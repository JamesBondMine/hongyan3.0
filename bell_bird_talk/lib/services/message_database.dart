import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../pages/chat/models/chat_model.dart';

/// 聊天数据库管理类（包含消息表和会话表）
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
      version: 2,  // 升级版本号
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // ==================== 消息表 ====================
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

    // 消息表索引
    await db.execute('CREATE INDEX idx_messages_conv_id ON messages (conv_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages (created_at)');
    await db.execute('CREATE INDEX idx_messages_status ON messages (status)');
    
    // ==================== 会话表 ====================
    await _createConversationsTable(db);
  }
  
  /// 创建会话表
  Future<void> _createConversationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        conv_id TEXT NOT NULL,
        conv_type INTEGER NOT NULL DEFAULT 0,
        target_id TEXT,
        display_name TEXT NOT NULL,
        avatar TEXT,
        unread_count INTEGER NOT NULL DEFAULT 0,
        last_message TEXT,
        last_message_type INTEGER DEFAULT 0,
        last_message_time INTEGER,
        last_sender_id TEXT,
        last_sender_name TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_muted INTEGER NOT NULL DEFAULT 0,
        is_online INTEGER NOT NULL DEFAULT 0,
        draft TEXT,
        at_me_count INTEGER NOT NULL DEFAULT 0,
        mention_all INTEGER NOT NULL DEFAULT 0,
        group_member_count INTEGER DEFAULT 0,
        search_key TEXT,
        ext TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(user_id, conv_id)
      )
    ''');
    
    // 会话表索引
    await db.execute('CREATE INDEX idx_conv_user_id ON conversations (user_id)');
    await db.execute('CREATE INDEX idx_conv_conv_id ON conversations (conv_id)');
    await db.execute('CREATE INDEX idx_conv_updated_at ON conversations (updated_at)');
    await db.execute('CREATE INDEX idx_conv_is_pinned ON conversations (is_pinned)');
    await db.execute('CREATE INDEX idx_conv_conv_type ON conversations (conv_type)');
    await db.execute('CREATE INDEX idx_conv_search_key ON conversations (search_key)');
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 从版本1升级到版本2：添加会话表
    if (oldVersion < 2) {
      await _createConversationsTable(db);
    }
  }
  
  // ==================== 会话相关方法 ====================
  
  /// 插入或更新会话
  Future<void> upsertConversation(String userId, ConversationModel conversation) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 构建搜索关键词（用于后续搜索）
    final searchKey = _buildSearchKey(conversation);
    
    final data = {
      'user_id': userId,
      'conv_id': conversation.convId,
      'conv_type': conversation.convType,
      'target_id': conversation.targetId,
      'display_name': conversation.displayName,
      'avatar': conversation.avatar,
      'unread_count': conversation.unreadCount,
      'last_message': conversation.lastMessage,
      'last_message_type': conversation.lastMessageType,
      'last_message_time': conversation.lastMessageTime?.millisecondsSinceEpoch,
      'last_sender_id': conversation.lastSenderId,
      'last_sender_name': conversation.lastSenderName,
      'is_pinned': conversation.isPinned ? 1 : 0,
      'is_muted': conversation.isMuted ? 1 : 0,
      'is_online': conversation.isOnline ? 1 : 0,
      'draft': conversation.draft,
      'at_me_count': conversation.atMeCount,
      'mention_all': conversation.mentionAll ? 1 : 0,
      'group_member_count': conversation.groupMemberCount,
      'search_key': searchKey,
      'ext': conversation.ext,
      'updated_at': now,
    };
    
    // 检查是否存在
    final existing = await db.query(
      'conversations',
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, conversation.convId],
      limit: 1,
    );
    
    if (existing.isEmpty) {
      data['created_at'] = now;
      await db.insert('conversations', data);
    } else {
      await db.update(
        'conversations',
        data,
        where: 'user_id = ? AND conv_id = ?',
        whereArgs: [userId, conversation.convId],
      );
    }
  }
  
  /// 批量插入或更新会话
  Future<void> upsertConversations(String userId, List<ConversationModel> conversations) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final conversation in conversations) {
      final searchKey = _buildSearchKey(conversation);
      
      final data = {
        'user_id': userId,
        'conv_id': conversation.convId,
        'conv_type': conversation.convType,
        'target_id': conversation.targetId,
        'display_name': conversation.displayName,
        'avatar': conversation.avatar,
        'unread_count': conversation.unreadCount,
        'last_message': conversation.lastMessage,
        'last_message_type': conversation.lastMessageType,
        'last_message_time': conversation.lastMessageTime?.millisecondsSinceEpoch,
        'last_sender_id': conversation.lastSenderId,
        'last_sender_name': conversation.lastSenderName,
        'is_pinned': conversation.isPinned ? 1 : 0,
        'is_muted': conversation.isMuted ? 1 : 0,
        'is_online': conversation.isOnline ? 1 : 0,
        'draft': conversation.draft,
        'at_me_count': conversation.atMeCount,
        'mention_all': conversation.mentionAll ? 1 : 0,
        'group_member_count': conversation.groupMemberCount,
        'search_key': searchKey,
        'ext': conversation.ext,
        'created_at': now,
        'updated_at': now,
      };
      
      batch.insert(
        'conversations',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }
  
  /// 获取用户的会话列表
  Future<List<ConversationModel>> getConversations(
    String userId, {
    int? limit,
    int? offset,
    int? convType,  // 可选筛选类型
  }) async {
    final db = await database;
    
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (convType != null) {
      where += ' AND conv_type = ?';
      whereArgs.add(convType);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_pinned DESC, updated_at DESC',  // 置顶优先，再按更新时间排序
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => _conversationFromDbMap(map)).toList();
  }
  
  /// 获取有未读消息的会话列表
  Future<List<ConversationModel>> getUnreadConversations(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'user_id = ? AND unread_count > 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    
    return maps.map((map) => _conversationFromDbMap(map)).toList();
  }
  
  /// 获取@我的会话列表
  Future<List<ConversationModel>> getAtMeConversations(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'user_id = ? AND at_me_count > 0',
      whereArgs: [userId],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    
    return maps.map((map) => _conversationFromDbMap(map)).toList();
  }
  
  /// 搜索会话（预留关键词搜索）
  Future<List<ConversationModel>> searchConversations(
    String userId,
    String keyword,
  ) async {
    final db = await database;
    final searchKeyword = '%${keyword.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'user_id = ? AND (search_key LIKE ? OR last_message LIKE ?)',
      whereArgs: [userId, searchKeyword, searchKeyword],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    
    return maps.map((map) => _conversationFromDbMap(map)).toList();
  }
  
  /// 获取单个会话
  Future<ConversationModel?> getConversation(String userId, String convId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return _conversationFromDbMap(maps.first);
  }
  
  /// 更新会话未读数
  Future<void> updateConversationUnreadCount(
    String userId,
    String convId,
    int unreadCount,
  ) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'unread_count': unreadCount,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 增加会话未读数
  Future<void> incrementUnreadCount(String userId, String convId, {int increment = 1}) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE conversations 
      SET unread_count = unread_count + ?, updated_at = ?
      WHERE user_id = ? AND conv_id = ?
    ''', [increment, DateTime.now().millisecondsSinceEpoch, userId, convId]);
  }
  
  /// 清除会话未读数
  Future<void> clearConversationUnreadCount(String userId, String convId) async {
    await updateConversationUnreadCount(userId, convId, 0);
  }
  
  /// 更新会话最后一条消息
  Future<void> updateConversationLastMessage(
    String userId,
    String convId, {
    required String lastMessage,
    required int lastMessageTime,
    int lastMessageType = 0,
    String? lastSenderId,
    String? lastSenderName,
  }) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'last_message_time': lastMessageTime,
        'last_sender_id': lastSenderId,
        'last_sender_name': lastSenderName,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 设置会话置顶状态
  Future<void> setConversationPinned(String userId, String convId, bool isPinned) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 设置会话静音状态
  Future<void> setConversationMuted(String userId, String convId, bool isMuted) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'is_muted': isMuted ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 保存会话草稿
  Future<void> saveConversationDraft(String userId, String convId, String? draft) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'draft': draft,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 删除会话
  Future<void> deleteConversation(String userId, String convId) async {
    final db = await database;
    await db.delete(
      'conversations',
      where: 'user_id = ? AND conv_id = ?',
      whereArgs: [userId, convId],
    );
  }
  
  /// 删除用户的所有会话（用于切换用户）
  Future<void> deleteUserConversations(String userId) async {
    final db = await database;
    await db.delete(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
  
  /// 获取用户总未读消息数
  Future<int> getTotalUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(unread_count) as total FROM conversations WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// 获取群聊未读消息数
  Future<int> getGroupUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(unread_count) as total FROM conversations WHERE user_id = ? AND conv_type = 2',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// 获取@我的未读数
  Future<int> getAtMeUnreadCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(at_me_count) as total FROM conversations WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// 构建搜索关键词
  String _buildSearchKey(ConversationModel conversation) {
    final parts = <String>[];
    parts.add(conversation.displayName.toLowerCase());
    if (conversation.targetId != null) {
      parts.add(conversation.targetId!.toLowerCase());
    }
    return parts.join(' ');
  }
  
  /// 从数据库Map转换为ConversationModel
  ConversationModel _conversationFromDbMap(Map<String, dynamic> map) {
    return ConversationModel(
      convId: map['conv_id'] as String,
      convType: map['conv_type'] as int? ?? 0,
      targetId: map['target_id'] as String?,
      displayName: map['display_name'] as String,
      avatar: map['avatar'] as String?,
      unreadCount: map['unread_count'] as int? ?? 0,
      lastMessage: map['last_message'] as String?,
      lastMessageType: map['last_message_type'] as int? ?? 0,
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_message_time'] as int)
          : null,
      lastSenderId: map['last_sender_id'] as String?,
      lastSenderName: map['last_sender_name'] as String?,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isMuted: (map['is_muted'] as int? ?? 0) == 1,
      isOnline: (map['is_online'] as int? ?? 0) == 1,
      draft: map['draft'] as String?,
      atMeCount: map['at_me_count'] as int? ?? 0,
      mentionAll: (map['mention_all'] as int? ?? 0) == 1,
      groupMemberCount: map['group_member_count'] as int? ?? 0,
      ext: map['ext'] as String?,
    );
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

  /// 更新语音消息URL
  Future<void> updateVoiceUrl(String localId, String voiceUrl) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'file_url': voiceUrl,
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

