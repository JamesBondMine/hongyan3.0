import 'package:get/get.dart';
import '../services/native_bridge.dart';
import '../services/message_database.dart';
import 'dart:convert';

class UserController extends GetxController { 

  static UserController get to => Get.put(UserController());

  final IOSNativeService _nativeService = IOSNativeService();

  /// 获取联系人列表
  Future<Map<String, dynamic>> getContactList({
    required int page,
    required int pageSize,
    int? groupId,
    required int relationship,
  }) async {
    final result = await _nativeService.imGetContactList(
      page: page,
      pageSize: pageSize,
      groupId: groupId,
      relationship: relationship,
    );

    // 如果获取成功，更新数据库中的用户信息
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        final data = json.decode(dataStr);
        final contactsJson = data['contacts'] as List? ?? [];

        // 提取用户信息用于更新数据库
        final usersInfo = contactsJson.map((contact) {
          return {
            'user_id': contact['contact_user_id'] ?? '',
            'nickname': contact['nickname'] ?? '',
            'avatar': contact['avatar'] ?? '',
            'account_id': contact['account_id'] ?? '',
            'online_status': contact['online_status'] ?? 0,
            'phone': contact['phone'] ?? contact['target_phone'] ?? '',
            'email': contact['email'] ?? contact['target_email'] ?? '',
            // 其他字段使用默认值或空
            'sex': 0,
            'signature': null,
            'region': null,
            'background_file': null,
            'last_online_time': null,
          };
        }).toList();

        // 批量更新用户信息到数据库
        if (usersInfo.isNotEmpty) {
          await MessageDatabase().upsertUsers(usersInfo);
        }
      }
    }

    return result;
  }

}