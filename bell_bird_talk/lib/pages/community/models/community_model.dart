/// 社群模型
class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String? avatar;
  final int memberCount;
  final int maxMembers;
  final String category; // 分类：如 "技术"、"生活"、"娱乐"等
  final bool isPublic; // 是否公开
  final String? ownerId;
  final String? ownerName;
  final int createTime;
  final bool isJoined; // 是否已加入
  final bool hasApplied; // 是否已申请
  
  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.avatar,
    this.memberCount = 0,
    this.maxMembers = 500,
    this.category = '其他',
    this.isPublic = true,
    this.ownerId,
    this.ownerName,
    this.createTime = 0,
    this.isJoined = false,
    this.hasApplied = false,
  });
  
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar'],
      memberCount: json['member_count'] ?? 0,
      maxMembers: json['max_members'] ?? 500,
      category: json['category'] ?? '其他',
      isPublic: json['is_public'] ?? true,
      ownerId: json['owner_id'],
      ownerName: json['owner_name'],
      createTime: json['created_at'] ?? json['create_time'] ?? 0,
      isJoined: json['is_member'] ?? json['is_joined'] ?? false,
      hasApplied: json['has_applied'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'member_count': memberCount,
      'max_members': maxMembers,
      'category': category,
      'is_public': isPublic,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'create_time': createTime,
      'is_joined': isJoined,
      'has_applied': hasApplied,
    };
  }
  
  /// 成员数量显示文本
  String get memberCountText {
    if (maxMembers > 0) {
      return '$memberCount / $maxMembers';
    }
    return '$memberCount';
  }
  
  /// 是否已满员
  bool get isFull => maxMembers > 0 && memberCount >= maxMembers;
}

