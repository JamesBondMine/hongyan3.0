import 'dart:convert';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../services/native_bridge.dart';

class NotiController extends GetxController {
  static NotiController get to => Get.put(NotiController());

  final IOSNativeService _nativeService = IOSNativeService();

  // 未读数量
  int unreadCount = 0;
  
  // 加载状态
  bool loading = false;
  
  // 通知列表
  List<Map<String, dynamic>> items = [];
  
  // 当前选中的Tab：0=全部, 1=未读, 2=已读
  int selectedTab = 0;


  // 刷新
  String notificationDataListRefreshId = 'notificationDataListRefreshId';
  void updateNotificationDataList() {
    update([notificationDataListRefreshId]);
  } 

  // 刷新
  String notificationBarRefreshId = 'notificationBarRefreshId';
  void updateNotificationBar() {
    update([notificationBarRefreshId]);
  } 

  @override
  void onInit() {
    super.onInit();
    // refresh();
  }

  

  /// 加载未读数量
  Future<void> loadUnread() async {
    final result = await _nativeService.imGetNotificationUnreadCount(types: ['0']);
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          unreadCount = (map['total_unread'] as num?)?.toInt() ?? 0;
          update();
        } catch (_) {
          // ignore parse error
        }
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取未读失败');
    }
  }

  /// 加载通知列表
  Future<void> loadList() async {
    loading = true;
    update();
    
    final result = await _nativeService.imPullNotifications(page: 1, pageSize: 50);
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final list = (map['notifications'] as List?) ?? [];
          items = list
              .map((e) => _mapNotification((e as Map).cast<String, dynamic>()))
              .toList();
        } catch (e) {
          EasyLoading.showError('解析通知失败');
          items = [];
        }
      } else {
        items = [];
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取通知失败');
      items = [];
    }
    
    loading = false;
    update();
  }

  /// 切换Tab
  void switchTab(int index) {
    selectedTab = index;
    update([notificationBarRefreshId, notificationDataListRefreshId]);
  }

  /// 获取过滤后的通知列表
  List<Map<String, dynamic>> get filteredItems {
    switch (selectedTab) {
      case 1: // 未读
        return items.where((item) {
          final status = (item['status'] as num?)?.toInt() ?? 0;
          return status == 0; // 0=UNREAD
        }).toList();
      case 2: // 已读
        return items.where((item) {
          final status = (item['status'] as num?)?.toInt() ?? 0;
          return status != 0; // 非0=已读
        }).toList();
      default: // 全部
        return items;
    }
  }

  /// 提取更友好的展示字段
  Map<String, dynamic> _mapNotification(Map<String, dynamic> raw) {
    final type = (raw['notification_type'] as String?) ?? '';
    final title = (raw['title'] as String?) ?? '';
    final contentStr = (raw['content'] as String?) ?? '';
    Map<String, dynamic> contentJson = {};
    try {
      if (contentStr.isNotEmpty) {
        contentJson = (json.decode(contentStr) as Map).cast<String, dynamic>();
      }
    } catch (_) {}

    String displayTitle = title;
    String displayBody = '';
    final friendName = (contentJson['friendName'] as String?) ??
        (contentJson['name'] as String?) ??
        (raw['related_user_id'] as String?) ??
        '';

    switch (type) {
      case 'FRIEND_REQUEST':
        displayTitle = '新的好友请求';
        displayBody =
            friendName.isNotEmpty ? '$friendName 请求添加你为好友' : '收到一条好友请求';
        break;
      case 'FRIEND_ADD':
        displayTitle = '新的好友请求';
        displayBody =
            friendName.isNotEmpty ? '$friendName 请求添加你为好友' : '收到一条好友请求';
        break;
      case 'FRIEND_REQUEST_ACCEPTED':
        displayTitle = '好友申请已通过';
        displayBody =
            friendName.isNotEmpty ? '$friendName 通过了你的好友申请' : '你的好友申请已通过';
        break;
      default:
        displayTitle = title.isNotEmpty ? title : '通知';
        displayBody = contentJson.isNotEmpty
            ? (contentJson['text'] as String? ??
                contentJson['content'] as String? ??
                contentStr)
            : (contentStr.isNotEmpty ? contentStr : '');
    }

    return {
      ...raw,
      'display_title': displayTitle,
      'display_body': displayBody,
      'content_json': contentJson,
      'display_friend_name': friendName,
    };
  }
}
