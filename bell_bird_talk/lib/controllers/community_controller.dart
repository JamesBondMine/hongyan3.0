
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
  Future<bool> joinCommunity({
    required String cmtyId,
  }) async {
    bool success = false;
    try {
      final result = await _nativeService.imJoinCommunity(
        cmtyId: cmtyId,
      );

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

}