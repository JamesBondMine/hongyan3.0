import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../utils/storage_util.dart';
import '../config/constants.dart';
import '../network/http_client.dart';
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
  
  // SDK 连接状态（由 SDK 管理）
  final RxBool isWsConnected = false.obs;
  
  // 未读消息数
  final RxInt unreadCount = 0.obs;
  
  // 刷新触发器（用于通知页面刷新）
  final RxInt refreshFriendList = 0.obs;
  final RxInt refreshFriendRequests = 0.obs;
  final RxInt refreshChatList = 0.obs;
  
  // 新消息通知（用于实时更新聊天列表）
  final Rx<Map<String, dynamic>?> newMessage = Rx<Map<String, dynamic>?>(null);
  
  /// 触发好友列表刷新
  void triggerFriendListRefresh() => refreshFriendList.value++;
  
  /// 触发好友申请列表刷新
  void triggerFriendRequestsRefresh() => refreshFriendRequests.value++;
  
  /// 触发聊天列表刷新
  void triggerChatListRefresh() => refreshChatList.value++;
  
  /// 触发所有列表刷新
  void triggerAllListRefresh() {
    refreshFriendList.value++;
    refreshFriendRequests.value++;
    refreshChatList.value++;
  }
  
  /// 触发联系人相关刷新（好友列表 + 好友申请）
  void triggerContactRefresh() {
    refreshFriendList.value++;
    refreshFriendRequests.value++;
  }
  
  /// 收到新消息，通知聊天列表更新
  void onNewMessageReceived(Map<String, dynamic> message) {
    newMessage.value = message;
    // 更新总未读数
    unreadCount.value++;
  }
  
  // IM SDK 状态
  final RxBool isIMSDKInitialized = false.obs;
  final RxString imsdkStatus = '未初始化'.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadLocalData();
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
    
    print('✅ 用户登录成功: ${user.nickname}');
  }
  
  /// 退出登录
  Future<void> logout() async {
    // 1. 调用 SDK 退出登录（断开 MQTT 连接）
    try {
      final nativeService = IOSNativeService();
      final result = await nativeService.imLogout(userId: currentUser.value?.id);
      print('🚪 SDK 退出登录结果: $result');
    } catch (e) {
      print('⚠️ SDK 退出登录异常: $e');
    }
    
    // 2. 清空状态
    token.value = '';
    currentUser.value = null;
    isLoggedIn.value = false;
    unreadCount.value = 0;
    
    // 3. 清空本地存储
    await StorageUtil().remove(AppConstants.keyToken);
    await StorageUtil().remove(AppConstants.keyUserInfo);
    await StorageUtil().remove(AppConstants.keyUserId);
    
    // 4. 清除 HTTP 客户端的 Token
    HttpClient().clearToken();
    
    // 5. 清空消息回调
    newMessage.value = null;
    
    print('✅ 用户已退出登录');
  }
  
  /// 注销当前用户（删除账号）
  Future<Map<String, dynamic>> deleteAccount() async {
    Map<String, dynamic> result = {'errorCode': -1, 'message': '未知错误'};
    try {
      final nativeService = IOSNativeService();
      result = await nativeService.imDeleteUser();
      print('🗑 SDK 注销用户结果: $result');
      if (result['errorCode'] == 0) {
        // 本地也做一次彻底登出清理
        await logout();
      }
    } catch (e) {
      print('⚠️ SDK 注销用户异常: $e');
      result = {'errorCode': -999, 'message': e.toString()};
    }
    return result;
  }
  
  /// 更新用户信息
  Future<void> updateUserInfo(UserModel user) async {
    currentUser.value = user;
    await StorageUtil().setObject(AppConstants.keyUserInfo, user.toJson());
  }
  
  /// 更新用户昵称
  Future<void> updateUserNickname(String nickname) async {
    final user = currentUser.value;
    if (user != null) {
      final updatedUser = user.copyWith(nickname: nickname);
      await updateUserInfo(updatedUser);
    }
  }
  
  /// 更新用户签名
  Future<void> updateUserSignature(String signature) async {
    final user = currentUser.value;
    if (user != null) {
      final updatedUser = user.copyWith(signature: signature);
      await updateUserInfo(updatedUser);
    }
  }
  
  /// 更新用户性别
  Future<void> updateUserGender(int gender) async {
    final user = currentUser.value;
    if (user != null) {
      final updatedUser = user.copyWith(gender: gender);
      await updateUserInfo(updatedUser);
    }
  }
  
  /// 更新用户头像
  Future<void> updateUserAvatar(String avatar) async {
    final user = currentUser.value;
    if (user != null) {
      final updatedUser = user.copyWith(avatar: avatar);
      await updateUserInfo(updatedUser);
    }
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
  
  // ==================== Token 自动登录 ====================
  
  /// Token 自动登录状态
  final RxBool isAutoLogging = false.obs;
  final RxString autoLoginStatus = ''.obs;
  
  /// 使用 Token 自动登录
  /// 返回 true 表示登录成功，false 表示登录失败
  Future<bool> autoLoginWithToken() async {
    // 检查本地是否有保存的 Token
    final savedToken = StorageUtil().getString(AppConstants.keyToken);
    if (savedToken == null || savedToken.isEmpty) {
      print('⚠️ 没有保存的 Token，跳过自动登录');
      return false;
    }
    
    print('🔐 开始 Token 自动登录...');
    isAutoLogging.value = true;
    autoLoginStatus.value = '正在自动登录...';
    
    try {
      final nativeService = IOSNativeService();
      
      // 调用 Token 登录
      final result = await nativeService.imLoginWithToken(token: savedToken)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('⚠️ Token 登录超时');
        return {'errorCode': -408, 'message': '登录超时'};
      });
      
      print('📊 Token 登录结果: $result');
      
      final errorCode = result['errorCode'] as int? ?? -1;
      
      if (errorCode == 0) {
        // 登录成功
        print('✅ Token 自动登录成功');
        autoLoginStatus.value = '登录成功';
        
        // 解析返回的用户数据（如果有）
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final dataMap = json.decode(dataStr) as Map<String, dynamic>;
            
            // 更新 Token（如果服务器返回新 Token）
            final newToken = dataMap['token'] as String?;
            if (newToken != null && newToken.isNotEmpty) {
              token.value = newToken;
              await StorageUtil().setString(AppConstants.keyToken, newToken);
            }
            
            // 更新用户信息（如果有）
            if (dataMap.containsKey('user')) {
              final userMap = dataMap['user'] as Map<String, dynamic>;
              final user = UserModel.fromJson(userMap);
              currentUser.value = user;
              await StorageUtil().setObject(AppConstants.keyUserInfo, user.toJson());
            }
          } catch (e) {
            print('⚠️ 解析登录数据失败: $e');
          }
        }
        
        isLoggedIn.value = true;
        return true;
      } else {
        // 登录失败
        print('❌ Token 自动登录失败: ${result['message']}');
        autoLoginStatus.value = '登录失败';
        
        // Token 无效，清除本地登录信息
        await logout();
        return false;
      }
    } catch (e) {
      print('❌ Token 自动登录异常: $e');
      autoLoginStatus.value = '登录异常';
      return false;
    } finally {
      isAutoLogging.value = false;
    }
  }
  
  /// 检查是否需要自动登录
  bool needAutoLogin() {
    final savedToken = StorageUtil().getString(AppConstants.keyToken);
    return savedToken != null && savedToken.isNotEmpty;
  }
}

