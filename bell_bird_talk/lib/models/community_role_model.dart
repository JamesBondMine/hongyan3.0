class CommunityRolePermissions {
  // 频道权限
  bool viewChannel;
  bool manageChannel;
  bool joinVoiceChannel;
  
  // 消息权限
  bool sendMessage;
  bool sendMessageTypes;
  String? messageTypes;
  bool viewHistory;
  
  // 成员管理权限
  bool inviteFriend;
  bool kickMember;
  bool muteMember;
  bool banMember;
  
  // 语音权限
  bool speak;
  bool muteOthers;

  CommunityRolePermissions({
    this.viewChannel = false,
    this.manageChannel = false,
    this.joinVoiceChannel = false,
    this.sendMessage = false,
    this.sendMessageTypes = false,
    this.messageTypes,
    this.viewHistory = false,
    this.inviteFriend = false,
    this.kickMember = false,
    this.muteMember = false,
    this.banMember = false,
    this.speak = false,
    this.muteOthers = false,
  });

  factory CommunityRolePermissions.fromJson(List<dynamic> data) {
    // 创建一个Map来存储权限键值对
    Map<String, dynamic> permissionsMap = {};
    
    // 将数组转换为Map，方便查找
    for (Map<String, dynamic> item in data) {
      String? permissionKey = item['permission_key'];
      if (permissionKey != null) {
        permissionsMap[permissionKey] = item;
      }
    }
    
    // 辅助函数：获取权限的启用状态
    bool getPermissionEnabled(String key) {
      return permissionsMap[key]?['default_enabled'] ?? false;
    }
    
    // 辅助函数：获取消息类型
    String? getMessageTypes(String key) {
      return permissionsMap[key]?['message_types'];
    }

    return CommunityRolePermissions(
      viewChannel: getPermissionEnabled('view_channel'),
      manageChannel: getPermissionEnabled('manage_channel'),
      joinVoiceChannel: getPermissionEnabled('join_voice_channel'),
      sendMessage: getPermissionEnabled('send_message'),
      sendMessageTypes: getPermissionEnabled('send_message_types'),
      messageTypes: getMessageTypes('send_message_types'),
      viewHistory: getPermissionEnabled('view_history'),
      inviteFriend: getPermissionEnabled('invite_friend'),
      kickMember: getPermissionEnabled('kick_member'),
      muteMember: getPermissionEnabled('mute_member'),
      banMember: getPermissionEnabled('ban_member'),
      speak: getPermissionEnabled('speak'),
      muteOthers: getPermissionEnabled('mute_others'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'view_channel': viewChannel,
      'manage_channel': manageChannel,
      'join_voice_channel': joinVoiceChannel,
      'send_message': sendMessage,
      'send_message_types': sendMessageTypes,
      'message_types': messageTypes,
      'view_history': viewHistory,
      'invite_friend': inviteFriend,
      'kick_member': kickMember,
      'mute_member': muteMember,
      'ban_member': banMember,
      'speak': speak,
      'mute_others': muteOthers,
    };
  }

  @override
  String toString() {
    return 'CommunityRolePermissions('
        'viewChannel: $viewChannel, '
        'manageChannel: $manageChannel, '
        'joinVoiceChannel: $joinVoiceChannel, '
        'sendMessage: $sendMessage, '
        'sendMessageTypes: $sendMessageTypes, '
        'messageTypes: $messageTypes, '
        'viewHistory: $viewHistory, '
        'inviteFriend: $inviteFriend, '
        'kickMember: $kickMember, '
        'muteMember: $muteMember, '
        'banMember: $banMember, '
        'speak: $speak, '
        'muteOthers: $muteOthers'
        ')';
  }

  // 便捷方法：检查是否有管理权限
  bool get hasManagementPermissions {
    return manageChannel || kickMember || muteMember || banMember;
  }

  // 便捷方法：检查是否有消息权限
  bool get hasMessagePermissions {
    return sendMessage || sendMessageTypes;
  }

  // 便捷方法：检查是否有语音权限
  bool get hasVoicePermissions {
    return joinVoiceChannel || speak || muteOthers;
  }

  // 便捷方法：获取支持的消息类型列表
  List<String> get supportedMessageTypes {
    if (messageTypes == null || messageTypes!.isEmpty) {
      return [];
    }
    return messageTypes!.split(',').map((e) => e.trim()).toList();
  }

  // 便捷方法：检查是否支持特定消息类型
  bool supportsMessageType(String type) {
    return supportedMessageTypes.contains(type);
  }
}