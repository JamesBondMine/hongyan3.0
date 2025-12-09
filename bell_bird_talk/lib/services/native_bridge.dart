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
  
  /// Token 登录（便捷方法）
  Future<Map<String, dynamic>> imLoginWithToken({
    required String token,
  }) async {
    return imLogin(
      loginType: 'token',
      token: token,
    );
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
        params['reset_type'] = 'sms';
      }
      if (email != null) {
        params['email'] = email;
        params['reset_type'] = 'email';
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
  }) async {
    try {
      final Map<String, dynamic> params = {
        'target_user_id': targetUserId,
        'target_value': targetPhone ?? targetEmail,
        'channel': channel,
      };
      
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
    required String userId,
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imDeleteContact', {
        'user_id': userId,
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
  
  /// 获取联系人列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @return 联系人列表
  /// 获取联系人列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @param relationship 关系类型：0=好友, 1=关注, 2=黑名单, 3=待确认, -1=全部
  Future<Map<String, dynamic>> imGetContactList({
    int page = 1,
    int pageSize = 20,
    int relationship = -1,  // 默认获取全部
  }) async {
    try {
      final result = await _bridge.invokeMethod<Map>('imGetContactList', {
        'page': page,
        'page_size': pageSize,
        'relationship': relationship,
      });
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
  
  // ---------- 会话管理 ----------
  
  /// 获取会话列表
  /// @param page 页码（从1开始）
  /// @param pageSize 每页数量
  /// @param convType 会话类型过滤（可选，-1表示不过滤）
  /// @return 会话列表
  Future<Map<String, dynamic>> imGetConversationList({
    int page = 1,
    int pageSize = 20,
    int convType = -1,
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
}

