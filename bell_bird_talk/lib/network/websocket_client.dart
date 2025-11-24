import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/constants.dart';

/// WebSocket 连接状态
enum WebSocketState {
  connecting, // 连接中
  connected, // 已连接
  disconnected, // 已断开
  reconnecting, // 重连中
  failed, // 连接失败
}

/// WebSocket 客户端封装
class WebSocketClient {
  static WebSocketClient? _instance;
  
  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectCount = 0;
  
  // 消息流控制器
  final _messageController = StreamController<dynamic>.broadcast();
  final _stateController = StreamController<WebSocketState>.broadcast();
  
  // 单例模式
  factory WebSocketClient() {
    _instance ??= WebSocketClient._internal();
    return _instance!;
  }
  
  WebSocketClient._internal();
  
  /// 当前状态
  WebSocketState get state => _state;
  
  /// 消息流
  Stream<dynamic> get messageStream => _messageController.stream;
  
  /// 状态流
  Stream<WebSocketState> get stateStream => _stateController.stream;
  
  /// 是否已连接
  bool get isConnected => _state == WebSocketState.connected;
  
  // ==================== 连接管理 ====================
  
  /// 连接 WebSocket
  Future<void> connect({String? url, Map<String, dynamic>? headers}) async {
    if (_state == WebSocketState.connected) {
      print('✅ WebSocket 已连接');
      return;
    }
    
    try {
      _updateState(WebSocketState.connecting);
      
      final wsUrl = url ?? AppConstants.wsUrl;
      print('🔌 正在连接 WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: headers != null ? [jsonEncode(headers)] : null,
      );
      
      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      
      _updateState(WebSocketState.connected);
      _reconnectCount = 0;
      
      // 启动心跳
      _startHeartbeat();
      
      print('✅ WebSocket 连接成功');
    } catch (e) {
      print('❌ WebSocket 连接失败: $e');
      _updateState(WebSocketState.failed);
      _scheduleReconnect();
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    print('🔌 断开 WebSocket 连接');
    
    _stopHeartbeat();
    _stopReconnect();
    
    await _channel?.sink.close(status.normalClosure);
    _channel = null;
    
    _updateState(WebSocketState.disconnected);
  }
  
  /// 重新连接
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }
  
  // ==================== 消息发送 ====================
  
  /// 发送消息
  void send(dynamic message) {
    if (!isConnected) {
      print('⚠️ WebSocket 未连接，无法发送消息');
      return;
    }
    
    try {
      String data;
      if (message is String) {
        data = message;
      } else {
        data = jsonEncode(message);
      }
      
      _channel?.sink.add(data);
      print('📤 发送消息: $data');
    } catch (e) {
      print('❌ 发送消息失败: $e');
    }
  }
  
  /// 发送心跳
  void sendHeartbeat() {
    send({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
  }
  
  // ==================== 事件处理 ====================
  
  /// 接收消息
  void _onMessage(dynamic message) {
    print('📥 收到消息: $message');
    
    try {
      dynamic data;
      if (message is String) {
        data = jsonDecode(message);
      } else {
        data = message;
      }
      
      _messageController.add(data);
      
      // 处理心跳响应
      if (data is Map && data['type'] == 'pong') {
        print('💓 心跳响应');
      }
    } catch (e) {
      print('❌ 消息解析失败: $e');
      _messageController.add(message);
    }
  }
  
  /// 错误处理
  void _onError(dynamic error) {
    print('❌ WebSocket 错误: $error');
    _updateState(WebSocketState.failed);
    _scheduleReconnect();
  }
  
  /// 连接关闭
  void _onDone() {
    print('🔌 WebSocket 连接已关闭');
    _updateState(WebSocketState.disconnected);
    _stopHeartbeat();
    
    // 自动重连
    if (_reconnectCount < AppConstants.wsMaxRetries) {
      _scheduleReconnect();
    }
  }
  
  // ==================== 心跳机制 ====================
  
  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => sendHeartbeat(),
    );
  }
  
  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  // ==================== 重连机制 ====================
  
  /// 安排重连
  void _scheduleReconnect() {
    if (_reconnectCount >= AppConstants.wsMaxRetries) {
      print('❌ 达到最大重连次数，停止重连');
      _updateState(WebSocketState.failed);
      return;
    }
    
    _stopReconnect();
    
    _reconnectCount++;
    _updateState(WebSocketState.reconnecting);
    
    final delay = Duration(milliseconds: AppConstants.wsReconnectDelay);
    print('🔄 将在 ${delay.inSeconds} 秒后重连 (第 $_reconnectCount 次)');
    
    _reconnectTimer = Timer(delay, () => connect());
  }
  
  /// 停止重连
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  // ==================== 状态管理 ====================
  
  /// 更新状态
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      print('📊 WebSocket 状态变更: $newState');
    }
  }
  
  // ==================== 资源释放 ====================
  
  /// 释放资源
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}

