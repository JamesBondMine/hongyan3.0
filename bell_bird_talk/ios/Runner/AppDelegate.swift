import Flutter
import UIKit
import Contacts
import UserNotifications
import AVFoundation

// IMSDK
import netinet_in

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private var nativeBridgeHandler: NativeBridgeHandler?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    DispatchQueue.main.async {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // 设置 Flutter 与原生通信
    setupNativeBridge()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupNativeBridge() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("⚠️ 无法获取 FlutterViewController")
      return
    }
    
    // 1. 设置 MethodChannel, EventChannel, BasicMessageChannel
    nativeBridgeHandler = NativeBridgeHandler()
    nativeBridgeHandler?.setup(with: controller)
    
    // 2. 注册 Platform Views（原生 UI 嵌入）
    // 如果你的项目中有自定义的 Platform View，请取消注释并实现对应的 Factory
    // let registrar = self.registrar(forPlugin: "NativeUIView")!
    // 
    // let nativeUIViewFactory = NativeUIViewFactory(messenger: registrar.messenger())
    // registrar.register(nativeUIViewFactory, withId: "native-ui-view")
    // 
    // let nativeMapViewFactory = NativeMapViewFactory(messenger: registrar.messenger())
    // registrar.register(nativeMapViewFactory, withId: "native-map-view")
    
    print("✅ AppDelegate Native Bridge 已初始化")
    print("✅ AppDelegate Platform Views 已注册")
  }
}

// MARK: - Native Bridge Handler

/// iOS 原生与 Flutter 通信处理类
class NativeBridgeHandler: NSObject {
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var messageChannel: FlutterBasicMessageChannel?
    private var eventSink: FlutterEventSink?
    private weak var binaryMessenger: FlutterBinaryMessenger?
    
    // API 处理器 - 负责所有方法调用的路由和处理
    private var apiHandler: FlutterAPIHandler?
    
    // MARK: - 初始化
    
    func setup(with controller: FlutterViewController) {
        // 保存 binaryMessenger 引用
        binaryMessenger = controller.binaryMessenger
        
        // 初始化 API 处理器（需要 binaryMessenger）
        apiHandler = FlutterAPIHandler(binaryMessenger: controller.binaryMessenger)
        
        // 1. MethodChannel - 方法调用
        methodChannel = FlutterMethodChannel(
            name: "com.bellbird.talk/method",
            binaryMessenger: controller.binaryMessenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)
        
        // 2. 消息回调通道 - 用于推送消息到 Flutter
        let nativeBridgeChannel = FlutterMethodChannel(
            name: "com.bell_bird_talk/native_bridge",
            binaryMessenger: controller.binaryMessenger
        )
        // 这个通道主要用于从 iOS 推送消息到 Flutter，不需要设置 handler
        
        // 3. EventChannel - 事件流
        eventChannel = FlutterEventChannel(
            name: "com.bellbird.talk/event",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel?.setStreamHandler(self)
        
        // 4. BasicMessageChannel - 消息传递
        messageChannel = FlutterBasicMessageChannel(
            name: "com.bellbird.talk/message",
            binaryMessenger: controller.binaryMessenger,
            codec: FlutterStandardMessageCodec.sharedInstance()
        )
        messageChannel?.setMessageHandler(handleMessage)
        
        print("✅ NativeBridgeHandler 初始化完成")
    }
    
    // MARK: - MethodChannel 处理
    
    /// 处理 Flutter 方法调用 - 委托给 FlutterAPIHandler
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        apiHandler?.handleMethodCall(call, result: result)
    }
    
    // MARK: - BasicMessageChannel 处理
    
    private func handleMessage(_ message: Any?, reply: @escaping FlutterReply) {
        guard let message = message as? [String: Any] else {
            reply(FlutterError(code: "INVALID_MESSAGE", message: "消息格式错误", details: nil))
            return
        }
        
        print("📨 收到 BasicMessage: \(message)")
        
        // 处理消息并回复
        let response: [String: Any] = [
            "status": "received",
            "timestamp": Date().timeIntervalSince1970,
            "echo": message
        ]
        
        reply(response)
    }
}

// MARK: - FlutterStreamHandler

extension NativeBridgeHandler: FlutterStreamHandler {
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        print("📡 EventChannel 开始监听")
        
        // 示例：定时发送事件
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.eventSink?([
                "type": "heartbeat",
                "timestamp": Date().timeIntervalSince1970
            ])
        }
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        print("📡 EventChannel 停止监听")
        return nil
    }
}
