
/// 好友模型
class FriendModel {
  final String id;
  final String? accountId;
  final String nickname;
  final String? avatar;
  final String? remark;
  final int relationship;  // 0=好友, 1=黑名单等
  final int onlineStatus;  // 0=离线, 1=在线
  
  FriendModel({
    required this.id,
    this.accountId,
    required this.nickname,
    this.avatar,
    this.remark,
    this.relationship = 0,
    this.onlineStatus = 0,
  });
  
  /// 从 JSON 构造
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['contact_user_id'] ?? json['user_id'] ?? '',
      accountId: json['account_id'],
      nickname: json['nickname'] ?? json['remark'] ?? '未知用户',
      avatar: json['avatar'],
      remark: json['remark'],
      relationship: json['relationship'] ?? 0,
      onlineStatus: json['online_status'] ?? 0,
    );
  }
  
  /// 是否在线
  bool get isOnline => onlineStatus == 1;
  
  /// 显示名称（优先显示备注）
  String get displayName => (remark != null && remark!.isNotEmpty) ? remark! : nickname;
  
  /// 用户ID别名（兼容字段）
  String get userId => id;
  
  /// 创建副本并更新指定字段
  FriendModel copyWith({
    String? id,
    String? accountId,
    String? nickname,
    String? avatar,
    String? remark,
    int? relationship,
    int? onlineStatus,
  }) {
    return FriendModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      remark: remark ?? this.remark,
      relationship: relationship ?? this.relationship,
      onlineStatus: onlineStatus ?? this.onlineStatus,
    );
  }
}

/// 好友分组模型
class FriendGroup {
  final String id;
  final String name;
  final bool isDefault;  // 是否是默认分组（不可删除）
  int count;  // 分组内好友数量
  final String? color;  // 分组颜色
  final int order;  // 排序顺序
  final String? icon;  // 分组图标
  final String? description;  // 分组描述
  
  FriendGroup({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.count = 0,
    this.color,
    this.order = 0,
    this.icon,
    this.description,
  });
  
  /// 从 JSON 构造
  factory FriendGroup.fromJson(Map<String, dynamic> json) {
    return FriendGroup(
      id: json['group_id']?.toString() ?? '',
      name: json['group_name'] ?? '未命名分组',
      count: json['contact_count'] ?? 0,
      color: json['group_color'],
      order: json['group_order'] ?? 0,
      icon: json['group_icon'],
      description: json['group_description'],
      isDefault: false,
    );
  }
}

/// 好友申请模型
class FriendRequestModel {
  final int requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String? message;
  final int channel;
  final int status;  // 0=待处理, 1=已同意, 2=已拒绝
  final int requestTime;
  final int expireTime;
  
  FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    this.message,
    this.channel = 0,
    this.status = 0,
    this.requestTime = 0,
    this.expireTime = 0,
  });
  
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: json['request_id'] ?? 0,
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '未知用户',
      requesterAvatar: json['requester_avatar'],
      message: json['message'],
      channel: json['channel'] ?? 0,
      status: json['status'] ?? 0,
      requestTime: json['request_time'] ?? 0,
      expireTime: json['expire_time'] ?? 0,
    );
  }
  
  /// 是否待处理
  bool get isPending => status == 0;
  
  /// 格式化时间
  String get formattedTime {
    if (requestTime == 0) return '';
    final time = DateTime.fromMillisecondsSinceEpoch(requestTime);
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
