import 'package:bell_bird_talk/services/native_logger.dart';
import 'package:flutter/services.dart';

/// 社群管理功能封装
class CommunityBridge {
  final MethodChannel _bridge;

  CommunityBridge({MethodChannel? bridge})
      : _bridge = bridge ?? const MethodChannel('com.bellbird.talk/method');

  // ======================== 社群基础操作 ========================

  /// 获取社群列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 社群列表
  Future<Map<String, dynamic>> getCommunityList({
    int page = 1,
    int pageSize = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunityList', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetCommunityList', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunityList', {'page': page, 'pageSize': pageSize}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 获取社群信息
  /// @param cmtyId 社群ID
  /// @return 社群详细信息
  Future<Map<String, dynamic>> getCommunityInfo({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunityInfo', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetCommunityInfo', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunityInfo', {'cmtyId': cmtyId}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 加入社群
  /// @param cmtyId 社群ID
  /// @return 加入结果
  Future<Map<String, dynamic>> joinCommunity({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imJoinCommunity', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imJoinCommunity', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imJoinCommunity', {'cmtyId': cmtyId}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 离开社群
  /// @param cmtyId 社群ID
  /// @return 离开结果
  Future<Map<String, dynamic>> leaveCommunity({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imLeaveCommunity', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imLeaveCommunity', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imLeaveCommunity', {'cmtyId': cmtyId}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  // ======================== 分组管理 ========================

  /// 获取分组列表
  /// @param cmtyId 社群ID
  /// @return 分组列表
  Future<Map<String, dynamic>> getCommunityGroups({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunityGroups', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetCommunityGroups', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunityGroups', {'cmtyId': cmtyId}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  // ======================== 频道管理 ========================

  /// 获取频道列表
  /// @param cmtyId 社群ID
  /// @return 频道列表
  Future<Map<String, dynamic>> getChannels({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imGetChannels', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetChannels', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetChannels', {'cmtyId': cmtyId}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 创建频道
  /// @param cmtyId 社群ID
  /// @param categoryId 分类ID
  /// @param channelName 频道名称
  /// @param channelType 频道类型（0=文字频道，1=语音频道）
  /// @param description 频道描述（可选）
  /// @param maxMembers 最大成员数（可选，语音频道默认50）
  /// @return 创建结果
  Future<Map<String, dynamic>> createChannel({
    required String cmtyId,
    required String categoryId,
    required String channelName,
    required int channelType,
    String? description,
    int? maxMembers,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
        'channelName': channelName,
        'channelType': channelType,
      };
      if (description != null && description.isNotEmpty) {
        params['description'] = description;
      }
      if (maxMembers != null && maxMembers > 0) {
        params['maxMembers'] = maxMembers;
      }

      final result = await _bridge.invokeMethod<Map>('imCreateChannel', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imCreateChannel', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imCreateChannel', {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
        'channelName': channelName,
        'channelType': channelType,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 更新频道
  /// @param channelId 频道ID
  /// @param channelName 频道名称（可选）
  /// @param pauseInvite 是否暂停邀请（可选）
  /// @param muteAll 是否禁止发言（可选）
  /// @param notificationType 通知类型（可选）
  /// @return 更新结果
  Future<Map<String, dynamic>> updateChannel({
    required String channelId,
    String? channelName,
    bool? pauseInvite,
    bool? muteAll,
    int? notificationType,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'channelId': channelId,
      };
      if (channelName != null && channelName.isNotEmpty) {
        params['channelName'] = channelName;
      }
      if (pauseInvite != null) {
        params['pauseInvite'] = pauseInvite;
      }
      if (muteAll != null) {
        params['muteAll'] = muteAll;
      }
      if (notificationType != null && notificationType >= 0) {
        params['notificationType'] = notificationType;
      }

      final result = await _bridge.invokeMethod<Map>('imUpdateChannel', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imUpdateChannel', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imUpdateChannel', {
        'channelId': channelId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 删除频道
  /// @param channelId 频道ID
  /// @return 删除结果
  Future<Map<String, dynamic>> deleteChannel({
    required String channelId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'channelId': channelId,
      };

      final result = await _bridge.invokeMethod<Map>('imDeleteChannel', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imDeleteChannel', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imDeleteChannel', {
        'channelId': channelId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 进入频道
  /// @param channelId 频道ID
  /// @return 进入结果
  Future<Map<String, dynamic>> enterChannel({
    required String channelId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'channelId': channelId,
      };

      final result = await _bridge.invokeMethod<Map>('imEnterChannel', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imEnterChannel', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imEnterChannel', {
        'channelId': channelId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  // ======================== 频道分组管理 ========================

  /// 创建频道分组
  /// @param cmtyId 社群ID
  /// @param categoryName 分组名称
  /// @return 创建结果
  Future<Map<String, dynamic>> createChannelGroup({
    required String cmtyId,
    required String categoryName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'categoryName': categoryName,
      };

      final result = await _bridge.invokeMethod<Map>('imCreateChannelGroup', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imCreateChannelGroup', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imCreateChannelGroup', {
        'cmtyId': cmtyId,
        'categoryName': categoryName,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 更新频道分组
  /// @param cmtyId 社群ID
  /// @param categoryId 分组ID
  /// @param categoryName 分组名称
  /// @return 更新结果
  Future<Map<String, dynamic>> updateChannelGroup({
    required String cmtyId,
    required String categoryId,
    required String categoryName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
        'categoryName': categoryName,
      };

      final result = await _bridge.invokeMethod<Map>('imUpdateChannelGroup', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imUpdateChannelGroup', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imUpdateChannelGroup', {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
        'categoryName': categoryName,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 删除频道分组
  /// @param cmtyId 社群ID
  /// @param categoryId 分组ID
  /// @return 删除结果
  Future<Map<String, dynamic>> deleteChannelGroup({
    required String cmtyId,
    required String categoryId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
      };

      final result = await _bridge.invokeMethod<Map>('imDeleteChannelGroup', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imDeleteChannelGroup', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imDeleteChannelGroup', {
        'cmtyId': cmtyId,
        'categoryId': categoryId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  // ======================== 成员管理 ========================

  /// 获取社群成员列表
  /// @param cmtyId 社群ID
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 成员列表结果
  Future<Map<String, dynamic>> getCommunityMembers({
    required String cmtyId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'page': page,
        'pageSize': pageSize,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunityMembers', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetCommunityMembers', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunityMembers', {
        'cmtyId': cmtyId,
        'page': page,
        'pageSize': pageSize,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 获取社群封禁成员列表
  /// @param cmtyId 社群ID
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 封禁成员列表结果
  Future<Map<String, dynamic>> getCommunityBannedMembers({
    required String cmtyId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'page': page,
        'pageSize': pageSize,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunityBannedMembers', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imGetCommunityBannedMembers', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunityBannedMembers', {
        'cmtyId': cmtyId,
        'page': page,
        'pageSize': pageSize,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 禁言社群成员
  /// @param cmtyId 社群ID
  /// @param userId 用户ID
  /// @param mute 是否禁言（true=禁言，false=解除禁言）
  /// @param muteUntil 禁言到期时间戳（可选，0或未设置表示永久禁言，>0表示临时禁言）
  /// @return 禁言结果
  Future<Map<String, dynamic>> muteCommunityMember({
    required String cmtyId,
    required String userId,
    required bool mute,
    int muteUntil = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'userId': userId,
        'mute': mute,
        'muteUntil': muteUntil,
      };

      final result = await _bridge.invokeMethod<Map>('imMuteCommunityMember', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imMuteCommunityMember', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imMuteCommunityMember', {
        'cmtyId': cmtyId,
        'userId': userId,
        'mute': mute,
        'muteUntil': muteUntil,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 踢出社群成员
  /// @param cmtyId 社群ID
  /// @param userId 用户ID
  /// @return 踢出结果
  Future<Map<String, dynamic>> kickCommunityMember({
    required String cmtyId,
    required String userId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'userId': userId,
      };

      final result = await _bridge.invokeMethod<Map>('imKickCommunityMember', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imKickCommunityMember', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imKickCommunityMember', {
        'cmtyId': cmtyId,
        'userId': userId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 获取社群设置
  /// @param cmtyId 社群ID
  /// @return 社群设置结果
  Future<Map<String, dynamic>> getCommunitySettings({
    required String cmtyId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
      };

      final result = await _bridge.invokeMethod<Map>('imGetCommunitySettings', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
      stopwatch.stop();
      NativeLogger.log('imGetCommunitySettings', params, resultMap, stopwatch.elapsed);
      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imGetCommunitySettings', {
        'cmtyId': cmtyId,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 更新社群设置
  /// @param cmtyId 社群ID
  /// @param settings 设置项字典（键值对形式：{"allow_add_friend": true, ...}）
  /// @return 更新结果
  Future<Map<String, dynamic>> updateCommunitySettings({
    required String cmtyId,
    required Map<String, dynamic> settings,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'settings': settings,
      };

      final result = await _bridge.invokeMethod<Map>('imUpdateCommunitySettings', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imUpdateCommunitySettings', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imUpdateCommunitySettings', {
        'cmtyId': cmtyId,
        'settings': settings,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 查询加入申请列表
  /// @param cmtyId 社群ID
  /// @param status 申请状态筛选（可选，0=全部，1=待审核，2=已通过，3=已拒绝，4=已过期，5=已取消）
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 加入申请列表结果
  Future<Map<String, dynamic>> listJoinRequests({
    required String cmtyId,
    int status = 0,
    int page = 1,
    int pageSize = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'status': status,
        'page': page,
        'pageSize': pageSize,
      };

      final result = await _bridge.invokeMethod<Map>('imListJoinRequests', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imListJoinRequests', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imListJoinRequests', {
        'cmtyId': cmtyId,
        'status': status,
        'page': page,
        'pageSize': pageSize,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 审核加入申请
  /// @param cmtyId 社群ID
  /// @param requestId 申请ID
  /// @param approve 是否同意（true=同意，false=拒绝）
  /// @param reviewMessage 审核消息（可选，拒绝时可填写原因）
  /// @return 审核结果
  Future<Map<String, dynamic>> reviewJoinRequest({
    required String cmtyId,
    required int requestId,
    required bool approve,
    String reviewMessage = '',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'cmtyId': cmtyId,
        'requestId': requestId,
        'approve': approve,
      };
      if (reviewMessage.isNotEmpty) {
        params['reviewMessage'] = reviewMessage;
      }

      final result = await _bridge.invokeMethod<Map>('imReviewJoinRequest', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};

      stopwatch.stop();
      NativeLogger.log('imReviewJoinRequest', params, resultMap, stopwatch.elapsed);

      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imReviewJoinRequest', {
        'cmtyId': cmtyId,
        'requestId': requestId,
        'approve': approve,
      }, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
}
