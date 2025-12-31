


import 'dart:convert';

import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:get/get.dart';

class FriendController extends GetxController { 

  static FriendController get to => Get.put(FriendController());

  final IOSNativeService _nativeService = IOSNativeService();
  

  String friendGropRefreshId = 'friendGropRefreshId';
  void updateFriendGroupRefreshId() {
    update([friendGropRefreshId]);
  }


  // 获取好友分组
  Future<List<FriendGroup>> getFriendGroups() async {
    try {
      final result = await _nativeService.imGetContactGroups(page: 1, pageSize: 100);
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final groupsJson = data['groups'] as List? ?? [];
          return groupsJson.map((json) => FriendGroup.fromJson(json)).toList();
    
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}