import 'package:get/get.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityController extends GetxController {
  static CommunityController get to => Get.put(CommunityController());

  final IOSNativeService _nativeService = IOSNativeService();

  // 社群列表
  final RxList<CommunityModel> communityList = <CommunityModel>[].obs;

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 缓存相关方法
  Future<List<CommunityModel>> _loadCachedCommunities() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('community_list');
    if (cachedData != null) {
      final data = json.decode(cachedData) as List<dynamic>;
      return data.map((item) => CommunityModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _saveCommunitiesToCache(List<CommunityModel> communities) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(communities.map((c) => c.toJson()).toList());
    await prefs.setString('community_list', data);
  }

  // 刷新
  String menuSliderRefreshId = 'menuSliderRefreshId';
  void updateListenProgressPanRefresh() {
    update([menuSliderRefreshId]);
  }

  double sliderValue = 0.0;

  double currentPlaySeconds = 0;

  /// 获取社群列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  Future<List<CommunityModel>> getCommunityList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      isLoading.value = true;

      // Load from cache first if page == 1
      final cachedCommunities = await _loadCachedCommunities();
      if (cachedCommunities.isNotEmpty && page == 1) {
        communityList.value = cachedCommunities;
      }

      final result = await _nativeService.imGetCommunityList(
        page: page,
        pageSize: pageSize,
      );

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          final data = json.decode(dataStr) as Map<String, dynamic>;
          final communitiesData = data['communities'] as List<dynamic>? ?? [];

          List<CommunityModel> communities = communitiesData.map((item) {
            return CommunityModel.fromJson(Map<String, dynamic>.from(item));
          }).toList();

          if (page == 1) {
            communityList.value = communities;
            // Save to cache
            await _saveCommunitiesToCache(communities);
          } else {
            communityList.addAll(communities);
          }
          return communities;
        }
      } else {
        print('获取社群列表失败: ${result['message']}');
        // Return cached data if available
        return cachedCommunities;
      }
      return cachedCommunities;
    } catch (e) {
      print('获取社群列表异常: $e');
      // Return cached data if available
      final cachedCommunities = await _loadCachedCommunities();
      return cachedCommunities;
    } finally {
      isLoading.value = false;
    }
  }

  /// 加入社群
  /// @param cmtyId 社群ID
  Future<bool> joinCommunity({required String cmtyId}) async {
    bool success = false;
    try {
      final result = await _nativeService.imJoinCommunity(cmtyId: cmtyId);

      if (result['errorCode'] == 0) {
        success = true;
        // 可以在这里更新本地状态，比如刷新社群列表
        await getCommunityList(page: 1, pageSize: 20);
      } else {
        print('加入社群失败: ${result['message']}');
      }

      return success;
    } catch (e) {
      print('加入社群异常: $e');
      return success;
    }
  }

  /// 获取社群信息
  /// @param cmtyId 社群ID
  Future<CommunityModel?> getCommunityInfo({required String cmtyId}) async {
    try {
      final result = await _nativeService.imGetCommunityInfo(cmtyId: cmtyId);

      if (result['errorCode'] == 0) {
        // 解析社群信息
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr) as Map<String, dynamic>;
          return CommunityModel.fromJson(data);
        }
      } else {
        print('获取社群信息失败: ${result['message']}');
      }
      return null;
    } catch (e) {
      print('获取社群信息异常: $e');
      return null;
    }
  }

  // 获取社群频道分组
  Future<List<CmtGroupModel>> getChannelGroups(String cmtyId) async {
    try {
      final nativeService = IOSNativeService(); // Create new instance
      final groupsResult = await nativeService.imGetCommunityGroups(
        cmtyId: cmtyId,
      );
      if (groupsResult['errorCode'] != 0) {
        return [];
      }
      // 解析分组列表
      final groupsDataStr = groupsResult['data'] as String? ?? '';
      if (groupsDataStr.isNotEmpty) {
        final groupsData = json.decode(groupsDataStr);
        List gdataList = groupsData is List ? groupsData : [];
        return gdataList.map((item) {
          return CmtGroupModel.fromJson(Map<String, dynamic>.from(item));
        }).toList();
      }
      return [];
    } catch (e) {
      print('获取社群分组和频道异常: $e');
      return [];
    }
  }

  // 获取社群频道列表
  static Future<List<ChannelModel>> getChannel(String cmtyId) async {
    try {
      final nativeService = IOSNativeService(); // Create new instance
      final channelsResult = await nativeService.imGetChannels(cmtyId: cmtyId);
      if (channelsResult['errorCode'] != 0) {
        return [];
      }
      // 解析分组列表
      final channelsDataStr = channelsResult['data'] as String? ?? '';
      if (channelsDataStr.isNotEmpty) {
        final channelsData = json.decode(channelsDataStr);
        if (channelsData is List) {
          List rawList = channelsData;
          return rawList.map((item) => ChannelModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('获取社群分组和频道异常: $e');
      return [];
    }
  }

  /// 获取社群分组和频道（分组里嵌套频道）
  Future<CommunityGChannels> getCommunityGroupsWithChannels({
    required String cmtyId,
  }) async {
    try {
      isLoading.value = true;

      // 1. 获取分组列表
      List<CmtGroupModel> groupsList = await getChannelGroups(cmtyId);

      if (groupsList.isEmpty) {
        return CommunityGChannels(
          categories: [],
          categoryIdMap: {},
          channels: <ChannelModel>[],
        );
      }

      // 2. 获取频道列表
      List<ChannelModel> channelsList = await getChannel(cmtyId);
      if (channelsList.isEmpty) {
        // 即使获取频道失败，也返回分组（频道为空）
        final result = _buildGroupsWithChannels(groupsList, []);
        return CommunityGChannels(
          categories: [],
          categoryIdMap: {},
          channels: result['channels'] as List<ChannelModel>,
        );
      }
      // 3. 组合成分组嵌套频道的结构
      final result = _buildGroupsWithChannels(groupsList, channelsList);
      return CommunityGChannels(
        categories: result['categories'] as List<CmtGroupModel>,
        categoryIdMap: result['categoryIdMap'],
        channels: result['channels'] as List<ChannelModel>,
      );
    } catch (e) {
      print('获取分组和频道异常: $e');
      return CommunityGChannels(
        categories: [],
        categoryIdMap: {},
        channels: <ChannelModel>[],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 构建分组嵌套频道的结构
  /// @param groupsList 分组列表
  /// @param channelsList 频道列表（使用 ChannelModel）
  /// @return Map，包含：
  Map<String, dynamic> _buildGroupsWithChannels(
    List<CmtGroupModel> groupsList,
    List<ChannelModel> channelsList,
  ) {
    final List<CmtGroupModel> categories = groupsList;
    final Map<String, List<ChannelModel>> categoryIdMap = {};

    // 遍历分组
    for (var group in groupsList) {
      // 获取分组信息（根据实际API返回的字段名调整）
      final groupId = group.id;
      // 查找该分组下的频道
      List<ChannelModel> channels = [];
      for (var channel in channelsList) {
        // 如果频道属于当前分组
        if (channel.categoryId == groupId) {
          channels.add(channel);
        }
      }
      // 组装数据
      categoryIdMap[groupId] = channels.isEmpty ? [] : channels;
    }

    // 如果部分频道没有分组、那么这些频道和分组放在一个层级啊
    List<ChannelModel> freeChannelsList = channelsList
        .where((e) => e.categoryId.isEmpty)
        .toList();
    if (freeChannelsList.isNotEmpty) {
      for (var i = 0; i < freeChannelsList.length; i++) {
        ChannelModel cm = freeChannelsList[i];
        CmtGroupModel gm = CmtGroupModel(
          id: cm.channelId,
          name: cm.channelName,
          communityId: cm.communityId,
          description: '',
        );
        gm.isChannel = true;
        categories.insert(0, gm);
      }
    }
    // 如果没有任何分组，但存在频道，直接展示频道即可
    return {
      'categories': categories,
      'categoryIdMap': categoryIdMap,
      'channels': channelsList, // 返回完整的频道列表
    };
  }

  /// 创建频道
  /// @param cmtyId 社群ID
  /// @param categoryId 分类ID
  /// @param channelName 频道名称
  /// @param channelType 频道类型（0=文字频道，1=语音频道）
  /// @param description 频道描述（可选）
  /// @param maxMembers 最大成员数（可选，语音频道默认50）
  /// @return 创建结果
  Future<bool> createChannel({
    required String cmtyId,
    required String categoryId,
    required String channelName,
    required int channelType,
    String? description,
    int? maxMembers,
  }) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imCreateChannel(
        cmtyId: cmtyId,
        categoryId: categoryId,
        channelName: channelName,
        channelType: channelType,
        description: description,
        maxMembers: maxMembers,
      );

      if (result['errorCode'] == 0) {
        // 创建成功后，刷新分组和频道列表
        return true;
      } else {
        print('创建频道失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('创建频道异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新频道
  /// @param channelId 频道ID
  /// @param channelName 频道名称（可选）
  /// @param pauseInvite 是否暂停邀请（可选）
  /// @param muteAll 是否禁止发言（可选）
  /// @param notificationType 通知类型（可选）
  /// @return 更新结果
  Future<bool> updateChannel({
    required String channelId,
    String? channelName,
    bool? pauseInvite,
    bool? muteAll,
    int? notificationType,
  }) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imUpdateChannel(
        channelId: channelId,
        channelName: channelName,
        pauseInvite: pauseInvite,
        muteAll: muteAll,
        notificationType: notificationType,
      );

      if (result['errorCode'] == 0) {
        // 更新成功后，可以刷新分组和频道列表
        return true;
      } else {
        print('更新频道失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('更新频道异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除频道
  /// @param channelId 频道ID
  /// @return 删除结果
  Future<bool> deleteChannel({required String channelId}) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imDeleteChannel(channelId: channelId);

      if (result['errorCode'] == 0) {
        // 删除成功后，可以刷新分组和频道列表
        return true;
      } else {
        print('删除频道失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('删除频道异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 进入频道
  /// @param channelId 频道ID
  /// @return 进入结果
  Future<bool> enterChannel({required String channelId}) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imEnterChannel(channelId: channelId);

      if (result['errorCode'] == 0) {
        // 进入成功后，可以执行后续操作（如跳转到频道聊天页面）
        return true;
      } else {
        print('进入频道失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('进入频道异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 创建频道分组
  /// @param cmtyId 社群ID
  /// @param categoryName 分组名称
  /// @return 创建结果
  Future<bool> createChannelGroup({
    required String cmtyId,
    required String categoryName,
  }) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imCreateChannelGroup(
        cmtyId: cmtyId,
        categoryName: categoryName,
      );

      if (result['errorCode'] == 0) {
        return true;
      } else {
        print('创建频道分组失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('创建频道分组异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新频道分组
  /// @param cmtyId 社群ID
  /// @param categoryId 分组ID
  /// @param categoryName 分组名称
  /// @return 更新结果
  Future<bool> updateChannelGroup({
    required String cmtyId,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imUpdateChannelGroup(
        cmtyId: cmtyId,
        categoryId: categoryId,
        categoryName: categoryName,
      );

      if (result['errorCode'] == 0) {
        return true;
      } else {
        print('更新频道分组失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('更新频道分组异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除频道分组
  /// @param cmtyId 社群ID
  /// @param categoryId 分组ID
  /// @return 删除结果
  Future<bool> deleteChannelGroup({
    required String cmtyId,
    required String categoryId,
  }) async {
    try {
      isLoading.value = true;

      final result = await _nativeService.imDeleteChannelGroup(
        cmtyId: cmtyId,
        categoryId: categoryId,
      );

      if (result['errorCode'] == 0) {
        return true;
      } else {
        print('删除频道分组失败: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('删除频道分组异常: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
