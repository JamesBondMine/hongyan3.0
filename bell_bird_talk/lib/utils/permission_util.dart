import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// 权限管理工具类
class PermissionUtil {
  static PermissionUtil? _instance;
  
  // 单例模式
  factory PermissionUtil() {
    _instance ??= PermissionUtil._internal();
    return _instance!;
  }
  
  PermissionUtil._internal();
  
  // ==================== 相机权限 ====================
  
  /// 请求相机权限
  Future<bool> requestCamera() async {
    return await _requestPermission(
      Permission.camera,
      '相机权限',
      '需要访问相机以拍照',
    );
  }
  
  /// 检查相机权限
  Future<bool> checkCamera() async {
    return await Permission.camera.isGranted;
  }
  
  // ==================== 相册/存储权限 ====================
  
  /// 请求相册权限
  Future<bool> requestPhotos() async {
    return await _requestPermission(
      Permission.photos,
      '相册权限',
      '需要访问相册以选择图片',
    );
  }
  
  /// 请求存储权限
  Future<bool> requestStorage() async {
    return await _requestPermission(
      Permission.storage,
      '存储权限',
      '需要访问存储以保存文件',
    );
  }
  
  /// 检查相册权限
  Future<bool> checkPhotos() async {
    return await Permission.photos.isGranted;
  }
  
  // ==================== 麦克风权限 ====================
  
  /// 请求麦克风权限
  Future<bool> requestMicrophone() async {
    return await _requestPermission(
      Permission.microphone,
      '麦克风权限',
      '需要访问麦克风以录音',
    );
  }
  
  /// 检查麦克风权限
  Future<bool> checkMicrophone() async {
    return await Permission.microphone.isGranted;
  }
  
  // ==================== 位置权限 ====================
  
  /// 请求位置权限（使用时）
  Future<bool> requestLocation() async {
    return await _requestPermission(
      Permission.locationWhenInUse,
      '位置权限',
      '需要访问位置信息',
    );
  }
  
  /// 请求位置权限（始终）
  Future<bool> requestLocationAlways() async {
    return await _requestPermission(
      Permission.locationAlways,
      '位置权限',
      '需要始终访问位置信息',
    );
  }
  
  /// 检查位置权限
  Future<bool> checkLocation() async {
    return await Permission.locationWhenInUse.isGranted;
  }
  
  // ==================== 通知权限 ====================
  
  /// 请求通知权限
  Future<bool> requestNotification() async {
    return await _requestPermission(
      Permission.notification,
      '通知权限',
      '需要发送通知以提醒您',
    );
  }
  
  /// 检查通知权限
  Future<bool> checkNotification() async {
    return await Permission.notification.isGranted;
  }
  
  // ==================== 通讯录权限 ====================
  
  /// 请求通讯录权限
  Future<bool> requestContacts() async {
    return await _requestPermission(
      Permission.contacts,
      '通讯录权限',
      '需要访问通讯录以选择联系人',
    );
  }
  
  /// 检查通讯录权限
  Future<bool> checkContacts() async {
    return await Permission.contacts.isGranted;
  }
  
  // ==================== 日历权限 ====================
  
  /// 请求日历权限
  Future<bool> requestCalendar() async {
    return await _requestPermission(
      Permission.calendar,
      '日历权限',
      '需要访问日历',
    );
  }
  
  /// 检查日历权限
  Future<bool> checkCalendar() async {
    return await Permission.calendar.isGranted;
  }
  
  // ==================== 通用权限请求 ====================
  
  /// 请求权限（通用方法）
  Future<bool> _requestPermission(
    Permission permission,
    String name,
    String description,
  ) async {
    // 检查权限状态
    final status = await permission.status;
    
    // 已授权
    if (status.isGranted) {
      return true;
    }
    
    // 已拒绝且不再询问
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(name, description);
      return false;
    }
    
    // 请求权限
    final result = await permission.request();
    
    // 已授权
    if (result.isGranted) {
      return true;
    }
    
    // 被拒绝且不再询问
    if (result.isPermanentlyDenied) {
      _showOpenSettingsDialog(name, description);
      return false;
    }
    
    // 被拒绝
    return false;
  }
  
  /// 显示打开设置对话框
  void _showOpenSettingsDialog(String name, String description) {
    Get.defaultDialog(
      title: '需要$name',
      middleText: '$description\n\n请在设置中开启$name',
      textConfirm: '去设置',
      textCancel: '取消'.tr,
      onConfirm: () {
        openAppSettings();
        Get.back();
      },
    );
  }
  
  // ==================== 批量权限请求 ====================
  
  /// 请求多个权限
  Future<Map<Permission, bool>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    final results = await permissions.request();
    return results.map((key, value) => MapEntry(key, value.isGranted));
  }
  
  /// 请求聊天所需的所有权限
  Future<bool> requestChatPermissions() async {
    final results = await requestMultiplePermissions([
      Permission.camera,
      Permission.photos,
      Permission.microphone,
      Permission.storage,
    ]);
    
    // 所有权限都授予才返回 true
    return results.values.every((granted) => granted);
  }
  
  // ==================== 权限状态检查 ====================
  
  /// 检查权限状态
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }
  
  /// 权限是否被永久拒绝
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
  
  /// 打开应用设置
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

/// 权限枚举扩展
extension PermissionExtension on Permission {
  /// 获取权限名称
  String get displayName {
    switch (this) {
      case Permission.camera:
        return '相机';
      case Permission.photos:
        return '相册';
      case Permission.storage:
        return '存储';
      case Permission.microphone:
        return '麦克风';
      case Permission.locationWhenInUse:
      case Permission.locationAlways:
        return '位置';
      case Permission.notification:
        return '通知';
      case Permission.contacts:
        return '通讯录';
      case Permission.calendar:
        return '日历';
      default:
        return '未知';
    }
  }
}

