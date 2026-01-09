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
      isJoined: json['is_member'] ?? false,
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

/// 频道模型
class ChannelModel {
  final String channelId;
  final String channelName;
  final int channelType; // 0=文字频道，1=语音频道
  final String categoryId; // 分组ID
  final String communityId; // 社群ID
  final String description; // 频道描述
  final int memberCount; // 成员数量
  final int maxMembers; // 最大成员数
  final bool pauseInvite; // 是否暂停邀请
  final bool muteAll; // 是否禁止发言
  final int notificationType; // 通知类型
  final int createdAt; // 创建时间
  final int updatedAt; // 更新时间
  
  ChannelModel({
    required this.channelId,
    required this.channelName,
    required this.channelType,
    this.categoryId = '',
    required this.communityId,
    this.description = '',
    this.memberCount = 0,
    this.maxMembers = 0,
    this.pauseInvite = false,
    this.muteAll = false,
    this.notificationType = 0,
    this.createdAt = 0,
    this.updatedAt = 0,
  });
  
  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      channelId: json['channel_id']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      channelType: json['channel_type'] ?? 0,
      categoryId: json['category_id']?.toString() ?? '',
      communityId: json['community_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      memberCount: json['member_count'] ?? 0,
      maxMembers: json['max_members'] ?? 0,
      pauseInvite: json['pause_invite'] ?? false,
      muteAll: json['mute_all'] ?? false,
      notificationType: json['notification_type'] ?? 0,
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'channel_name': channelName,
      'channel_type': channelType,
      'category_id': categoryId,
      'community_id': communityId,
      'description': description,
      'member_count': memberCount,
      'max_members': maxMembers,
      'pause_invite': pauseInvite,
      'mute_all': muteAll,
      'notification_type': notificationType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  /// 是否为文字频道
  bool get isTextChannel => channelType == 0;
  
  /// 是否为语音频道
  bool get isVoiceChannel => channelType == 1;
  
  /// 成员数量显示文本
  String get memberCountText {
    if (maxMembers > 0) {
      return '$memberCount / $maxMembers';
    }
    return '$memberCount';
  }
  
  /// 是否已满员
  bool get isFull => maxMembers > 0 && memberCount >= maxMembers;
  
  /// 频道类型显示文本
  String get channelTypeText {
    return isTextChannel ? '文字频道' : '语音频道';
  }
}

/// 社群分组和频道数据模型
class CommunityGChannels {
  /// 分组名到频道名列表的映射
  final Map<String, List<String>> categories;
  
  /// 分组名到分组ID的映射
  final Map<String, String> categoryIdMap;
  
  /// 所有频道列表（使用 ChannelModel 模型）
  final List<ChannelModel> channels;
  
  CommunityGChannels({
    required this.categories,
    required this.categoryIdMap,
    required this.channels,
  });
  
  /// 从 Map 创建（兼容旧的返回格式）
  factory CommunityGChannels.fromMap(Map<String, dynamic> map) {
    return CommunityGChannels(
      categories: map['categories'] != null
          ? Map<String, List<String>>.from(
              (map['categories'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value as List),
                ),
              ),
            )
          : <String, List<String>>{},
      categoryIdMap: map['categoryIdMap'] != null
          ? Map<String, String>.from(map['categoryIdMap'])
          : <String, String>{},
      channels: map['channels'] != null
          ? (map['channels'] as List).map((item) {
              if (item is ChannelModel) {
                return item;
              } else if (item is Map<String, dynamic>) {
                return ChannelModel.fromJson(item);
              } else {
                return ChannelModel.fromJson(Map<String, dynamic>.from(item));
              }
            }).toList()
          : <ChannelModel>[],
    );
  }
  
  /// 转换为 Map（兼容旧的返回格式）
  Map<String, dynamic> toMap() {
    return {
      'categories': categories,
      'categoryIdMap': categoryIdMap,
      'channels': channels.map((channel) => channel.toJson()).toList(),
    };
  }
  
  /// 是否为空
  bool get isEmpty => categories.isEmpty && channels.isEmpty;
  
  /// 是否有数据
  bool get isNotEmpty => !isEmpty;
  
  /// 获取指定分组下的频道列表（返回 ChannelModel）
  List<ChannelModel> getChannelsByCategory(String categoryName) {
    final channelNames = categories[categoryName] ?? [];
    return channels.where((channel) => channelNames.contains(channel.channelName)).toList();
  }
  
  /// 根据频道ID获取频道
  ChannelModel? getChannelById(String channelId) {
    try {
      return channels.firstWhere((channel) => channel.channelId == channelId);
    } catch (e) {
      return null;
    }
  }
  
  /// 根据频道名称获取频道
  ChannelModel? getChannelByName(String channelName) {
    try {
      return channels.firstWhere((channel) => channel.channelName == channelName);
    } catch (e) {
      return null;
    }
  }
}
