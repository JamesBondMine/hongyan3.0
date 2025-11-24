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
}

