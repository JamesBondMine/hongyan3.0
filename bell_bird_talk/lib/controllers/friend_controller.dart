


import 'dart:convert';

import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:get/get.dart';

class FriendController extends GetxController { 

  static FriendController get to => Get.put(FriendController());

  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  

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

  /// 获取所有分组及其联系人
  /// 返回格式: {
  ///   'groupId': {
  ///     'groupId': '分组ID',
  ///     'groupName': '分组名',
  ///     'count': 成员人数,
  ///     'contacts': [FriendModel...]
  ///   }
  /// }
  Future<Map<String, Map<String, dynamic>>> getContactsByGroup() async {
    try {
      // 获取当前用户ID
      final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        return {};
      }
      
      // 1. 获取所有分组列表
      final groups = await getFriendGroups();
      
      // 2. 从数据库获取所有联系人（按分组名分组）
      final groupedContactsByName = await _messageDatabase.getContactsByGroup(currentUserId);
      
      // 3. 创建分组ID到分组名的映射（用于快速查找）
      final Map<String, String> groupIdToNameMap = {};
      final Map<String, FriendGroup> groupNameToGroupMap = {};
      for (final group in groups) {
        groupIdToNameMap[group.id] = group.name;
        groupNameToGroupMap[group.name] = group;
      }
      
      // 4. 构建结果，结合分组信息和联系人列表
      final Map<String, Map<String, dynamic>> result = {};
      
      // 处理有分组ID的分组（从服务器获取的分组）
      for (final group in groups) {
        final groupName = group.name;
        final contacts = groupedContactsByName[groupName] ?? [];
        final contactModels = contacts.map((contact) => FriendModel.fromJson(contact)).toList();
        
        result[group.id] = {
          'groupId': group.id,
          'groupName': group.name,
          'count': contactModels.length, // 使用实际联系人数量
          'contacts': contactModels,
        };
      }
      
      // 5. 处理"未分组"（默认分组）
      final defaultGroupContacts = groupedContactsByName['未分组'] ?? [];
      if (defaultGroupContacts.isNotEmpty) {
        final contactModels = defaultGroupContacts.map((contact) => FriendModel.fromJson(contact)).toList();
        result['0'] = {
          'groupId': '0',
          'groupName': '未分组',
          'count': contactModels.length,
          'contacts': contactModels,
        };
      }
      
      return result;
    } catch (e) {
      print('❌ 获取所有分组及联系人失败: $e');
      return {};
    }
  }
    
}