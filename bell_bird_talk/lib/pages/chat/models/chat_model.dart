/// 会话模型
class ConversationModel {
  final String convId;
  final String displayName;
  final String? avatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final int convType; // 0=单聊, 2=群聊, 3=系统, 4=社区
  final String? targetId;
  final bool isOnline;

  ConversationModel({
    required this.convId,
    required this.displayName,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.convType = 0,
    this.targetId,
    this.isOnline = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      convId: json['conv_id'] ?? '',
      displayName: json['display_name'] ?? '未知会话',
      avatar: json['avatar_url'],
      lastMessage: json['last_message'],
      lastMessageTime: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      convType: json['conv_type'] as int? ?? 0,
      targetId: json['target_id'],
      isOnline: (json['online_status'] as int? ?? 0) == 1,
    );
  }
  
  /// 复制并更新
  ConversationModel copyWith({
    String? convId,
    String? displayName,
    String? avatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    int? convType,
    String? targetId,
    bool? isOnline,
  }) {
    return ConversationModel(
      convId: convId ?? this.convId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      convType: convType ?? this.convType,
      targetId: targetId ?? this.targetId,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
