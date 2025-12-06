import 'package:flutter/services.dart';

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
    try {
      final result = await _methodChannel.invokeMethod<T>(method, arguments);
      return result;
    } on PlatformException catch (e) {
      print('调用原生方法失败: ${e.message}');
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
  }) async {
    return imLogin(
      loginType: 'password',
      accountId: accountId,
      password: password,
    );
  }
  
  /// 短信验证码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithSMS({
    required String phone,
    required String code,
    required String captchaId,
  }) async {
    return imLogin(
      loginType: 'sms_code',
      accountId: phone,  // 手机号也作为账户ID
      phone: phone,
      password: code,
      captchaId: captchaId,
    );
  }
  
  /// 邮箱验证码登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithEmail({
    required String email,
    required String code,
    required String captchaId,
  }) async {
    return imLogin(
      loginType: 'email_code',
      accountId: email,  // 邮箱也作为账户ID
      email: email,
      password: code,
      captchaId: captchaId,
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
}

