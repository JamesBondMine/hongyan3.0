
/// 申请类型
enum RequestType {
  friend,  // 好友申请
  group,   // 群组申请
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

/// 群组申请模型
class GroupRequestModel {
  final int requestId;
  final String groupId;
  final String groupName;
  final String? groupAvatar;
  final String requesterId;
  final String requesterName;
  final String? message;
  final int status;  // 0=待处理, 1=已同意, 2=已拒绝
  final int requestTime;
  
  GroupRequestModel({
    required this.requestId,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    required this.requesterId,
    required this.requesterName,
    this.message,
    this.status = 0,
    this.requestTime = 0,
  });
  
  factory GroupRequestModel.fromJson(Map<String, dynamic> json) {
    return GroupRequestModel(
      requestId: json['request_id'] ?? 0,
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? '未知群组',
      groupAvatar: json['group_avatar'],
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '未知用户',
      message: json['message'],
      status: json['status'] ?? 0,
      requestTime: json['request_time'] ?? 0,
    );
  }
  
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
