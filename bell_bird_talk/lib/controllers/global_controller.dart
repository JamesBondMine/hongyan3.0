import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../utils/storage_util.dart';
import '../config/constants.dart';
import '../network/http_client.dart';
import '../network/websocket_client.dart';
import '../services/native_bridge.dart';

/// 全局控制器 - 管理应用全局状态
class GlobalController extends GetxController {
  // 用户信息
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  
  // 是否已登录
  final RxBool isLoggedIn = false.obs;
  
  // Token
  final RxString token = ''.obs;
  
  // 主题模式
  final RxBool isDarkMode = false.obs;
  
  // 语言
  final RxString language = 'zh_CN'.obs;
  
  // 网络状态
  final RxBool isOnline = true.obs;
  
  // WebSocket 连接状态
  final RxBool isWsConnected = false.obs;
  
  // 未读消息数
  final RxInt unreadCount = 0.obs;
  
  // IM SDK 状态
  final RxBool isIMSDKInitialized = false.obs;
  final RxString imsdkStatus = '未初始化'.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadLocalData();
    _listenWebSocketState();
    initializeIMSDK(); // 初始化 IM SDK
  }
  
  // ==================== 用户相关 ====================
  
  /// 加载本地数据
  Future<void> _loadLocalData() async {
    // 加载 Token
    final savedToken = StorageUtil().getString(AppConstants.keyToken);
    if (savedToken != null && savedToken.isNotEmpty) {
      token.value = savedToken;
      isLoggedIn.value = true;
      
      // 更新 HTTP 客户端的 Token
      HttpClient().updateToken(savedToken);
      
      // 加载用户信息
      final userJson = StorageUtil().getObject(
        AppConstants.keyUserInfo,
        (json) => json,
      );
      if (userJson != null) {
        currentUser.value = UserModel.fromJson(userJson);
      }
    }
    
    // 加载主题设置
    final savedTheme = StorageUtil().getBool(AppConstants.keyTheme);
    if (savedTheme != null) {
      isDarkMode.value = savedTheme;
    }
    
    // 加载语言设置
    final savedLanguage = StorageUtil().getString(AppConstants.keyLanguage);
    if (savedLanguage != null) {
      language.value = savedLanguage;
    }
  }
  
  /// 保存用户登录信息
  Future<void> saveLoginInfo(String newToken, UserModel user) async {
    token.value = newToken;
    currentUser.value = user;
    isLoggedIn.value = true;
    
    // 保存到本地
    await StorageUtil().setString(AppConstants.keyToken, newToken);
    await StorageUtil().setObject(AppConstants.keyUserInfo, user.toJson());
    await StorageUtil().setString(AppConstants.keyUserId, user.id);
    
    // 更新 HTTP 客户端的 Token
    HttpClient().updateToken(newToken);
    
    // 连接 WebSocket
    await connectWebSocket();
    
    print('✅ 用户登录成功: ${user.nickname}');
  }
  
  /// 退出登录
  Future<void> logout() async {
    // 断开 WebSocket
    await WebSocketClient().disconnect();
    
    // 清空状态
    token.value = '';
    currentUser.value = null;
    isLoggedIn.value = false;
    unreadCount.value = 0;
    
    // 清空本地存储
    await StorageUtil().remove(AppConstants.keyToken);
    await StorageUtil().remove(AppConstants.keyUserInfo);
    await StorageUtil().remove(AppConstants.keyUserId);
    
    // 清除 HTTP 客户端的 Token
    HttpClient().clearToken();
    
    print('✅ 用户已退出登录');
  }
  
  /// 更新用户信息
  Future<void> updateUserInfo(UserModel user) async {
    currentUser.value = user;
    await StorageUtil().setObject(AppConstants.keyUserInfo, user.toJson());
  }
  
  // ==================== 主题相关 ====================
  
  /// 切换主题
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await StorageUtil().setBool(AppConstants.keyTheme, isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
  
  /// 设置主题
  Future<void> setTheme(bool dark) async {
    isDarkMode.value = dark;
    await StorageUtil().setBool(AppConstants.keyTheme, dark);
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
  }
  
  // ==================== 语言相关 ====================
  
  /// 切换语言
  Future<void> changeLanguage(String lang) async {
    language.value = lang;
    await StorageUtil().setString(AppConstants.keyLanguage, lang);
    // Get.updateLocale(Locale(lang));
  }
  
  // ==================== WebSocket 相关 ====================
  
  /// 连接 WebSocket
  Future<void> connectWebSocket() async {
    if (token.value.isEmpty) {
      print('⚠️ 未登录，无法连接 WebSocket');
      return;
    }
    
    await WebSocketClient().connect(
      headers: {'token': token.value},
    );
  }
  
  /// 断开 WebSocket
  Future<void> disconnectWebSocket() async {
    await WebSocketClient().disconnect();
  }
  
  /// 监听 WebSocket 状态
  void _listenWebSocketState() {
    WebSocketClient().stateStream.listen((state) {
      isWsConnected.value = state == WebSocketState.connected;
    });
  }
  
  // ==================== 未读消息相关 ====================
  
  /// 增加未读数
  void increaseUnreadCount([int count = 1]) {
    unreadCount.value += count;
  }
  
  /// 减少未读数
  void decreaseUnreadCount([int count = 1]) {
    unreadCount.value = (unreadCount.value - count).clamp(0, 999);
  }
  
  /// 清空未读数
  void clearUnreadCount() {
    unreadCount.value = 0;
  }
  
  /// 设置未读数
  void setUnreadCount(int count) {
    unreadCount.value = count.clamp(0, 999);
  }
  
  // ==================== IM SDK 相关 ====================
  
  /// 初始化 IM SDK
  Future<void> initializeIMSDK() async {
    try {
      print('🚀 开始初始化 IM SDK...');
      imsdkStatus.value = '正在初始化...';
      
      final nativeService = IOSNativeService();
      
      // 1. 初始化（添加超时保护）
      final initResult = await nativeService.imInitialize()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('⚠️ IM SDK 初始化超时');
        return false;
      });
      
      if (initResult) {
        print('✅ IM SDK 初始化成功');
        isIMSDKInitialized.value = true;
        imsdkStatus.value = '初始化成功';
        
        // 2. 启动网络服务（添加超时保护）
        imsdkStatus.value = '正在启动网络服务...';
        final startResult = await nativeService.imStart()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          print('⚠️ IM SDK 网络服务启动超时');
          return false;
        });
        
        if (startResult) {
          print('✅ IM SDK 网络服务启动成功');
          imsdkStatus.value = '运行中';
        } else {
          print('❌ IM SDK 网络服务启动失败');
          imsdkStatus.value = '启动失败';
        }
      } else {
        print('❌ IM SDK 初始化失败');
        imsdkStatus.value = '初始化失败';
      }
    } catch (e, stackTrace) {
      print('❌ IM SDK 初始化异常: $e');
      print('Stack trace: $stackTrace');
      imsdkStatus.value = '初始化异常';
      isIMSDKInitialized.value = false;
    }
  }
  
  /// 获取 IM SDK 状态
  String getIMSDKStatus() {
    return imsdkStatus.value;
  }
}

