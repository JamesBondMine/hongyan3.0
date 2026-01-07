
import 'package:get/get.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'dart:convert';

class CommunityController extends GetxController {
  static CommunityController get to => Get.put(CommunityController());

  final IOSNativeService _nativeService = IOSNativeService();
  
  // 社群列表
  final RxList<CommunityModel> communityList = <CommunityModel>[].obs;
  
  // 是否正在加载
  final RxBool isLoading = false.obs;

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
  Future<void> getCommunityList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      isLoading.value = true;
      
      final result = await _nativeService.imGetCommunityList(
        page: page,
        pageSize: pageSize,
      );
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          final data = json.decode(dataStr) as Map<String, dynamic>;
          final communitiesData = data['communities'] as List<dynamic>? ?? [];
          
          final List<CommunityModel> communities = communitiesData.map((item) {
            return CommunityModel.fromJson(Map<String, dynamic>.from(item));
          }).toList();
          
          if (page == 1) {
            communityList.value = communities;
          } else {
            communityList.addAll(communities);
          }
        }
      } else {
        print('获取社群列表失败: ${result['message']}');
      }
    } catch (e) {
      print('获取社群列表异常: $e');
    } finally {
      isLoading.value = false;
    }
  }

}