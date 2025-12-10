import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';

/// 消息数据库管理类
class MessageDatabase {
  static final MessageDatabase _instance = MessageDatabase._internal();
  factory MessageDatabase() => _instance;
  MessageDatabase._internal();

  Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        conv_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        is_mine INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sent_at INTEGER,
        is_read INTEGER DEFAULT 0,
        text_content TEXT,
        image_local_path TEXT,
        image_url TEXT,
        image_thumbnail_url TEXT,
        image_width INTEGER,
        image_height INTEGER,
        file_local_path TEXT,
        file_url TEXT,
        file_name TEXT,
        file_size INTEGER,
        file_mime_type TEXT,
        voice_duration INTEGER,
        video_duration INTEGER,
        video_cover_url TEXT,
        ext TEXT,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_conv_id ON messages (conv_id)');
    await db.execute('CREATE INDEX idx_created_at ON messages (created_at)');
    await db.execute('CREATE INDEX idx_status ON messages (status)');
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级时处理
  }

  /// 插入消息
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入消息
  Future<void> insertMessages(List<ChatMessage> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final message in messages) {
      batch.insert(
        'messages',
        message.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 更新消息
  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      'messages',
      message.toDbMap(),
      where: 'local_id = ?',
      whereArgs: [message.localId],
    );
  }

  /// 更新消息状态
  Future<void> updateMessageStatus(String localId, MessageStatus status, {String? errorMessage}) async {
    final db = await database;
    final Map<String, dynamic> values = {'status': status.value};
    if (errorMessage != null) {
      values['error_message'] = errorMessage;
    }
    if (status == MessageStatus.sent) {
      values['sent_at'] = DateTime.now().millisecondsSinceEpoch;
    }
    await db.update(
      'messages',
      values,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// 更新消息服务器ID
  Future<void> updateMessageServerId(String localId, String serverId) async {
    final db = await database;
    await db.update(
      'messages',
      {'server_id': serverId},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// 更新图片消息URL
  Future<void> updateImageUrl(String localId, String imageUrl, String? thumbnailUrl) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'image_url': imageUrl,
        'image_thumbnail_url': thumbnailUrl,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// 获取会话消息列表
  Future<List<ChatMessage>> getMessages(String convId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conv_id = ?',
      whereArgs: [convId],
      orderBy: 'created_at ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ChatMessage.fromDbMap(map)).toList();
  }

  /// 获取会话最新消息
  Future<ChatMessage?> getLatestMessage(String convId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conv_id = ?',
      whereArgs: [convId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatMessage.fromDbMap(maps.first);
  }

  /// 获取待发送的消息
  Future<List<ChatMessage>> getPendingMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'status IN (?, ?)',
      whereArgs: [MessageStatus.pending.value, MessageStatus.failed.value],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => ChatMessage.fromDbMap(map)).toList();
  }

  /// 获取发送失败的消息
  Future<List<ChatMessage>> getFailedMessages(String convId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conv_id = ? AND status = ?',
      whereArgs: [convId, MessageStatus.failed.value],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => ChatMessage.fromDbMap(map)).toList();
  }

  /// 删除消息
  Future<void> deleteMessage(String localId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// 删除会话所有消息
  Future<void> deleteConversationMessages(String convId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'conv_id = ?',
      whereArgs: [convId],
    );
  }

  /// 获取消息数量
  Future<int> getMessageCount(String convId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conv_id = ?',
      [convId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 标记会话消息已读
  Future<void> markConversationAsRead(String convId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'conv_id = ? AND is_read = 0',
      whereArgs: [convId],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

