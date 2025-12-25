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
      version: 5,  // 升级版本号：添加用户表
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
        msg_id TEXT NOT NULL,
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
        is_all INTEGER DEFAULT 0,
        at_info_list TEXT,
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
    
    // ==================== 好友表 ====================
    await _createContactsTable(db);
    
    // ==================== 用户表 ====================
    await _createUsersTable(db);
  }
  
  /// 创建用户表
  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        nickname TEXT,
        avatar TEXT,
        avatar_bg TEXT,
        sex INTEGER DEFAULT 0,
        signature TEXT,
        region TEXT,
        background_file TEXT,
        phone TEXT,
        email TEXT,
        account_id TEXT,
        online_status INTEGER DEFAULT 0,
        last_online_time INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // 用户表索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_user_id ON users (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_updated_at ON users (updated_at)');
  }
  
  /// 创建好友表
  Future<void> _createContactsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        contact_user_id TEXT NOT NULL,
        nickname TEXT,
        avatar TEXT,
        avatar_bg TEXT,
        remark TEXT,
        phone TEXT,
        email TEXT,
        account_id TEXT,
        relationship INTEGER DEFAULT 0,
        online_status INTEGER DEFAULT 0,
        add_channel INTEGER DEFAULT 0,
        group_id INTEGER,
        group_name TEXT,
        create_time INTEGER,
        last_chat_time INTEGER,
        updated_at INTEGER,
        UNIQUE(user_id, contact_user_id)
      )
    ''');
    
    // 好友表索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_contacts_contact_user_id ON contacts (contact_user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_contacts_remark ON contacts (remark)');
  }
  
  /// 创建会话表
  Future<void> _createConversationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        conv_id TEXT NOT NULL,
        conv_type INTEGER NOT NULL DEFAULT 1,
        target_id TEXT,
        display_name TEXT NOT NULL,
        avatar TEXT,
        avatar_bg TEXT,
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
    // 从版本2升级到版本3：添加好友表
    if (oldVersion < 3) {
      await _createContactsTable(db);
    }
    // 从版本3升级到版本4：添加@消息字段
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE messages ADD COLUMN is_all INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE messages ADD COLUMN at_info_list TEXT');
    }
    // 从版本4升级到版本5：添加用户表
    if (oldVersion < 5) {
      await _createUsersTable(db);
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
  
  /// 根据 target_id 和 conv_type 获取会话（用于单聊/群聊）
  Future<ConversationModel?> getConversationByTargetId(
    String userId,
    String targetId,
    int convType,
  ) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'user_id = ? AND target_id = ? AND conv_type = ?',
      whereArgs: [userId, targetId, convType],
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
  Future<ChatMessage> insertMessage(ChatMessage message) async {
    final db = await database;

    print("message.ext: ${message.ext}");
    // 查询本地消息 ---  因为要删除
    final existingMessage = await db.query(
      'messages',
      where: 'server_id = ?',
      whereArgs: [message.serverId],
      limit: 1,
    );
    print("existingMessage: $existingMessage");
    if (existingMessage.isNotEmpty) {
      // 删除本地消息
      int count = await db.delete(
        'messages',
        where: 'server_id = ?',
        whereArgs: [message.serverId],
      );
      print("删除本地消息: $count");
    }
    

    print('插入消息数据库--单条: ${message.toDbMap()}');
    await db.insert(
      'messages',
      message.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return message;
  }

  /// 批量插入消息
  Future<void> insertMessages(List<ChatMessage> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final message in messages) {
      print('插入消息数据库--批量: ${message.displayContent}');
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
    print('获取数据库会话最新消息: ${maps.first}');
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
  
  // ==================== 好友相关方法 ====================
  
  /// 批量保存好友列表
  Future<void> saveContacts(String userId, List<Map<String, dynamic>> contacts) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final batch = db.batch();
    for (final contact in contacts) {
      final data = {
        'user_id': userId,
        'contact_user_id': contact['contact_user_id'] ?? contact['contactUserId'] ?? '',
        'nickname': contact['nickname'] ?? '',
        'avatar': contact['avatar'] ?? '',
        'remark': contact['remark'] ?? '',
        'phone': contact['phone'] ?? contact['targetPhone'] ?? '',
        'email': contact['email'] ?? contact['targetEmail'] ?? '',
        'account_id': contact['account_id'] ?? contact['accountId'] ?? '',
        'relationship': contact['relationship'] ?? 0,
        'online_status': contact['online_status'] ?? contact['onlineStatus'] ?? 0,
        'add_channel': contact['add_channel'] ?? contact['addChannel'] ?? 0,
        'group_id': contact['group_id'] ?? contact['groupId'],
        'group_name': contact['group_name'] ?? contact['groupName'] ?? '',
        'create_time': contact['create_time'] ?? contact['createTime'],
        'last_chat_time': contact['last_chat_time'] ?? contact['lastChatTime'],
        'updated_at': now,
      };
      
      batch.insert(
        'contacts',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    print('💾 保存好友到数据库: ${contacts.length} 条');
  }
  
  /// 获取好友信息（根据好友ID）
  Future<Map<String, dynamic>?> getContact(String userId, String contactUserId) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'user_id = ? AND contact_user_id = ?',
      whereArgs: [userId, contactUserId],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
  
  /// 批量获取好友信息
  Future<Map<String, Map<String, dynamic>>> getContactsMap(String userId, List<String> contactUserIds) async {
    if (contactUserIds.isEmpty) return {};
    
    final db = await database;
    final placeholders = List.filled(contactUserIds.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT * FROM contacts WHERE user_id = ? AND contact_user_id IN ($placeholders)',
      [userId, ...contactUserIds],
    );
    
    final Map<String, Map<String, dynamic>> contactsMap = {};
    for (final row in result) {
      final contactUserId = row['contact_user_id'] as String?;
      if (contactUserId != null) {
        contactsMap[contactUserId] = row;
      }
    }
    
    return contactsMap;
  }
  
  /// 获取好友的显示名称（备注 > 昵称）
  Future<String?> getContactDisplayName(String userId, String contactUserId) async {
    final contact = await getContact(userId, contactUserId);
    if (contact == null) return null;
    
    final remark = contact['remark'] as String?;
    final nickname = contact['nickname'] as String?;
    
    // 备注优先
    if (remark != null && remark.isNotEmpty) {
      return remark;
    }
    return nickname;
  }
  
  /// 获取好友的头像
  Future<String?> getContactAvatar(String userId, String contactUserId) async {
    final contact = await getContact(userId, contactUserId);
    if (contact == null) return null;
    
    return contact['avatar'] as String?;
  }
  
  /// 获取所有好友列表
  Future<List<Map<String, dynamic>>> getAllContacts(String userId) async {
    final db = await database;
    return await db.query(
      'contacts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'remark ASC, nickname ASC',
    );
  }
  
  /// 更新好友备注
  Future<void> updateContactRemark(String userId, String contactUserId, String remark) async {
    final db = await database;
    await db.update(
      'contacts',
      {'remark': remark, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'user_id = ? AND contact_user_id = ?',
      whereArgs: [userId, contactUserId],
    );
  }
  
  /// 删除好友
  Future<void> deleteContact(String userId, String contactUserId) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'user_id = ? AND contact_user_id = ?',
      whereArgs: [userId, contactUserId],
    );
  }
  
  /// 清空用户的所有好友缓存
  Future<void> clearContacts(String userId) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== 用户相关方法 ====================
  
  /// 插入或更新用户信息
  Future<void> upsertUser(Map<String, dynamic> userInfo) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final userId = userInfo['user_id'] as String?;
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('user_id 不能为空');
    }
    
    final data = {
      'user_id': userId,
      'nickname': userInfo['nickname'],
      'avatar': userInfo['avatar'],
      'sex': userInfo['sex'] ?? 0,
      'signature': userInfo['signature'],
      'region': userInfo['region'],
      'background_file': userInfo['background_file'],
      'phone': userInfo['phone'],
      'email': userInfo['email'],
      'account_id': userInfo['account_id'],
      'online_status': userInfo['online_status'] ?? 0,
      'last_online_time': userInfo['last_online_time'],
      'updated_at': now,
    };
    
    // 检查用户是否已存在
    final existing = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // 更新现有用户
      await db.update(
        'users',
        data,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      // 插入新用户
      data['created_at'] = now;
      await db.insert('users', data);
    }
  }
  
  /// 批量插入或更新用户信息
  Future<void> upsertUsers(List<Map<String, dynamic>> usersInfo) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 批量查询现有用户，获取他们的 created_at
    final userIds = usersInfo
        .map((info) => info['user_id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toList();
    
    final existingUsers = <String, int>{};
    if (userIds.isNotEmpty) {
      final placeholders = List.filled(userIds.length, '?').join(',');
      final results = await db.rawQuery(
        'SELECT user_id, created_at FROM users WHERE user_id IN ($placeholders)',
        userIds,
      );
      for (final row in results) {
        final userId = row['user_id'] as String?;
        final createdAt = row['created_at'] as int?;
        if (userId != null && createdAt != null) {
          existingUsers[userId] = createdAt;
        }
      }
    }
    
    for (final userInfo in usersInfo) {
      final userId = userInfo['user_id'] as String?;
      if (userId == null || userId.isEmpty) continue;
      
      // 如果用户已存在，使用原有的 created_at；否则使用当前时间
      final createdAt = existingUsers[userId] ?? now;
      
      final data = {
        'user_id': userId,
        'nickname': userInfo['nickname'],
        'avatar': userInfo['avatar'],
        'avatar_bg': userInfo['avatar_bg'], // 添加 avatar_bg 字段
        'sex': userInfo['sex'] ?? 0,
        'signature': userInfo['signature'],
        'region': userInfo['region'],
        'background_file': userInfo['background_file'],
        'phone': userInfo['phone'],
        'email': userInfo['email'],
        'account_id': userInfo['account_id'],
        'online_status': userInfo['online_status'] ?? 0,
        'last_online_time': userInfo['last_online_time'],
        'created_at': createdAt, // 添加 created_at 字段
        'updated_at': now,
      };
      
      // 使用 INSERT OR REPLACE
      batch.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }
  
  /// 获取单个用户信息
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
  
  /// 批量获取用户信息
  Future<List<Map<String, dynamic>>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = List.filled(userIds.length, '?').join(',');
    final results = await db.query(
      'users',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
    return results;
  }
  
  /// 获取所有用户信息
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'updated_at DESC');
  }
  
  /// 删除用户信息
  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
  
  /// 批量删除用户信息
  Future<void> deleteUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;
    
    final db = await database;
    final placeholders = List.filled(userIds.length, '?').join(',');
    await db.delete(
      'users',
      where: 'user_id IN ($placeholders)',
      whereArgs: userIds,
    );
  }
  
  /// 获取需要更新的用户信息（超过指定小时未更新）
  Future<List<String>> getUsersNeedUpdate(int hoursAgo) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(hours: hoursAgo)).millisecondsSinceEpoch;
    
    final results = await db.query(
      'users',
      columns: ['user_id'],
      where: 'updated_at < ?',
      whereArgs: [cutoffTime],
    );
    
    return results.map((row) => row['user_id'] as String).toList();
  }
  
  /// 清空用户表
  Future<void> clearUsers() async {
    final db = await database;
    await db.delete('users');
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

