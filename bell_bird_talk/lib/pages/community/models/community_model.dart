import 'package:bell_bird_talk/controllers/global_controller.dart';

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
  final bool allowAddFriend; // 是否公开
  
  final String ownerId;
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
    this.allowAddFriend = true,
    required this.ownerId,
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
      allowAddFriend: json['allow_add_friend'] ?? true,
      
      ownerId: json['owner_id'] ?? '',
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
  final List<CmtGroupModel> categories;
  
  /// 分组ID的映射
  final Map<String, List<ChannelModel>> categoryIdMap;
  
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
      categories: map['categories'] ?? [],
      categoryIdMap: {},
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
  
  // /// 获取指定分组下的频道列表（返回 ChannelModel）
  // List<ChannelModel> getChannelsByCategory(String categoryId) {
  //   final channelNames = categories[categoryId] ?? [];
  //   return channels.where((channel) => channelNames.contains(channel.channelName)).toList();
  // }
  
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


// =
// "created_at" -> 1767951870533
// 1 =
// "category_name" -> "我是新分类1111"
// 2 =
// "updated_at" -> 1767955553349
// 3 =
// "category_id" -> "WKY79XNX"
// 4 =
// "community_id" -> "KQYRLQC1LR"
// 5 =
// "description" -> 

// 社群分组
class CmtGroupModel {
  final String id;
  final String name;
  final String description;
  final String communityId;
  final int memberCount;

  // 分组状态的频道
  bool isChannel = false;

  
  CmtGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.communityId,
    this.memberCount = 0,
  });
  
  factory CmtGroupModel.fromJson(Map<String, dynamic> json) {
    return CmtGroupModel(
      id: json['category_id'] ?? '',
      name: json['category_name'] ?? '',
      description: json['description'] ?? '',
      communityId: json['community_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'community_id': communityId,
    };
  }
  

}

/// 社群成员模型
class CommunityMemberModel {
  final String id;
  final String username;
  final String? nickname;
  final String? avatar;
  final String role; // 角色，如 'owner', 'admin', 'member'
  final int joinTime;
  final bool isMuted; // 是否被禁言
  final int muteUntil; // 禁言到期时间

  CommunityMemberModel({
    required this.id,
    required this.username,
    this.nickname,
    this.avatar,
    this.role = 'member',
    this.joinTime = 0,
    this.isMuted = false,
    this.muteUntil = 0,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['user_id'] ?? '',
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'],
      role: '${json['role'] ?? '0'}',
      joinTime: json['join_time'] ?? 0,
      isMuted: json['is_muted'] ?? false,
      muteUntil: json['mute_until'] ?? 0,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'role': role,
      'join_time': joinTime,
      'is_muted': isMuted,
      'mute_until': muteUntil,
    };
  }

  /// 角色显示文本
  String get roleText {
    switch (role) {
      case 'owner':
        return '群主';
      case 'admin':
        return '管理员';
      case 'member':
      default:
        return '成员';
    }
  }

  /// 是否为管理员或群主
  bool get isAdmin => role == 'admin' || role == 'owner';

  /// 是否为群主
  final currentUserId =  GlobalController.to.currentUser.value?.id ?? '';
  bool get isOwner => id== currentUserId || role == 'owner';
}

