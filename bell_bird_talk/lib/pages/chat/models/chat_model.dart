/// 会话模型
class ConversationModel {
  final String convId;
  final String displayName;
  final String? avatar;
  final String? lastMessage;
  final int lastMessageType;  // 最后一条消息类型
  final DateTime? lastMessageTime;
  final String? lastSenderId;  // 最后一条消息发送者ID
  final String? lastSenderName;  // 最后一条消息发送者名称
  final int unreadCount;
  final int convType; // 0=单聊, 2=群聊, 3=系统, 4=社区
  final String? targetId;
  final bool isOnline;
  final bool isPinned;  // 是否置顶
  final bool isMuted;   // 是否静音
  final String? draft;  // 草稿
  final int atMeCount;  // @我的消息数
  final bool mentionAll;  // 是否@所有人
  final int groupMemberCount;  // 群成员数量
  final String? ext;  // 扩展字段

  ConversationModel({
    required this.convId,
    required this.displayName,
    this.avatar,
    this.lastMessage,
    this.lastMessageType = 0,
    this.lastMessageTime,
    this.lastSenderId,
    this.lastSenderName,
    this.unreadCount = 0,
    this.convType = 0,
    this.targetId,
    this.isOnline = false,
    this.isPinned = false,
    this.isMuted = false,
    this.draft,
    this.atMeCount = 0,
    this.mentionAll = false,
    this.groupMemberCount = 0,
    this.ext,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      convId: json['conv_id'] ?? '',
      displayName: json['display_name'] ?? '未知会话',
      avatar: json['avatar_url'] ?? json['avatar'],
      lastMessage: json['last_message'],
      lastMessageType: json['last_message_type'] as int? ?? 0,
      lastMessageTime: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : (json['last_message_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['last_message_time'] as int)
              : null),
      lastSenderId: json['last_sender_id'],
      lastSenderName: json['last_sender_name'],
      unreadCount: json['unread_count'] as int? ?? 0,
      convType: json['conv_type'] as int? ?? 0,
      targetId: json['target_id'],
      isOnline: (json['online_status'] as int? ?? 0) == 1,
      isPinned: (json['is_pinned'] as int? ?? 0) == 1 || json['is_pinned'] == true,
      isMuted: (json['is_muted'] as int? ?? 0) == 1 || json['is_muted'] == true,
      draft: json['draft'],
      atMeCount: json['at_me_count'] as int? ?? 0,
      mentionAll: (json['mention_all'] as int? ?? 0) == 1 || json['mention_all'] == true,
      groupMemberCount: json['group_member_count'] as int? ?? 0,
      ext: json['ext'],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'conv_id': convId,
      'display_name': displayName,
      'avatar': avatar,
      'last_message': lastMessage,
      'last_message_type': lastMessageType,
      'last_message_time': lastMessageTime?.millisecondsSinceEpoch,
      'last_sender_id': lastSenderId,
      'last_sender_name': lastSenderName,
      'unread_count': unreadCount,
      'conv_type': convType,
      'target_id': targetId,
      'online_status': isOnline ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'is_muted': isMuted ? 1 : 0,
      'draft': draft,
      'at_me_count': atMeCount,
      'mention_all': mentionAll ? 1 : 0,
      'group_member_count': groupMemberCount,
      'ext': ext,
    };
  }
  
  /// 复制并更新
  ConversationModel copyWith({
    String? convId,
    String? displayName,
    String? avatar,
    String? lastMessage,
    int? lastMessageType,
    DateTime? lastMessageTime,
    String? lastSenderId,
    String? lastSenderName,
    int? unreadCount,
    int? convType,
    String? targetId,
    bool? isOnline,
    bool? isPinned,
    bool? isMuted,
    String? draft,
    int? atMeCount,
    bool? mentionAll,
    int? groupMemberCount,
    String? ext,
  }) {
    return ConversationModel(
      convId: convId ?? this.convId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      convType: convType ?? this.convType,
      targetId: targetId ?? this.targetId,
      isOnline: isOnline ?? this.isOnline,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      draft: draft ?? this.draft,
      atMeCount: atMeCount ?? this.atMeCount,
      mentionAll: mentionAll ?? this.mentionAll,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      ext: ext ?? this.ext,
    );
  }
  
  /// 获取最后消息的显示文本
  String get lastMessageDisplay {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return '';
    }
    
    // 根据消息类型返回不同的显示文本
    switch (lastMessageType) {
      case 0: // 文本
        return lastMessage!;
      case 1: // 图片
        return '[图片]';
      case 2: // 视频
        return '[视频]';
      case 3: // 语音
        return '[语音]';
      case 4: // 文件
        return '[文件]';
      case 5: // 位置
        return '[位置]';
      case 6: // 名片
        return '[名片]';
      case 7: // 分享链接
        return '[链接]';
      case 8: // 表情贴纸
        return '[表情]';
      case 15: // 红包
        return '[红包]';
      case 16: // 通知
        return lastMessage!;
      default:
        return lastMessage!;
    }
  }
}
