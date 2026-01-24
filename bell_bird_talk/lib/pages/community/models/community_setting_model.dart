/// 社群设置对象
class CmtSetting {
  // 布尔类型设置
  bool allowAddFriend = false;
  bool pauseInvite;
  bool needVerify = false;
  bool allowPrivateChat = false;
  bool allowAccessOtherChannels = false;
  bool allowJoinByInviteLink = false;
  
  
  // 整数类型设置
  final int? speakFrequencyLimit;
  
  // 列表类型设置
  final List<String>? speakTypeLimit;
  
  // 其他动态设置（用于存储未定义的设置项）
  final Map<String, dynamic>? otherSettings;

  CmtSetting({
    this.allowAddFriend = false,
    this.pauseInvite = false,
    this.needVerify = false,
    this.allowPrivateChat =false,
    this.allowAccessOtherChannels = false,
    this.allowJoinByInviteLink = false,
    this.speakFrequencyLimit,
    this.speakTypeLimit,
    this.otherSettings,
  });

  factory CmtSetting.fromJson(Map<String, dynamic> json) {
    // 辅助函数：获取布尔值
    bool? getBool(String key) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value == 'true' || value == '1';
      return null;
    }
    
    // 辅助函数：获取整数值
    int? getInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // 辅助函数：获取列表值
    List<String>? getList(String key) {
      final value = json[key];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }
    
    // 提取已知的设置项
    final knownKeys = {
      'allow_add_friend',
      'pause_invite',
      'need_verify',
      'allow_private_chat',
      'allow_access_other_channels',
      'speak_frequency_limit',
      'allow_join_by_invite_link',
      'speak_type_limit',
    };
    
    // 提取其他未知的设置项
    final Map<String, dynamic> other = {};
    json.forEach((key, value) {
      if (!knownKeys.contains(key)) {
        other[key] = value;
      }
    });
    
    return CmtSetting(
      allowAddFriend: getBool('allow_add_friend') ?? false,
      pauseInvite: getBool('pause_invite') ?? false,
      needVerify: getBool('need_verify') ?? false,
      allowJoinByInviteLink: getBool('allow_join_by_invite_link') ?? false,
      
      allowPrivateChat: getBool('allow_private_chat') ?? false,
      allowAccessOtherChannels: getBool('allow_access_other_channels') ?? false,
      speakFrequencyLimit: getInt('speak_frequency_limit'),
      speakTypeLimit: getList('speak_type_limit'),
      otherSettings: other.isNotEmpty ? other : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    if (allowAddFriend != null) json['allow_add_friend'] = allowAddFriend;
    if (pauseInvite != null) json['pause_invite'] = pauseInvite;
    if (needVerify != null) json['need_verify'] = needVerify;
    if (allowPrivateChat != null) json['allow_private_chat'] = allowPrivateChat;
    if (allowJoinByInviteLink != null) json['allow_join_by_invite_link'] = allowJoinByInviteLink;
    
    if (allowAccessOtherChannels != null) {
      json['allow_access_other_channels'] = allowAccessOtherChannels;
    }
    if (speakFrequencyLimit != null) {
      json['speak_frequency_limit'] = speakFrequencyLimit;
    }
    if (speakTypeLimit != null) json['speak_type_limit'] = speakTypeLimit;
    
    // 添加其他设置
    if (otherSettings != null) {
      json.addAll(otherSettings!);
    }
    
    return json;
  }
  
  /// 获取其他设置项的值
  dynamic getOtherSetting(String key) {
    return otherSettings?[key];
  }
}

/// 社群设置模型
class CommunitySettingsModel {
  final String cmtyId;
  final CmtSetting settings; // 键值对形式：{"allow_add_friend": true, ...}

  CommunitySettingsModel({
    required this.cmtyId,
    required this.settings,
  });

  factory CommunitySettingsModel.fromJson(Map<String, dynamic> json) {
    final settingsList = json['settings'] as List<dynamic>? ?? [];
    
    // 将数组转换为 Map 对象
    final Map<String, dynamic> settingsMap = {};
    for (var item in settingsList) {
      if (item is Map<String, dynamic>) {
        final settingKey = item['setting_key'] as String? ?? '';
        final settingValue = item['setting_value'];
        if (settingKey.isNotEmpty) {
          settingsMap[settingKey] = settingValue;
        }
      }
    }
    
    return CommunitySettingsModel(
      cmtyId: json['cmty_id'] ?? '',
      settings: CmtSetting.fromJson(settingsMap) ,
    );
  }

  Map<String, dynamic> toJson() {
    // 将 CmtSetting 对象转换回数组格式（如果需要）
    final settingsJson = settings.toJson();
    final List<Map<String, dynamic>> settingsList = [];
    
    settingsJson.forEach((key, value) {
      settingsList.add({
        'setting_key': key,
        'setting_value': value,
      });
    });
    
    return {
      'cmty_id': cmtyId,
      'settings': settingsList,
    };
  }
}

/// 社群加入申请记录
class JoinRequest {
  final String inviteCode;
  final String requestMessage;
  final int requestId;
  final int requestTime; // 时间戳（毫秒）
  final String reviewUserId;
  final String userId;
  final String avatar;
  final String reviewMessage;
  final String inviteLink;
  final String username;
  final String cmtyId;
  final String nickname;
  final int reviewTime; // 时间戳（毫秒）
  final int status; // 0=待审核，1=已通过，2=已拒绝，3=已过期，4=已取消
  final int expireTime; // 时间戳（毫秒）

  JoinRequest({
    this.inviteCode = '',
    this.requestMessage = '',
    required this.requestId,
    required this.requestTime,
    this.reviewUserId = '',
    required this.userId,
    this.avatar = '',
    this.reviewMessage = '',
    this.inviteLink = '',
    this.username = '',
    required this.cmtyId,
    this.nickname = '',
    this.reviewTime = 0,
    required this.status,
    required this.expireTime,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      inviteCode: json['invite_code'] as String? ?? '',
      requestMessage: json['request_message'] as String? ?? '',
      requestId: json['request_id'] as int? ?? 0,
      requestTime: json['request_time'] as int? ?? 0,
      reviewUserId: json['review_user_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      reviewMessage: json['review_message'] as String? ?? '',
      inviteLink: json['invite_link'] as String? ?? '',
      username: json['username'] as String? ?? '',
      cmtyId: json['cmty_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      reviewTime: json['review_time'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      expireTime: json['expire_time'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invite_code': inviteCode,
      'request_message': requestMessage,
      'request_id': requestId,
      'request_time': requestTime,
      'review_user_id': reviewUserId,
      'user_id': userId,
      'avatar': avatar,
      'review_message': reviewMessage,
      'invite_link': inviteLink,
      'username': username,
      'cmty_id': cmtyId,
      'nickname': nickname,
      'review_time': reviewTime,
      'status': status,
      'expire_time': expireTime,
    };
  }

  /// 获取申请状态文本
  String getStatusText() {
    switch (status) {
      case 0:
        return '待审核';
      case 1:
        return '已通过';
      case 2:
        return '已拒绝';
      case 3:
        return '已过期';
      case 4:
        return '已取消';
      default:
        return '未知';
    }
  }
}

/// 社群加入申请列表模型
class JoinRequestListModel {
  final int total;
  final List<JoinRequest> records;

  JoinRequestListModel({
    required this.total,
    required this.records,
  });

  factory JoinRequestListModel.fromJson(Map<String, dynamic> json) {
    final recordsList = json['records'] as List<dynamic>? ?? [];
    final records = recordsList
        .map((item) => JoinRequest.fromJson(item as Map<String, dynamic>))
        .toList();

    return JoinRequestListModel(
      total: json['total'] as int? ?? 0,
      records: records,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'records': records.map((item) => item.toJson()).toList(),
    };
  }
}
