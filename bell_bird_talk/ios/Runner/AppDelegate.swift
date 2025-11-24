import Flutter
import UIKit
import Contacts
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private var nativeBridgeHandler: NativeBridgeHandler?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
    let registrar = self.registrar(forPlugin: "NativeUIView")!
    
    let nativeUIViewFactory = NativeUIViewFactory(messenger: registrar.messenger())
    registrar.register(nativeUIViewFactory, withId: "native-ui-view")
    
    let nativeMapViewFactory = NativeMapViewFactory(messenger: registrar.messenger())
    registrar.register(nativeMapViewFactory, withId: "native-map-view")
    
    print("✅ Native Bridge 已初始化")
    print("✅ Platform Views 已注册")
  }
}

// MARK: - Native Bridge Handler

/// iOS 原生与 Flutter 通信处理类
class NativeBridgeHandler: NSObject {
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var messageChannel: FlutterBasicMessageChannel?
    private var eventSink: FlutterEventSink?
    
    // MARK: - 初始化
    
    func setup(with controller: FlutterViewController) {
        // 1. MethodChannel - 方法调用
        methodChannel = FlutterMethodChannel(
            name: "com.bellbird.talk/method",
            binaryMessenger: controller.binaryMessenger
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)
        
        // 2. EventChannel - 事件流
        eventChannel = FlutterEventChannel(
            name: "com.bellbird.talk/event",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel?.setStreamHandler(self)
        
        // 3. BasicMessageChannel - 消息传递
        messageChannel = FlutterBasicMessageChannel(
            name: "com.bellbird.talk/message",
            binaryMessenger: controller.binaryMessenger,
            codec: FlutterStandardMessageCodec.sharedInstance()
        )
        messageChannel?.setMessageHandler(handleMessage)
    }
    
    // MARK: - MethodChannel 处理
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // ---------- 数据互通 ----------
        case "getDeviceInfo":
            getDeviceInfo(result: result)
            
        case "saveData":
            saveData(call: call, result: result)
            
        case "loadData":
            loadData(call: call, result: result)
            
        // ---------- iOS SDK 调用 ----------
        case "getContacts":
            getContacts(result: result)
            
        case "openCamera":
            openCamera(result: result)
            
        case "sendNotification":
            sendLocalNotification(call: call, result: result)
            
        // ---------- 原生 UI ----------
        case "openNativePage":
            openNativePage(call: call, result: result)
            
        case "showAlert":
            showNativeAlert(call: call, result: result)
            
        // ---------- 聊天功能 ----------
        case "processMessage":
            processMessage(call: call, result: result)
            
        case "syncChatData":
            syncChatData(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 数据互通实现
    
    /// 获取设备信息
    private func getDeviceInfo(result: @escaping FlutterResult) {
        let device = UIDevice.current
        let deviceInfo: [String: Any] = [
            "deviceName": device.name,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "model": device.model,
            "identifier": device.identifierForVendor?.uuidString ?? ""
        ]
        result(deviceInfo)
    }
    
    /// 保存数据到 UserDefaults
    private func saveData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
        result(true)
    }
    
    /// 从 UserDefaults 读取数据
    private func loadData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let value = UserDefaults.standard.object(forKey: key)
        result(value)
    }
    
    // MARK: - iOS SDK 调用实现
    
    /// 获取通讯录
    private func getContacts(result: @escaping FlutterResult) {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                
                var contacts: [[String: Any]] = []
                
                do {
                    try store.enumerateContacts(with: request) { contact, _ in
                        let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
                        contacts.append([
                            "givenName": contact.givenName,
                            "familyName": contact.familyName,
                            "phoneNumbers": phoneNumbers
                        ])
                    }
                    
                    DispatchQueue.main.async {
                        result(contacts)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CONTACTS_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PERMISSION_DENIED", message: "通讯录权限被拒绝", details: nil))
                }
            }
        }
    }
    
    /// 打开相机（简化示例）
    private func openCamera(result: @escaping FlutterResult) {
        // 这里应该打开相机并返回图片路径
        // 实际实现需要使用 UIImagePickerController
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "相机功能需要完整实现", details: nil))
    }
    
    /// 发送本地通知
    private func sendLocalNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                center.add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
                        } else {
                            result(true)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PERMISSION_DENIED", message: "通知权限被拒绝", details: nil))
                }
            }
        }
    }
    
    // MARK: - 原生 UI 实现
    
    /// 打开原生页面
    private func openNativePage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let pageName = args["pageName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let params = args["params"] as? [String: Any]
        
        DispatchQueue.main.async {
            // 根据 pageName 打开对应的原生页面
            // 这里需要根据实际业务创建对应的 ViewController
            switch pageName {
            case "settings":
                // 打开设置页面
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                result(true)
            default:
                result(FlutterError(code: "PAGE_NOT_FOUND", message: "页面不存在: \(pageName)", details: nil))
            }
        }
    }
    
    /// 显示原生弹窗
    private func showNativeAlert(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                result(FlutterError(code: "NO_CONTROLLER", message: "找不到根控制器", details: nil))
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                result(true)
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
                result(false)
            })
            
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - 聊天功能实现
    
    /// 处理消息（例如加密）
    private func processMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        // 这里可以调用原生加密 SDK
        let processedMessage: [String: Any] = [
            "original": message,
            "encrypted": message.data(using: .utf8)?.base64EncodedString() ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        result(processedMessage)
    }
    
    /// 同步聊天数据
    private func syncChatData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let messages = args["messages"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        // 保存到本地数据库或同步到服务器
        UserDefaults.standard.set(messages, forKey: "chat_messages")
        UserDefaults.standard.synchronize()
        
        result(true)
    }
    
    // MARK: - BasicMessageChannel 处理
    
    private func handleMessage(_ message: Any?, reply: FlutterReply) {
        // 处理来自 Flutter 的消息
        if let msg = message as? [String: Any] {
            print("收到 Flutter 消息: \(msg)")
            
            // 处理后回复
            reply(["status": "received", "data": msg])
        } else {
            reply(nil)
        }
    }
    
    // MARK: - 向 Flutter 发送事件
    
    /// 发送事件到 Flutter（例如新消息通知）
    func sendEventToFlutter(event: [String: Any]) {
        eventSink?(event)
    }
}

// MARK: - FlutterStreamHandler

extension NativeBridgeHandler: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // 开始监听需要推送的事件（例如位置更新、新消息等）
        // 这里可以设置定时器或监听系统通知
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - Platform Views

/// 原生 UI 视图工厂
class NativeUIViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeUIView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// 原生 UI 视图（可以是任何 iOS 原生控件）
class NativeUIView: NSObject, FlutterPlatformView {
    private var _view: UIView
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        
        // 创建原生 UI
        createNativeView(args: args)
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func createNativeView(args: Any?) {
        _view.backgroundColor = .systemBlue
        
        // 示例：添加一个原生按钮
        let button = UIButton(type: .system)
        button.setTitle("这是 iOS 原生按钮", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        _view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 250),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 示例：添加一个原生标签
        let label = UILabel()
        label.text = "原生 UIView 示例"
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        _view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -20)
        ])
    }
    
    @objc private func buttonTapped() {
        // 显示原生弹窗
        let alert = UIAlertController(
            title: "原生响应",
            message: "你点击了 iOS 原生按钮！",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        // 获取当前的 ViewController 并显示弹窗
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

/// 另一个示例：嵌入地图或其他原生 SDK 视图
class NativeMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeMapView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeMapView: NSObject, FlutterPlatformView {
    private var _view: UIView
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        
        // 这里可以创建 MapKit 地图或其他第三方地图 SDK
        _view.backgroundColor = .systemGreen
        
        let label = UILabel()
        label.text = "这里可以嵌入地图或其他原生 SDK"
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        _view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -20)
        ])
    }
    
    func view() -> UIView {
        return _view
    }
}
