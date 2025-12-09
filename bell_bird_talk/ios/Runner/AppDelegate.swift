import Flutter
import UIKit
import Contacts
import UserNotifications

// IMSDK
import netinet_in



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
    
    //C++通信
    private func imsdkManagerConfig() {
//        int ret = network_init();
//        if (ret != 0) {
//            // 初始化失败
//        }
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
            
        // ---------- C++ 数据传输 ----------
        case "generateCppData":
            generateCppData(result: result)
            
        case "processCppString":
            processCppString(call: call, result: result)
            
        case "calculateCppStatistics":
            calculateCppStatistics(call: call, result: result)
            
        case "simulateCppDataTransfer":
            simulateCppDataTransfer(call: call, result: result)
            
        // ---------- IM SDK ----------
        case "imInitialize":
            imInitialize(result: result)
            
        case "imStart":
            imStart(result: result)
            
        case "imStartNetCheck":
            imStartNetCheck(call: call, result: result)
            
        case "imSetIPTable":
            imSetIPTable(call: call, result: result)
            
        case "imGetIPStatus":
            imGetIPStatus(result: result)
            
        case "imAddTarget":
            imAddTarget(call: call, result: result)
            
        case "imStop":
            imStop(result: result)
            
        // ---------- IM SDK 认证 ----------
        case "imRegister":
            imRegister(call: call, result: result)
            
        case "imGetCaptcha":
            imGetCaptcha(call: call, result: result)
            
        case "imLogin":
            imLogin(call: call, result: result)
            
        case "imSearchUser":
            imSearchUser(call: call, result: result)
        
        // ---------- 联系人管理 ----------
        case "imAddContact":
            imAddContact(call: call, result: result)
        case "imDeleteContact":
            imDeleteContact(call: call, result: result)
        case "imBlockContact":
            imBlockContact(call: call, result: result)
        case "imUnblockContact":
            imUnblockContact(call: call, result: result)
        case "imGetContactList":
            imGetContactList(call: call, result: result)
        
        // ---------- 好友申请 ----------
        case "imGetFriendRequests":
            imGetFriendRequests(call: call, result: result)
        case "imAcceptFriendRequest":
            imAcceptFriendRequest(call: call, result: result)
        case "imRejectFriendRequest":
            imRejectFriendRequest(call: call, result: result)
        
        // ---------- 会话管理 ----------
        case "imGetConversationList":
            imGetConversationList(call: call, result: result)
        case "imGetConversation":
            imGetConversation(call: call, result: result)
        case "imCreateConversation":
            imCreateConversation(call: call, result: result)
        case "imDeleteConversation":
            imDeleteConversation(call: call, result: result)
        case "imMarkConversationRead":
            imMarkConversationRead(call: call, result: result)
        case "imClearConversationMessages":
            imClearConversationMessages(call: call, result: result)
        
        // ---------- 云存储 ----------
        case "initAliyunOSS", "initTencentCOS", "initAWSS3",
             "uploadToAliyun", "uploadToTencent", "uploadToAWS",
             "downloadFile":
            CloudStorageManager.shared.handleMethodCall(call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 沙盒信息
    
    /// 打印沙盒路径和文件夹信息
    private func printSandboxInfo() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📂 iOS 沙盒路径信息")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let fileManager = FileManager.default
        
        // 1. 沙盒根目录（Home Directory）
        let homeDir = NSHomeDirectory()
        print("\n🏠 沙盒根目录:")
        print("   \(homeDir)")
        
        // 2. Documents 目录（用户数据，会被 iCloud 备份）
        if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("\n📄 Documents 目录:")
            print("   \(documentsDir.path)")
            listDirectory(at: documentsDir.path, prefix: "   ")
        }
        
        // 3. Library 目录
        if let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            print("\n📚 Library 目录:")
            print("   \(libraryDir.path)")
            listDirectory(at: libraryDir.path, prefix: "   ")
        }
        
        // 4. Caches 目录（缓存，不会被备份）
        if let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            print("\n💾 Caches 目录:")
            print("   \(cachesDir.path)")
            listDirectory(at: cachesDir.path, prefix: "   ")
        }
        
        // 5. tmp 目录（临时文件）
        let tmpDir = NSTemporaryDirectory()
        print("\n🗑️ tmp 目录:")
        print("   \(tmpDir)")
        listDirectory(at: tmpDir, prefix: "   ")
        
        // 6. Application Support 目录
        if let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            print("\n⚙️ Application Support 目录:")
            print("   \(appSupportDir.path)")
            listDirectory(at: appSupportDir.path, prefix: "   ")
        }
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ 沙盒信息打印完成")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// 列出目录内容
    private func listDirectory(at path: String, prefix: String = "") {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            if contents.isEmpty {
                print("\(prefix)   (空目录)")
            } else {
                for item in contents.sorted() {
                    var isDir: ObjCBool = false
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                    
                    if isDir.boolValue {
                        print("\(prefix)   📁 \(item)/")
                    } else {
                        // 获取文件大小
                        if let attrs = try? fileManager.attributesOfItem(atPath: fullPath),
                           let size = attrs[.size] as? Int64 {
                            let sizeStr = formatFileSize(size)
                            print("\(prefix)   📄 \(item) (\(sizeStr))")
                        } else {
                            print("\(prefix)   📄 \(item)")
                        }
                    }
                }
            }
        } catch {
            print("\(prefix)   ❌ 无法读取: \(error.localizedDescription)")
        }
    }
    
    /// 格式化文件大小
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
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
    
    // MARK: - C++ 数据传输实现
    
    /// 从 C++ 生成模拟数据
    private func generateCppData(result: @escaping FlutterResult) {
        let jsonString = DataTransViewController.generateSimulationDataFromCPP()
        
        // 将 JSON 字符串转换为字典
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            result(json)
        } else {
            result(FlutterError(code: "PARSE_ERROR", message: "解析 C++ 数据失败", details: nil))
        }
    }
    
    /// 处理字符串（调用 C++ 加密）
    private func processCppString(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let input = args["input"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let processed = DataTransViewController.processString(withCPP: input)
        result(processed)
    }
    
    /// 计算统计数据（调用 C++ 计算）
    private func calculateCppStatistics(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let numbers = args["numbers"] as? [Int] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let numberObjects = numbers.map { NSNumber(value: $0) }
        let stats = DataTransViewController.calculateStatistics(withCPP: numberObjects)
        result(stats)
    }
    
    /// 模拟数据传输（调用 C++ 获取复杂数据）
    private func simulateCppDataTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? Int,
              let messageCount = args["messageCount"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let jsonString = DataTransViewController.simulateDataTransfer(withCPP: userId, messageCount: messageCount)
        
        // 将 JSON 字符串转换为字典
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            result(json)
        } else {
            result(FlutterError(code: "PARSE_ERROR", message: "解析 C++ 数据失败", details: nil))
        }
    }
    
    // MARK: - IM SDK 实现
    
    /// 初始化 IM SDK
    private func imInitialize(result: @escaping FlutterResult) {
        IMSDKManager.shared().initSDK(withConfig: "{\"platform\":\"iOS\"}")
        result(true)
    }
    
    /// 启动网络服务
    private func imStart(result: @escaping FlutterResult) {
        let code = IMSDKManager.shared().startNetwork()
        result(code == 0 ? true : false)
    }
    
    /// 启动网络检查
    private func imStartNetCheck(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let code = IMSDKManager.shared().startNetworkCheck(withURL: url)
        result(code == 0 ? true : false)
    }
    
    /// 设置 IP 地址表
    private func imSetIPTable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let ips = args["ips"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        IMSDKManager.shared().setIPTable(ips)
        result(true)
    }
    
    /// 获取 IP 延迟状态
    private func imGetIPStatus(result: @escaping FlutterResult) {
        let latencies = IMSDKManager.shared().getIPStatus()
        result(latencies)
    }
    
    /// 添加目标服务器
    private func imAddTarget(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let ip = args["ip"] as? String,
              let port = args["port"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        IMSDKManager.shared().addTargetToGroup(withIP: ip, port: Int32(port))
        result(true)
    }
    
    /// 停止网络服务
    private func imStop(result: @escaping FlutterResult) {
        IMSDKManager.shared().stopNetwork()
        result(true)
    }
    
    // MARK: - IM SDK 认证
    
    /// 用户注册
    private func imRegister(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📝 注册请求: \(args)")
        
        // 调用 IMSDKAuthManager 注册（使用 protobuf）
        let code = IMSDKAuthManager.shared().register(with: args) { errorCode, reqId, data in
            print("✅ 注册回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "注册成功",
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "注册失败",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "REGISTER_ERROR", 
                              message: "注册请求发送失败: \(code)", 
                              details: nil))
        }
    }
    
    /// 获取验证码（支持短信和邮箱）
    /// GetCaptcha protobuf: scene, type(CaptchaType), value
    private func imGetCaptcha(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误: 缺少 value", details: nil))
            return
        }
        
        // 获取参数
        let scene = args["scene"] as? String ?? "register"  // 使用场景
        let typeStr = args["type"] as? String ?? "SMS"      // SMS 或 EMAIL
        
        // CaptchaType 枚举值转换: IMAGE=0, SMS=1, EMAIL=2
        let captchaType: Int32
        switch typeStr.uppercased() {
        case "SMS":
            captchaType = 1
        case "EMAIL":
            captchaType = 2
        case "IMAGE":
            captchaType = 0
        default:
            captchaType = 1 // 默认短信
        }
        
        print("📱 获取验证码: scene=\(scene), type=\(typeStr)(\(captchaType)), value=\(value)")
        
        // 调用 IMSDKAuthManager 获取验证码（使用 Protobuf 序列化）
        let code = IMSDKAuthManager.shared().getCaptchaWithScene(
            scene,
            type: captchaType,
            value: value
        ) { errorCode, reqId, data in
            print("✅ 验证码回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            let message = typeStr.uppercased() == "EMAIL" ? "验证码已发送到邮箱" : "验证码已发送"
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": message,
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "获取验证码失败",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "CAPTCHA_ERROR", 
                              message: "验证码请求发送失败: \(code)", 
                              details: nil))
        }
    }
    
    /// 用户登录（支持多种登录方式）
    /// 参数说明：
    /// - login_type: 登录类型 (password/sms_code/email_code/token)
    /// - account_id: 账户ID（密码登录必填）
    /// - password: 密码（密码登录）或验证码答案（验证码登录）
    /// - phone: 手机号（短信登录必填）
    /// - email: 邮箱（邮箱登录必填）
    /// - captcha_id: 验证码ID（验证码登录必填）
    /// - device_id: 设备ID（可选）
    /// - biz_code: 业务邀请码（可选）
    private func imLogin(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        // 获取登录类型
        let loginType = args["login_type"] as? String ?? "password"
        print("🔐 用户登录: login_type=\(loginType)")
        
        // 构建登录字典
        var loginDict: [String: Any] = [:]
        
        // 登录类型
        loginDict["login_type"] = loginType
        
        // 根据登录类型设置必要字段
        switch loginType {
        case "password":
            // 密码登录：需要 account_id + password
            if let accountId = args["account_id"] as? String {
                loginDict["account_id"] = accountId
            }
            if let password = args["password"] as? String {
                loginDict["password"] = password
            }
            print("📋 密码登录: account_id=\(loginDict["account_id"] ?? "nil")")
            
        case "sms_code":
            // 短信验证码登录：需要 phone + password(验证码) + captcha_id
            if let phone = args["phone"] as? String {
                loginDict["phone"] = phone
            }
            if let password = args["password"] as? String {
                loginDict["password"] = password
            }
            if let captchaId = args["captcha_id"] as? String {
                loginDict["captcha_id"] = captchaId
            }
//            if let accountId = args["account_id"] as? String {
//                            loginDict["account_id"] = accountId
//                        }
            print("📋 短信登录: phone=\(loginDict["phone"] ?? "nil")")
            
        case "email_code":
            // 邮箱验证码登录：需要 email + password(验证码) + captcha_id
            if let email = args["email"] as? String {
                loginDict["email"] = email
            }
            if let password = args["password"] as? String {
                loginDict["password"] = password
            }
            if let captchaId = args["captcha_id"] as? String {
                loginDict["captcha_id"] = captchaId
            }
//            if let accountId = args["account_id"] as? String {
//                                        loginDict["account_id"] = accountId
//                                    }
            print("📋 邮箱登录: email=\(loginDict["email"] ?? "nil")")
            
        case "token":
            // Token 登录
            if let token = args["token"] as? String {
                // 对于 token 登录，使用旧的方法
                let code = IMSDKAuthManager.shared().login(withToken: token) { errorCode, reqId, data in
//                    print("✅ Token登录回调: errorCode=\(errorCode), reqId=\(reqId)")
                    result([
                        "errorCode": errorCode,
                        "reqId": reqId,
                        "message": errorCode == 0 ? "登录成功" : "登录失败",
                        "data": data ?? ""
                    ])
                }
                if code != 0 {
                    result(FlutterError(code: "LOGIN_ERROR", message: "Token登录请求发送失败: \(code)", details: nil))
                }
                return
            }
            
        default:
            // 兼容旧的 userId + token 方式
            if let userId = args["userId"] as? String, let token = args["token"] as? String {
                let code = IMSDKAuthManager.shared().login(withUserId: userId, token: token) { errorCode, reqId, data in
//                    print("✅ 登录回调: errorCode=\(errorCode), reqId=\(reqId)")
                    result([
                        "errorCode": errorCode,
                        "reqId": reqId,
                        "message": errorCode == 0 ? "登录成功" : "登录失败",
                        "data": data ?? ""
                    ])
                }
                if code != 0 {
                    result(FlutterError(code: "LOGIN_ERROR", message: "登录请求发送失败: \(code)", details: nil))
                }
                return
            }
        }
        
        // 可选字段
        if let deviceId = args["device_id"] as? String {
            loginDict["device_id"] = deviceId
        }
        if let bizCode = args["biz_code"] as? String {
            loginDict["biz_code"] = bizCode
        }
        if let clientIp = args["client_ip"] as? String {
            loginDict["client_ip"] = clientIp
        }
        
        // 调用新的字典登录方法
        let code = IMSDKAuthManager.shared().login(with: loginDict) { errorCode, reqId, data in
//            print("✅ 登录回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "登录成功",
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "登录失败",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "LOGIN_ERROR", 
                              message: "登录请求发送失败: \(code)", 
                              details: nil))
        }
    }
    
    /// 搜索用户
    /// 参数说明：
    /// - user_id: 用户ID（可选）
    /// - account_id: 账户ID，可以是手机号、邮箱等（可选）
    private func imSearchUser(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let userId = args["user_id"] as? String
        let accountId = args["account_id"] as? String
        
        if userId == nil && accountId == nil {
            result(FlutterError(code: "INVALID_ARGS", message: "必须提供 user_id 或 account_id", details: nil))
            return
        }
        
        print("🔍 搜索用户: user_id=\(userId ?? "nil"), account_id=\(accountId ?? "nil")")
        
        let code = IMSDKAuthManager.shared().searchUser(withUserId: userId, accountId: accountId) { errorCode, reqId, data in
            print("✅ 用户搜索回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "搜索成功",
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "未找到用户",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "SEARCH_ERROR",
                              message: "搜索请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 联系人管理
    
    /// 添加联系人（发送好友申请）
    private func imAddContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let targetUserId = args["target_user_id"] as? String, !targetUserId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "目标用户ID不能为空", details: nil))
            return
        }
        
        print("👥 添加联系人: \(args)")
        
        let code = IMSDKContactManager.shared().addContact(withParams: args) { errorCode, reqId, data in
            print("✅ 添加联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "好友申请已发送",
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "发送好友申请失败",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "ADD_CONTACT_ERROR",
                              message: "添加联系人请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 删除联系人
    private func imDeleteContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "用户ID不能为空", details: nil))
            return
        }
        
        print("🗑️ 删除联系人: \(userId)")
        
        let code = IMSDKContactManager.shared().deleteContact(withUserId: userId) { errorCode, reqId, data in
            print("✅ 删除联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "删除成功" : "删除失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "DELETE_CONTACT_ERROR",
                              message: "删除联系人请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 拉黑用户
    private func imBlockContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "用户ID不能为空", details: nil))
            return
        }
        
        print("🚫 拉黑用户: \(userId)")
        
        let code = IMSDKContactManager.shared().blockContact(withUserId: userId) { errorCode, reqId, data in
            print("✅ 拉黑用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "拉黑成功" : "拉黑失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "BLOCK_CONTACT_ERROR",
                              message: "拉黑用户请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 取消拉黑
    private func imUnblockContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "用户ID不能为空", details: nil))
            return
        }
        
        print("✅ 取消拉黑用户: \(userId)")
        
        let code = IMSDKContactManager.shared().unblockContact(withUserId: userId) { errorCode, reqId, data in
            print("✅ 取消拉黑回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "取消拉黑成功" : "取消拉黑失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "UNBLOCK_CONTACT_ERROR",
                              message: "取消拉黑请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取联系人列表
    private func imGetContactList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        let relationship = args["relationship"] as? Int ?? -1  // 默认 -1 表示获取全部
        
        print("📋 获取联系人列表: page=\(page), pageSize=\(pageSize), relationship=\(relationship)")
        
        let code = IMSDKContactManager.shared().getContactList(withPage: Int32(page), pageSize: Int32(pageSize), relationship: Int32(relationship)) { errorCode, reqId, data in
            print("✅ 联系人列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_CONTACT_LIST_ERROR",
                              message: "获取联系人列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 好友申请
    
    /// 获取好友申请列表
    private func imGetFriendRequests(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let status = args["status"] as? Int ?? 0
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        
        print("📋 获取好友申请列表: status=\(status), page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKContactManager.shared().getFriendRequests(withStatus: Int32(status), page: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("✅ 好友申请列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_FRIEND_REQUESTS_ERROR",
                              message: "获取好友申请列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 同意好友申请
    private func imAcceptFriendRequest(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let requestId = args["request_id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("✅ 同意好友申请: requestId=\(requestId)")
        
        let code = IMSDKContactManager.shared().acceptFriendRequest(withId: Int64(requestId)) { errorCode, reqId, data in
            print("✅ 同意申请回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "已同意" : "操作失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "ACCEPT_REQUEST_ERROR",
                              message: "同意好友申请请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 拒绝好友申请
    private func imRejectFriendRequest(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let requestId = args["request_id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("❌ 拒绝好友申请: requestId=\(requestId), reason=\(reason ?? "")")
        
        let code = IMSDKContactManager.shared().rejectFriendRequest(withId: Int64(requestId), reason: reason) { errorCode, reqId, data in
            print("✅ 拒绝申请回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "已拒绝" : "操作失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "REJECT_REQUEST_ERROR",
                              message: "拒绝好友申请请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 会话管理
    
    /// 获取会话列表
    private func imGetConversationList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        let convType = args["conv_type"] as? Int ?? -1
        
        print("📋 获取会话列表: page=\(page), pageSize=\(pageSize), convType=\(convType)")
        
        let code = IMSDKConversationManager.shared().getConversationList(withPage: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("✅ 会话列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_CONVERSATION_LIST_ERROR",
                              message: "获取会话列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取单个会话
    private func imGetConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📋 获取会话: convId=\(convId)")
        
        let code = IMSDKConversationManager.shared().getConversationWithId(convId, completion: { errorCode, reqId, data in
            print("✅ 获取会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_CONVERSATION_ERROR",
                              message: "获取会话请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 创建会话
    private func imCreateConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convType = args["conv_type"] as? Int,
              let targetId = args["target_id"] as? String,
              let displayName = args["display_name"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📋 创建会话: convType=\(convType), targetId=\(targetId), displayName=\(displayName)")
        
        var params: [String: Any] = [
            "conv_type": convType,
            "target_id": targetId,
            "display_name": displayName
        ]
        if let avatarUrl = args["avatar_url"] as? String {
            params["avatar_url"] = avatarUrl
        }
        
        let code = IMSDKConversationManager.shared().createConversation(withParams: params) { errorCode, reqId, data in
            print("✅ 创建会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "创建成功" : "创建失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "CREATE_CONVERSATION_ERROR",
                              message: "创建会话请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 删除会话
    private func imDeleteConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📋 删除会话: convId=\(convId)")
        
        let code = IMSDKConversationManager.shared().deleteConversation(withId: convId) { errorCode, reqId, data in
            print("✅ 删除会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "删除成功" : "删除失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "DELETE_CONVERSATION_ERROR",
                              message: "删除会话请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 标记会话已读
    private func imMarkConversationRead(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📋 标记会话已读: convId=\(convId)")
        
        let code = IMSDKConversationManager.shared().markConversationRead(withId: convId) { errorCode, reqId, data in
            print("✅ 标记已读回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "标记成功" : "标记失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "MARK_READ_ERROR",
                              message: "标记已读请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 清空会话消息
    private func imClearConversationMessages(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📋 清空会话消息: convId=\(convId)")
        
        let code = IMSDKConversationManager.shared().clearConversationMessages(withId: convId) { errorCode, reqId, data in
            print("✅ 清空消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "清空成功" : "清空失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "CLEAR_MESSAGES_ERROR",
                              message: "清空消息请求发送失败: \(code)",
                              details: nil))
        }
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
