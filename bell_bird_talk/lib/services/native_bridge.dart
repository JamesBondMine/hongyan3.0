import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ======================== 日志工具 ========================

/// 原生调用日志工具
class NativeLogger {
  /// 是否启用日志（生产环境可关闭）
  static bool enabled = kDebugMode;
  
  /// 最大结果长度（超过则截断）
  static int maxResultLength = 800;
  
  /// 记录完整的 API 调用（一行输出）
  static void log(String method, dynamic params, dynamic result, Duration duration, {bool isError = false}) {
    if (!enabled) return;
    
    final icon = isError ? '❌' : '✅';
    final paramsStr = _toJson(params);
    final resultStr = _toJson(result);
    
    // 截断过长的结果
    final displayResult = resultStr.length > maxResultLength 
        ? '${resultStr.substring(0, maxResultLength)}...(${resultStr.length}字符)'
        : resultStr;
    
    // 使用 print 输出单行日志，更简洁
    print('\n===================================\n$icon ${duration.inMilliseconds}ms \n[$method]  \n$paramsStr \n----\n$displayResult \n===================================');
  }
  
  /// 转换为 JSON 字符串
  static String _toJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map) {
        return json.encode(data);
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }
}

/// Flutter 与 iOS 原生通信桥接类
class NativeBridge {
  // 单例模式
  static final NativeBridge _instance = NativeBridge._internal();
  factory NativeBridge() => _instance;
  NativeBridge._internal();

  // ======================== MethodChannel ========================
  // 用于方法调用（一次性请求/响应）
  static const MethodChannel _methodChannel = MethodChannel('com.bellbird.talk/method');

  /// 调用 iOS 原生方法
  /// 
  /// 示例:
  /// - 获取设备信息
  /// - 打开系统设置
  /// - 调用原生 SDK 功能
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await _methodChannel.invokeMethod<T>(method, arguments);
      stopwatch.stop();
      
      // 记录成功
      NativeLogger.log(method, arguments, result, stopwatch.elapsed);
      
      return result;
    } on PlatformException catch (e) {
      stopwatch.stop();
      // 记录失败
      NativeLogger.log(method, arguments, {'error': e.message}, stopwatch.elapsed, isError: true);
      rethrow;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log(method, arguments, {'error': e.toString()}, stopwatch.elapsed, isError: true);
      rethrow;
    }
  }

  // ======================== EventChannel ========================
  // 用于接收 iOS 持续发送的事件流
  static const EventChannel _eventChannel = EventChannel('com.bellbird.talk/event');
  
  /// 监听 iOS 原生事件流
  /// 
  /// 示例:
  /// - 位置更新
  /// - 聊天消息推送
  /// - 网络状态变化
  Stream<dynamic>? _eventStream;
  Stream<dynamic> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream();
    return _eventStream!;
  }

  // ======================== BasicMessageChannel ========================
  // 用于持续的双向消息传递
  static const BasicMessageChannel<dynamic> _messageChannel = 
      BasicMessageChannel('com.bellbird.talk/message', StandardMessageCodec());

  /// 发送消息到 iOS
  Future<dynamic> sendMessage(dynamic message) async {
    return await _messageChannel.send(message);
  }

  /// 设置消息接收回调
  void setMessageHandler(Future<dynamic> Function(dynamic message)? handler) {
    _messageChannel.setMessageHandler(handler);
  }
}

// ======================== 具体功能封装 ========================

/// iOS 原生功能调用封装
class IOSNativeService {
  final NativeBridge _bridge = NativeBridge();

  // ---------- 数据互通示例 ----------
  
  /// 获取 iOS 设备信息
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    final result = await _bridge.invokeMethod<Map>('getDeviceInfo');
    return result?.cast<String, dynamic>();
  }

  /// 保存数据到 iOS 原生（UserDefaults/Keychain）
  Future<bool?> saveToNative(String key, dynamic value) async {
    return await _bridge.invokeMethod<bool>('saveData', {
      'key': key,
      'value': value,
    });
  }

  /// 从 iOS 原生读取数据
  Future<dynamic> loadFromNative(String key) async {
    return await _bridge.invokeMethod('loadData', {'key': key});
  }

  // ---------- iOS SDK 调用示例 ----------
  
  /// 调用 iOS 原生通讯录
  Future<List<dynamic>?> getContacts() async {
    return await _bridge.invokeMethod<List>('getContacts');
  }

  /// 调用 iOS 相机
  Future<String?> openCamera() async {
    return await _bridge.invokeMethod<String>('openCamera');
  }

  /// 调用 iOS 通知推送
  Future<void> sendLocalNotification(String title, String body) async {
    await _bridge.invokeMethod('sendNotification', {
      'title': title,
      'body': body,
    });
  }

  // ---------- iOS 原生 UI 交互 ----------
  
  /// 打开 iOS 原生页面
  Future<void> openNativePage(String pageName, Map<String, dynamic>? params) async {
    await _bridge.invokeMethod('openNativePage', {
      'pageName': pageName,
      'params': params,
    });
  }

  /// 显示 iOS 原生弹窗
  Future<bool?> showNativeAlert(String title, String message) async {
    return await _bridge.invokeMethod<bool>('showAlert', {
      'title': title,
      'message': message,
    });
  }

  // ---------- 聊天相关示例 ----------
  
  /// 发送消息到 iOS 原生（可能用于处理加密等）
  Future<Map<String, dynamic>?> processMessage(String message) async {
    final result = await _bridge.invokeMethod<Map>('processMessage', {
      'message': message,
    });
    return result?.cast<String, dynamic>();
  }

  /// 同步聊天数据到 iOS 原生存储
  Future<bool?> syncChatData(List<Map<String, dynamic>> messages) async {
    return await _bridge.invokeMethod<bool>('syncChatData', {
      'messages': messages,
    });
  }
  
  // ---------- C++ 数据传输示例 ----------
  
  /// 从 C++ 生成模拟数据
  Future<Map<String, dynamic>?> generateCppData() async {
    final result = await _bridge.invokeMethod<Map>('generateCppData');
    return result?.cast<String, dynamic>();
  }
  
  /// 处理字符串（调用 C++ 加密方法）
  Future<String?> processCppString(String input) async {
    return await _bridge.invokeMethod<String>('processCppString', {
      'input': input,
    });
  }
  
  /// 计算统计数据（调用 C++ 计算方法）
  Future<Map<String, dynamic>?> calculateCppStatistics(List<int> numbers) async {
    final result = await _bridge.invokeMethod<Map>('calculateCppStatistics', {
      'numbers': numbers,
    });
    return result?.cast<String, dynamic>();
  }
  
  /// 模拟数据传输（从 C++ 获取复杂结构化数据）
  Future<Map<String, dynamic>?> simulateCppDataTransfer(int userId, int messageCount) async {
    final result = await _bridge.invokeMethod<Map>('simulateCppDataTransfer', {
      'userId': userId,
      'messageCount': messageCount,
    });
    return result?.cast<String, dynamic>();
  }
  
  // ---------- IM SDK ----------
  
  /// 初始化 IM SDK
  Future<bool> imInitialize() async {
    final result = await _bridge.invokeMethod<bool>('imInitialize');
    return result ?? false;
  }
  
  /// 启动 IM 网络服务
  Future<bool> imStart() async {
    final result = await _bridge.invokeMethod<bool>('imStart');
    return result ?? false;
  }
  
  /// 启动网络检查
  Future<bool> imStartNetCheck(String url) async {
    final result = await _bridge.invokeMethod<bool>('imStartNetCheck', {
      'url': url,
    });
    return result ?? false;
  }
  
  /// 设置 IP 地址表
  Future<bool> imSetIPTable(List<String> ips) async {
    final result = await _bridge.invokeMethod<bool>('imSetIPTable', {
      'ips': ips,
    });
    return result ?? false;
  }
  
  /// 获取 IP 延迟状态
  Future<List<int>> imGetIPStatus() async {
    final result = await _bridge.invokeMethod<List>('imGetIPStatus');
    return result?.cast<int>() ?? [];
  }
  
  /// 添加目标服务器
  Future<bool> imAddTarget(String ip, int port) async {
    final result = await _bridge.invokeMethod<bool>('imAddTarget', {
      'ip': ip,
      'port': port,
    });
    return result ?? false;
  }
  
  /// 停止 IM 网络服务
  Future<bool> imStop() async {
    final result = await _bridge.invokeMethod<bool>('imStop');
    return result ?? false;
  }
  
  // ---------- IM SDK 认证相关 ----------
  
  /// 用户注册
  /// @param registerData 注册数据
  ///   - register_type: 'account' 或 'phone'
  ///   - account_id: 账号（account 模式）
  ///   - phone: 手机号（phone 模式）
  ///   - captcha: 验证码（phone 模式）
  ///   - password: 密码
  ///   - biz_code: 邀请码（可选）
  /// @return 注册结果
  Future<Map<String, dynamic>> imRegister(Map<String, dynamic> registerData) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imRegister', registerData);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取验证码
  /// @param value 目标值：SMS时为手机号，EMAIL时为邮箱
  /// @param type 验证码类型：SMS（短信）、EMAIL（邮箱）
  /// @param scene 使用场景：login/register/createGroup等
  /// @return 验证码结果
  Future<Map<String, dynamic>> imGetCaptcha(String value, {
    String type = 'SMS',      // SMS=短信, EMAIL=邮箱
    String scene = 'register', // 使用场景
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetCaptcha', {
        'scene': scene,        // 使用场景：register/login 等
        'type': type,          // 验证码类型：SMS/EMAIL
        'value': value,        // 目标值：手机号或邮箱
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 用户登录（支持多种登录方式）
  /// @param loginType 登录类型：password（密码）、sms_code（短信）、email_code（邮箱）、token
  /// @param accountId 账户ID（密码登录必填）
  /// @param password 密码（密码登录）或验证码答案（验证码登录）
  /// @param phone 手机号（短信登录必填）
  /// @param email 邮箱（邮箱登录必填）
  /// @param captchaId 验证码ID（验证码登录必填）
  /// @param deviceId 设备ID（可选）
  /// @param bizCode 业务邀请码（可选）
  /// @return 登录结果
  Future<Map<String, dynamic>> imLogin({
    required String loginType,
    String? accountId,
    String? password,
    String? phone,
    String? email,
    String? captchaId,
    String? deviceId,
    String? bizCode,
    String? token,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'login_type': loginType,
      };
      
      // 根据登录类型添加必要参数
      if (accountId != null) params['account_id'] = accountId;
      if (password != null) params['password'] = password;
      if (phone != null) params['phone'] = phone;
      if (email != null) params['email'] = email;
      if (captchaId != null) params['captcha_id'] = captchaId;
      if (deviceId != null) params['device_id'] = deviceId;
      if (bizCode != null) params['biz_code'] = bizCode;
      if (token != null) params['token'] = token;
      
      final result = await _bridge.invokeMethod<Map>('imLogin', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 密码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithPassword({
    required String accountId,
    required String password,
    String? bizCode,
  }) async {
    return imLogin(
      loginType: 'password',
      accountId: accountId,
      password: password,
      bizCode: bizCode,
    );
  }
  
  /// 短信验证码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithSMS({
    required String phone,
    required String code,
    required String captchaId,
    String? bizCode,
  }) async {
    return imLogin(
      loginType: 'sms_code',
      accountId: phone,  // 手机号也作为账户ID
      phone: phone,
      password: code,
      captchaId: captchaId,
      bizCode: bizCode,
    );
  }
  
  /// 手机+密码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithPhonePassword({
    required String phone,
    required String password,
    String? bizCode,
  }) async {
    return imLogin(
      loginType: 'password',
      accountId: phone,  // 手机号作为账户ID
      phone: phone,
      password: password,
      bizCode: bizCode,
    );
  }
  
  /// 邮箱验证码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithEmail({
    required String email,
    required String code,
    required String captchaId,
    String? bizCode,
  }) async {
    return imLogin(
      loginType: 'email_code',
      accountId: email,  // 邮箱也作为账户ID
      email: email,
      password: code,
      captchaId: captchaId,
      bizCode: bizCode,
    );
  }
  
  /// 邮箱+密码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithEmailPassword({
    required String email,
    required String password,
    String? bizCode,
  }) async {
    return imLogin(
      loginType: 'password',
      accountId: email,  // 邮箱作为账户ID
      email: email,
      password: password,
      bizCode: bizCode,
    );
  }
  
  /// Token 登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithToken({
    required String token,
  }) async {
    return imLogin(
      loginType: 'token',
      token: token,
    );
  }
  
  /// 修改密码
  /// @param userId 用户ID
  /// @param oldPassword 旧密码
  /// @param newPassword 新密码
  /// @return 修改结果
  Future<Map<String, dynamic>> imChangePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'user_id': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
      };
      
      print('🔐 修改密码请求: userId=$userId');
      
      final result = await _bridge.invokeMethod<Map>('imChangePassword', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('修改密码错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 重置密码
  /// @param phone 手机号（和email二选一）
  /// @param email 邮箱（和phone二选一）
  /// @param code 验证码
  /// @param captchaId 验证码ID
  /// @param newPassword 新密码
  Future<Map<String, dynamic>> imResetPassword({
    String? phone,
    String? email,
    required String code,
    required String captchaId,
    required String newPassword,
  }) async {
    if (phone == null && email == null) {
      return {'errorCode': -1, 'message': '必须提供手机号或邮箱'};
    }
    
    try {
      final Map<String, dynamic> params = {
        'code': code,
        'captcha_id': captchaId,
        'new_password': newPassword,
      };
      
      if (phone != null) {
        params['phone'] = phone;
      }
      if (email != null) {
        params['email'] = email;
      }
      
      print('🔐 重置密码请求: $params');
      
      final result = await _bridge.invokeMethod<Map>('imResetPassword', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('重置密码错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 用户查询 ----------
  
  /// 搜索用户
  /// @param userId 用户ID（可选）
  /// @param accountId 账户ID，可以是手机号、邮箱等（可选）
  /// @return 搜索结果，包含用户信息
  Future<Map<String, dynamic>> imSearchUser({
    String? userId,
    String? accountId,
  }) async {
    if (userId == null && accountId == null) {
      return {'errorCode': -1, 'message': '必须提供 userId 或 accountId'};
    }
    
    try {
      final Map<String, dynamic> params = {};
      if (userId != null) params['user_id'] = userId;
      if (accountId != null) params['account_id'] = accountId;
      
      final result = await _bridge.invokeMethod<Map>('imSearchUser', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 用户信息管理 ----------
  
  /// 更新用户信息
  /// @param userId 用户ID（可选，默认使用当前登录用户）
  /// @param nickname 昵称
  /// @param sex 性别 (0=男, 1=女)
  /// @param signature 个性签名
  /// @param avatar 头像URL
  /// @param region 地区
  /// @param backgroundFile 背景图片URL
  /// @return 更新结果
  Future<Map<String, dynamic>> imUpdateUserInfo({
    String? userId,
    String? nickname,
    int? sex,
    String? signature,
    String? avatar,
    String? region,
    String? backgroundFile,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      
      if (userId != null) params['user_id'] = userId;
      if (nickname != null) params['nickname'] = nickname;
      if (sex != null) params['sex'] = sex;
      if (signature != null) params['signature'] = signature;
      if (avatar != null) params['avatar'] = avatar;
      if (region != null) params['region'] = region;
      if (backgroundFile != null) params['background_file'] = backgroundFile;
      
      print('📝 更新用户信息: $params');
      
      final result = await _bridge.invokeMethod<Map>('imUpdateUserInfo', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('更新用户信息错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 更新昵称（便捷方法）
  Future<Map<String, dynamic>> imUpdateNickname(String nickname) async {
    return imUpdateUserInfo(nickname: nickname);
  }
  
  /// 更新签名（便捷方法）
  Future<Map<String, dynamic>> imUpdateSignature(String signature) async {
    return imUpdateUserInfo(signature: signature);
  }
  
  /// 更新性别（便捷方法）
  Future<Map<String, dynamic>> imUpdateSex(int sex) async {
    return imUpdateUserInfo(sex: sex);
  }
  
  /// 更新头像（便捷方法）
  Future<Map<String, dynamic>> imUpdateAvatar(String avatarUrl) async {
    return imUpdateUserInfo(avatar: avatarUrl);
  }
  
  /// 退出登录
  /// 可选传入 userId/clientIp/reason，调用 SDK 退出登录接口
  Future<Map<String, dynamic>> imLogout({
    String? userId,
    String? clientIp,
    int? reason,
  }) async {
    try {
      print('🚪 开始退出登录...');
      
      final Map<String, dynamic> params = {};
      if (userId != null && userId.isNotEmpty) params['user_id'] = userId;
      if (clientIp != null && clientIp.isNotEmpty) params['client_ip'] = clientIp;
      if (reason != null) params['reason'] = reason;
      
      final result = await _bridge.invokeMethod<Map>('imLogout', params.isEmpty ? null : params);
      print('🚪 退出登录结果: $result');
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('❌ 退出登录错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 注销当前用户
  /// 调用底层 delete_user 接口，删除当前登录账号
  Future<Map<String, dynamic>> imDeleteUser() async {
    try {
      final result = await _bridge.invokeMethod<Map>('imDeleteUser');
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 联系人管理 ----------
  
  /// 添加联系人（发送好友申请）
  /// @param targetUserId 目标用户ID（必填）
  /// @param channel 添加渠道：0=用户ID, 1=用户名, 2=手机号, 3=邮箱, 4=邀请码, 5=二维码
  /// @param message 验证消息（可选）
  /// @param targetValue 目标值（用户ID/手机号/邮箱等）
  /// @return 添加结果
  Future<Map<String, dynamic>> imAddContact({
    required String targetUserId,
    int channel = 0,
    String? message,
    String? targetValue,
    String? targetPhone,
    String? targetEmail,
    int? groupId,  // 分组ID（可选）
  }) async {
    try {
      final Map<String, dynamic> params = {
        'target_user_id': targetUserId,
        'target_value': targetPhone ?? targetEmail,
        'channel': channel,
      };
      
      if (groupId != null && groupId > 0) {
        params['group_id'] = groupId;
      }
      
      if (message != null && message.isNotEmpty) {
        params['message'] = message;
      }
      if (targetPhone != null && targetPhone.isNotEmpty) {
        params['target_phone'] = targetPhone;
      }
      if (targetEmail != null && targetEmail.isNotEmpty) {
        params['target_email'] = targetEmail;
      }
      
      final result = await _bridge.invokeMethod<Map>('imAddContact', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 删除联系人
  /// @param userId 要删除的好友用户ID
  /// @return 删除结果
  Future<Map<String, dynamic>> imDeleteContact({
    required String contact_user_id,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imDeleteContact', {
        'contact_user_id': contact_user_id,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 拉黑用户
  /// @param userId 要拉黑的用户ID
  /// @return 拉黑结果
  Future<Map<String, dynamic>> imBlockContact({
    required String userId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imBlockContact', {
        'user_id': userId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 取消拉黑
  /// @param userId 要取消拉黑的用户ID
  /// @return 取消拉黑结果
  Future<Map<String, dynamic>> imUnblockContact({
    required String userId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imUnblockContact', {
        'user_id': userId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取黑名单状态
  /// @param userId 用户ID
  /// @return 返回结果，data 字段包含黑名单状态（JSON 格式，包含 block_direction, is_blocked 等字段）
  Future<Map<String, dynamic>> imGetBlackStatus({
    required String userId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetBlackStatus', {
        'user_id': userId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取联系人列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 联系人列表
  /// 获取联系人列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @param relationship 关系类型：0=好友, 1=关注, 2=黑名单, 3=待确认, -1=全部
  /// @param groupId 分组ID（可选，null表示不按分组过滤）
  /// @param keyword 搜索关键词（可选，null或空字符串表示不搜索）
  Future<Map<String, dynamic>> imGetContactList({
    int page = 1,
    int pageSize = 20,
    int relationship = -1,  // 默认获取全部
    int? groupId,  // 分组ID（可选，null表示不按分组过滤）
    String? keyword,  // 搜索关键词（可选）
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'page_size': pageSize,
        'relationship': relationship,
      };
      if (groupId != null && groupId > 0) {
        params['group_id'] = groupId;
      }
      if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = keyword;
      }
      
      final result = await _bridge.invokeMethod<Map>('imGetContactList', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 好友申请管理 ----------
  
  /// 获取好友申请列表
  /// @param status 申请状态过滤（0=待处理, 1=已同意, 2=已拒绝, -1=全部）
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 好友申请列表
  Future<Map<String, dynamic>> imGetFriendRequests({
    int status = 0,  // 默认获取待处理的
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetFriendRequests', {
        'status': status,
        'page': page,
        'page_size': pageSize,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 同意好友申请
  /// @param requestId 申请ID
  /// @return 操作结果
  Future<Map<String, dynamic>> imAcceptFriendRequest({
    required int requestId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imAcceptFriendRequest', {
        'request_id': requestId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 拒绝好友申请
  /// @param requestId 申请ID
  /// @param reason 拒绝原因（可选）
  /// @return 操作结果
  Future<Map<String, dynamic>> imRejectFriendRequest({
    required int requestId,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'request_id': requestId,
      };
      if (reason != null && reason.isNotEmpty) {
        params['reason'] = reason;
      }
      final result = await _bridge.invokeMethod<Map>('imRejectFriendRequest', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 联系人分组 ----------

  /// 搜索联系人
  /// @param keyword 搜索关键词（昵称、备注、ID 等）
  /// @return 搜索结果列表
  Future<Map<String, dynamic>> imSearchContact({
    required String keyword,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSearchContact', {
        'keyword': keyword,
      });
      return result?.cast<String, dynamic>() ??
          {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取联系人分组列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 分组列表
  Future<Map<String, dynamic>> imGetContactGroups({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetContactGroups', {
        'page': page,
        'page_size': pageSize,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 创建联系人分组
  /// @param groupName 分组名称（必填）
  /// @param groupColor 分组颜色（可选）
  /// @param groupOrder 排序权重（可选）
  /// @param groupIcon 分组图标（可选）
  /// @param groupDescription 分组描述（可选）
  /// @return 创建结果
  Future<Map<String, dynamic>> imCreateContactGroup({
    required String groupName,
    String? groupColor,
    int? groupOrder,
    String? groupIcon,
    String? groupDescription,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_name': groupName,
      };
      if (groupColor != null) params['group_color'] = groupColor;
      if (groupOrder != null) params['group_order'] = groupOrder;
      if (groupIcon != null) params['group_icon'] = groupIcon;
      if (groupDescription != null) params['group_description'] = groupDescription;
      
      final result = await _bridge.invokeMethod<Map>('imCreateContactGroup', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('创建联系人分组错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 更新联系人分组
  Future<Map<String, dynamic>> imUpdateContactGroup({
    required int groupId,
    String? groupName,
    String? groupColor,
    int? groupOrder,
    String? groupIcon,
    String? groupDescription,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_id': groupId,
      };
      if (groupName != null) params['group_name'] = groupName;
      if (groupColor != null) params['group_color'] = groupColor;
      if (groupOrder != null) params['group_order'] = groupOrder;
      if (groupIcon != null) params['group_icon'] = groupIcon;
      if (groupDescription != null) params['group_description'] = groupDescription;
      
      final result = await _bridge.invokeMethod<Map>('imUpdateContactGroup', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('更新联系人分组错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 删除联系人分组
  Future<Map<String, dynamic>> imDeleteContactGroup({
    required int groupId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imDeleteContactGroup', {
        'group_id': groupId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('删除联系人分组错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 群组 ----------
  /// 获取群组列表
  Future<Map<String, dynamic>> imGetGroupList({
    // int groupType = -1,
    // int status = -1,
    // String? keyword,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetGroupList', {
        // 'group_type': groupType,
        // 'status': status,
        // 'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('获取群组列表错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取群成员列表
  Future<Map<String, dynamic>> imGetGroupMembers({
    required String groupId,
    int status = 0,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetGroupMembers', {
        'group_id': groupId,
        'status': status,
        'page': page,
        'page_size': pageSize,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('获取群成员列表错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 更新群信息（名称 / 头像 / 公告 / 描述）
  Future<Map<String, dynamic>> imUpdateGroup({
    required String groupId,
    String? groupName,
    String? groupAvatar,
    String? groupAnnouncement,
    String? groupDescription,
    int version = 1,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_id': groupId,
        'version': version,
      };
      if (groupName != null) params['group_name'] = groupName;
      if (groupAvatar != null) params['group_avatar'] = groupAvatar;
      if (groupAnnouncement != null) params['group_announcement'] = groupAnnouncement;
      if (groupDescription != null) params['group_description'] = groupDescription;
      
      final result = await _bridge.invokeMethod<Map>('imUpdateGroup', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('更新群信息错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 设置群内昵称
  Future<Map<String, dynamic>> imSetGroupAlias({
    required String groupId,
    required String alias,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSetGroupAlias', {
        'group_id': groupId,
        'alias': alias,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('设置群昵称错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取群信息
  Future<Map<String, dynamic>> imGetGroupInfo({
    required String groupId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetGroupInfo', {
        'group_id': groupId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('获取群信息错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取用户信息
  /// @param userIds 用户ID数组
  /// @return 返回结果，data 字段包含用户信息数组（JSON 字符串）
  Future<Map<String, dynamic>> imGetUsersInfo({
    required List<String> userIds,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetUsersInfo', {
        'user_ids': userIds,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('获取用户信息错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 解散群组
  /// @param groupId 群组ID（必填）
  /// @param reason 解散原因（可选）
  /// @return 操作结果
  Future<Map<String, dynamic>> imDissolveGroup({
    required String groupId,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_id': groupId,
      };
      if (reason != null && reason.isNotEmpty) {
        params['reason'] = reason;
      }
      final result = await _bridge.invokeMethod<Map>('imDissolveGroup', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('解散群组错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 退出群组
  /// @param groupId 群组ID（必填）
  /// @param reason 退出原因（可选）
  /// @return 操作结果
  Future<Map<String, dynamic>> imLeaveGroup({
    required String groupId,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_id': groupId,
      };
      if (reason != null && reason.isNotEmpty) {
        params['reason'] = reason;
      }
      final result = await _bridge.invokeMethod<Map>('imLeaveGroup', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('退出群组错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 添加群组成员
  /// @param groupId 群组ID（必填）
  /// @param userIds 用户ID列表（必填）
  /// @param reason 邀请理由（可选）
  /// @return 操作结果
  Future<Map<String, dynamic>> imAddGroupMembers({
    required String groupId,
    required List<String> userIds,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'group_id': groupId,
        'user_ids': userIds,
      };
      if (reason != null && reason.isNotEmpty) {
        params['reason'] = reason;
      }
      final result = await _bridge.invokeMethod<Map>('imAddGroupMembers', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('添加群成员错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 设置联系人备注
  /// @param userId 联系人用户ID
  /// @param remark 备注名称
  /// @return 操作结果
  Future<Map<String, dynamic>> imSetContactRemark({
    required String userId,
    required String remark,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSetContactRemark', {
        'user_id': userId,
        'remark': remark,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 移动联系人到分组
  /// @param contactUserId 联系人用户ID
  /// @param groupId 目标分组ID（0表示移除分组）
  /// @return 操作结果
  Future<Map<String, dynamic>> imMoveContactToGroup({
    required String contactUserId,
    required int groupId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imMoveContactToGroup', {
        'contact_user_id': contactUserId,
        'group_id': groupId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送群聊文本消息
  /// @param content 文本内容
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendGroupTextMessage({
    required String content,
    required String conversationId,
    required String groupId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSendGroupTextMessage', {
        'content': content,
        'conversation_id': conversationId,
        'group_id': groupId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送群聊图片消息
  /// @param imageUrl 图片URL
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @param thumbnailUrl 缩略图URL（可选）
  /// @param width 图片宽度（可选）
  /// @param height 图片高度（可选）
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendGroupImageMessage({
    required String imageUrl,
    required String conversationId,
    required String groupId,
    String? thumbnailUrl,
    int? width,
    int? height,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'image_url': imageUrl,
        'conversation_id': conversationId,
        'group_id': groupId,
      };
      if (thumbnailUrl != null) params['thumbnail_url'] = thumbnailUrl;
      if (width != null) params['width'] = width;
      if (height != null) params['height'] = height;
      
      final result = await _bridge.invokeMethod<Map>('imSendGroupImageMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送群聊语音消息
  /// @param audioUrl 语音文件URL
  /// @param duration 语音时长（秒）
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendGroupVoiceMessage({
    required String audioUrl,
    required int duration,
    required String conversationId,
    required String groupId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSendGroupVoiceMessage', {
        'audio_url': audioUrl,
        'duration': duration,
        'conversation_id': conversationId,
        'group_id': groupId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送群聊视频消息
  /// @param videoUrl 视频文件URL
  /// @param coverUrl 封面图URL（可选）
  /// @param duration 视频时长（秒）
  /// @param width 视频宽度（可选）
  /// @param height 视频高度（可选）
  /// @param size 视频文件大小（字节，可选）
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendGroupVideoMessage({
    required String videoUrl,
    String? coverUrl,
    int? duration,
    int? width,
    int? height,
    int? size,
    required String conversationId,
    required String groupId,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'video_url': videoUrl,
        'conversation_id': conversationId,
        'group_id': groupId,
      };
      if (coverUrl != null) params['cover_url'] = coverUrl;
      if (duration != null) params['duration'] = duration;
      if (width != null) params['width'] = width;
      if (height != null) params['height'] = height;
      if (size != null) params['size'] = size;
      
      final result = await _bridge.invokeMethod<Map>('imSendGroupVideoMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送群聊@消息
  /// @param content 消息内容
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @param atInfoList @成员信息列表，格式：[{'user_id': 'xxx', 'nickname': 'xxx'}]
  /// @param isAll 是否@所有人
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendGroupAtMessage({
    required String content,
    required String conversationId,
    required String groupId,
    required List<Map<String, dynamic>> atInfoList,
    bool isAll = false,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imSendGroupAtMessage', {
        'content': content,
        'conversation_id': conversationId,
        'group_id': groupId,
        'at_info_list': atInfoList,
        'is_all': isAll,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 拉取群聊历史消息
  /// @param conversationId 会话ID
  /// @param groupId 群组ID
  /// @param lastSeq 最后消息序号（0表示从最新开始拉取）
  /// @param limit 拉取数量限制
  /// @return 拉取结果
  Future<Map<String, dynamic>> imPullGroupMessages({
    required String conversationId,
    required String groupId,
    int lastSeq = 0,
    int limit = 50,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imPullGroupMessages', {
        'conversation_id': conversationId,
        'group_id': groupId,
        'last_seq': lastSeq,
        'limit': limit,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 会话管理 ----------
  
  /// 获取会话列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @param convType 会话类型过滤（可选，-1表示不过滤）
  /// @return 会话列表
  Future<Map<String, dynamic>> imGetConversationList({
    int page = 1,
    int pageSize = 20,
    int convType = 0,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetConversationList', {
        'page': page,
        'page_size': pageSize,
        'conv_type': convType,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取单个会话
  /// @param convId 会话ID
  /// @return 会话详情
  Future<Map<String, dynamic>> imGetConversation({
    required String convId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetConversation', {
        'conv_id': convId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 获取未读会话列表
  /// @return 未读会话列表
  Future<Map<String, dynamic>> imGetUnreadConversations({
    int page = 1,
    int pageSize = 20,
    int convType = -1,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetUnreadConversations', {
        'page': page,
        'page_size': pageSize,
        'conv_type': convType,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('获取未读会话列表错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 更新会话信息
  /// @param convId 会话ID（必填）
  /// @param displayName 显示名称（可选）
  /// @param avatarUrl 头像URL（可选）
  /// @param description 描述（可选）
  /// @return 更新结果
  Future<Map<String, dynamic>> imUpdateConversation({
    required String convId,
    String? displayName,
    String? avatarUrl,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'conv_id': convId,
      };
      if (displayName != null) params['display_name'] = displayName;
      if (avatarUrl != null) params['avatar_url'] = avatarUrl;
      if (description != null) params['description'] = description;
      
      final result = await _bridge.invokeMethod<Map>('imUpdateConversation', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('更新会话错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 通知 ----------

  /// 获取通知未读数量
  Future<Map<String, dynamic>> imGetNotificationUnreadCount({
    List<String>? types,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetNotificationUnreadCount', {
        if (types != null) 'types': types,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 拉取通知列表
  Future<Map<String, dynamic>> imPullNotifications({
    List<String>? types,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imPullNotifications', {
        'page': page,
        'page_size': pageSize,
        if (types != null) 'types': types,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 标记通知已读
  Future<Map<String, dynamic>> imMarkNotificationRead({
    required List<int> notificationIds,
    int? readTime,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imMarkNotificationRead', {
        'notification_ids': notificationIds,
        if (readTime != null) 'read_time': readTime,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 创建会话
  /// @param convType 会话类型（0=单聊, 2=群聊）
  /// @param targetId 目标ID（单聊为对方用户ID，群聊为群ID）
  /// @param displayName 显示名称
  /// @return 创建结果
  Future<Map<String, dynamic>> imCreateConversation({
    required int convType,
    required String targetId,
    required String displayName,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'conv_type': convType,
        'target_id': targetId,
        'display_name': displayName,
      };
      if (avatarUrl != null) params['avatar_url'] = avatarUrl;
      
      final result = await _bridge.invokeMethod<Map>('imCreateConversation', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 删除会话
  /// @param convId 会话ID
  /// @return 删除结果
  Future<Map<String, dynamic>> imDeleteConversation({
    required String convId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imDeleteConversation', {
        'conv_id': convId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 标记会话已读
  /// @param convId 会话ID
  /// @return 标记结果
  Future<Map<String, dynamic>> imMarkConversationRead({
    required String convId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imMarkConversationRead', {
        'conv_id': convId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 清空会话消息
  /// @param convId 会话ID
  /// @return 清空结果
  Future<Map<String, dynamic>> imClearConversationMessages({
    required String convId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imClearConversationMessages', {
        'conv_id': convId,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ==================== 消息管理 ====================
  
  /// 发送文本消息
  /// @param content 文本内容
  /// @param conversationId 会话ID
  /// @param receiverId 接收者ID
  /// @param ext 扩展字段（可选）
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendTextMessage({
    required String content,
    required String conversationId,
    required String receiverId,
    String? ext,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'content': content,
        'conversation_id': conversationId,
        'receiver_id': receiverId,
      };
      if (ext != null) params['ext'] = ext;
      
      final result = await _bridge.invokeMethod<Map>('imSendTextMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送图片消息
  /// @param imageUrl 图片URL
  /// @param conversationId 会话ID
  /// @param receiverId 接收者ID
  /// @param thumbnailUrl 缩略图URL（可选）
  /// @param width 图片宽度（可选）
  /// @param height 图片高度（可选）
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendImageMessage({
    required String imageUrl,
    required String conversationId,
    required String receiverId,
    String? thumbnailUrl,
    int? width,
    int? height,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'image_url': imageUrl,
        'conversation_id': conversationId,
        'receiver_id': receiverId,
      };
      if (thumbnailUrl != null) params['thumbnail_url'] = thumbnailUrl;
      if (width != null) params['width'] = width;
      if (height != null) params['height'] = height;
      
      final result = await _bridge.invokeMethod<Map>('imSendImageMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 发送语音消息
  /// @param audioUrl 语音文件URL
  /// @param duration 语音时长（秒）
  /// @param conversationId 会话ID
  /// @param receiverId 接收者ID
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendVoiceMessage({
    required String audioUrl,
    required int duration,
    required String conversationId,
    required String receiverId,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'audio_url': audioUrl,
        'duration': duration,
        'conversation_id': conversationId,
        'receiver_id': receiverId,
      };
      
      final result = await _bridge.invokeMethod<Map>('imSendVoiceMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }

  /// 发送视频消息
  /// @param videoUrl 视频文件URL
  /// @param coverUrl 封面图URL（可选）
  /// @param duration 视频时长（秒，可选）
  /// @param width 视频宽度（可选）
  /// @param height 视频高度（可选）
  /// @param size 视频文件大小（字节，可选）
  /// @param conversationId 会话ID
  /// @param receiverId 接收者ID
  /// @return 发送结果
  Future<Map<String, dynamic>> imSendVideoMessage({
    required String videoUrl,
    required String conversationId,
    required String receiverId,
    String? coverUrl,
    int? duration,
    int? width,
    int? height,
    int? size,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'video_url': videoUrl,
        'conversation_id': conversationId,
        'receiver_id': receiverId,
      };
      if (coverUrl != null) params['cover_url'] = coverUrl;
      if (duration != null) params['duration'] = duration;
      if (width != null) params['width'] = width;
      if (height != null) params['height'] = height;
      if (size != null) params['size'] = size;

      final result = await _bridge.invokeMethod<Map>('imSendVideoMessage', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 拉取历史消息
  /// @param conversationId 会话ID
  /// @param convType 会话类型（0=单聊, 2=群聊）
  /// @param targetId 目标ID（单聊为对方用户ID）
  /// @param lastSeq 最后消息序号（0表示从最新开始）
  /// @param limit 拉取数量限制
  /// @return 消息列表
  Future<Map<String, dynamic>> imPullMessages({
    required String conversationId,
    int convType = 0,
    String targetId = '',
    int lastSeq = 0,
    int limit = 50,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imPullMessages', {
        'conversation_id': conversationId,
        'conv_type': convType,
        'target_id': targetId,
        'last_seq': lastSeq,
        'limit': limit,
      });
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  // ---------- 消息监听 ----------
  
  /// 消息接收回调
  Function(Map<String, dynamic> message)? onMessageReceived;
  
  /// 系统消息回调
  Function(Map<String, dynamic> message)? onSystemMessage;
  
  /// 命令消息回调
  Function(int eventType, Map<String, dynamic> message)? onCommandMessage;
  
  /// 注册消息回调（单聊、群聊、社区）
  /// 在进入首页时调用，注册后可接收被动推送的消息
  Future<Map<String, dynamic>> imRegisterMessageCallbacks() async {
    try {
      // 设置方法处理器来接收 Native 推送的消息
      _setupMethodCallHandler();
      
      final result = await _bridge.invokeMethod<Map>('imRegisterMessageCallbacks');
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 取消注册消息回调
  Future<Map<String, dynamic>> imUnregisterMessageCallbacks() async {
    try {
      final result = await _bridge.invokeMethod<Map>('imUnregisterMessageCallbacks');
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  bool _isMethodCallHandlerSetup = false;
  
  /// 设置方法调用处理器（接收 Native 推送的消息）
  void _setupMethodCallHandler() {
    if (_isMethodCallHandlerSetup) return;
    
    const channel = MethodChannel('com.bell_bird_talk/native_bridge');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onMessageReceived') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final message = data.cast<String, dynamic>();
          print('📨 Flutter 收到消息1: $message');
          onMessageReceived?.call(message);
        }
      } else if (call.method == 'onSystemMessage') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final message = data.cast<String, dynamic>();
          print('📨 Flutter 收到系统消息2: $message');
          onSystemMessage?.call(message);
        }
      } else if (call.method == 'onCommandMessage') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final message = data.cast<String, dynamic>();
          final eventType = message['event_type'] as int? ?? 0;
          print('📨 Flutter 收到命令消息3: eventType=$eventType, data=$message');
          onCommandMessage?.call(eventType, message);
        }
      }
      return null;
    });
    
    _isMethodCallHandlerSetup = true;
    print('✅ 消息监听器已设置');
  }
  
  // ---------- 文件管理 ----------
  
  /// 准备上传文件（获取上传凭证）
  /// @param businessModule 业务模块（必填，如: avatar, group_avatar, message等）
  /// @param fileName 文件名（必填）
  /// @param fileSize 文件大小（字节，可选）
  /// @param contentType 文件MIME类型（可选）
  /// @return 上传凭证信息，包含：
  ///   - provider_code: 提供商类型代码（ALIYUN/TENCENT/AWS/MINIO/HUAWEI）
  ///   - upload_url: 上传URL
  ///   - method: HTTP方法（POST/PUT）
  ///   - headers: HTTP头
  ///   - form_data: 表单字段
  ///   - file_path: 文件路径
  ///   - file_url: 文件访问URL
  ///   - expires_at: 过期时间戳
  ///   - expires_in: 有效期（秒）
  ///   - upload_mode: 上传模式（POST_OBJECT或STS_SDK）
  ///   - sts_access_key_id: STS临时访问密钥ID
  ///   - sts_access_key_secret: STS临时访问密钥Secret
  ///   - sts_security_token: STS安全令牌
  ///   - bucket_name: 存储桶名称
  ///   - region: 区域ID
  Future<Map<String, dynamic>> imPrepareUpload({
    required String businessModule,
    required String fileName,
    int? fileSize,
    String? contentType,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'business_module': businessModule,
        'file_name': fileName,
      };
      if (fileSize != null && fileSize > 0) params['file_size'] = fileSize;
      if (contentType != null) params['content_type'] = contentType;
      
      print('📤 准备上传: $params');
      
      final result = await _bridge.invokeMethod<Map>('imPrepareUpload', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('准备上传错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
  /// 使用腾讯云 STS 临时凭证上传文件
  /// @param localFilePath 本地文件路径
  /// @param objectKey 对象键/远程路径
  /// @param bucketName 存储桶名称
  /// @param region 区域
  /// @param secretId 临时 AccessKeyId
  /// @param secretKey 临时 SecretKey
  /// @param token 临时 Token
  /// @return 上传结果，包含 success, url, error
  Future<Map<String, dynamic>> imUploadWithTencentSTS({
    required String localFilePath,
    required String objectKey,
    required String bucketName,
    required String region,
    required String secretId,
    required String secretKey,
    required String token,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'local_file_path': localFilePath,
        'object_key': objectKey,
        'bucket_name': bucketName,
        'region': region,
        'secret_id': secretId,
        'secret_key': secretKey,
        'token': token,
      };
      
      print('📤 腾讯云 STS 上传: objectKey=$objectKey, bucket=$bucketName');
      
      final result = await _bridge.invokeMethod<Map>('imUploadWithTencentSTS', params);
      return result?.cast<String, dynamic>() ?? {'success': false, 'error': '未知错误'};
    } catch (e) {
      print('腾讯云上传错误: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // ======================== 群组操作 ========================
  
  /// 创建群聊
  /// @param groupName 群名称
  /// @param memberIds 群成员用户ID列表
  /// @param avatarUrl 群头像URL（可选）
  /// @return 创建结果，包含群组信息
  Future<Map<String, dynamic>> imCreateGroup({
    required String groupName,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final Map<String, dynamic> params = {
        'group_name': groupName,
        'member_ids': memberIds,
      };
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        params['avatar_url'] = avatarUrl;
      }
      
      final result = await _bridge.invokeMethod<Map>('imCreateGroup', params);
      final resultMap = result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
      
      stopwatch.stop();
      NativeLogger.log('imCreateGroup', params, resultMap, stopwatch.elapsed);
      
      return resultMap;
    } catch (e) {
      stopwatch.stop();
      NativeLogger.log('imCreateGroup', {'groupName': groupName, 'memberIds': memberIds}, e.toString(), stopwatch.elapsed, isError: true);
      return {'errorCode': -999, 'message': e.toString()};
    }
  }


  /// 注销用户
  /// @param userId 用户ID（必填）
  /// @param reason 注销原因（可选）
  /// @return 注销结果
  Future<Map<String, dynamic>> imDeactivateAccount({
    required String userId,
    String? reason,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'user_id': userId,
      };
      
      if (reason != null && reason.isNotEmpty) {
        params['reason'] = reason;
      }
      
      print('🗑️ 注销用户: reason=${reason ?? "无"}');
      
      final result = await _bridge.invokeMethod<Map>('imDeactivateAccount', params);
      return result?.cast<String, dynamic>() ?? {'errorCode': -1, 'message': '未知错误'};
    } catch (e) {
      print('注销用户错误: $e');
      return {'errorCode': -999, 'message': e.toString()};
    }
  }
  
}

