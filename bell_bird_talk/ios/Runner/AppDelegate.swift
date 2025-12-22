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
    private weak var binaryMessenger: FlutterBinaryMessenger?
    
    // MARK: - 初始化
    
    func setup(with controller: FlutterViewController) {
        // 保存 binaryMessenger 引用
        binaryMessenger = controller.binaryMessenger
        
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
            
        case "imRefreshToken":
            imRefreshToken(call: call, result: result)
            
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
        case "imGetBlackStatus":
            imGetBlackStatus(call: call, result: result)
        case "imGetContactList":
            imGetContactList(call: call, result: result)
        case "imSearchContact":
            imSearchContact(call: call, result: result)
        
        // ---------- 好友申请 ----------
        case "imGetFriendRequests":
            imGetFriendRequests(call: call, result: result)
        case "imAcceptFriendRequest":
            imAcceptFriendRequest(call: call, result: result)
        case "imRejectFriendRequest":
            imRejectFriendRequest(call: call, result: result)
        case "imGetContactGroups":
            imGetContactGroups(call: call, result: result)
        case "imCreateContactGroup":
            imCreateContactGroup(call: call, result: result)
        case "imUpdateContactGroup":
            imUpdateContactGroup(call: call, result: result)
        case "imDeleteContactGroup":
            imDeleteContactGroup(call: call, result: result)
        case "imGetGroupList":
            imGetGroupList(call: call, result: result)
        case "imGetGroupMembers":
            imGetGroupMembers(call: call, result: result)
        case "imUpdateGroup":
            imUpdateGroup(call: call, result: result)
        case "imSetGroupAlias":
            imSetGroupAlias(call: call, result: result)
        case "imGetGroupInfo":
            imGetGroupInfo(call: call, result: result)
        case "imDissolveGroup":
            imDissolveGroup(call: call, result: result)
        case "imLeaveGroup":
            imLeaveGroup(call: call, result: result)
        case "imSetGroupDisturb":
            imSetGroupDisturb(call: call, result: result)
        case "imGetGroupDisturbStatus":
            imGetGroupDisturbStatus(call: call, result: result)
        case "imAddGroupMembers":
            imAddGroupMembers(call: call, result: result)
        case "imRemoveGroupMembers":
            imRemoveGroupMembers(call: call, result: result)
        case "imSetContactRemark":
            imSetContactRemark(call: call, result: result)
        case "imMoveContactToGroup":
            imMoveContactToGroup(call: call, result: result)
        case "imGetUsersInfo":
            imGetUsersInfo(call: call, result: result)
        
        // ---------- 会话管理 ----------
        case "imGetConversationList":
            imGetConversationList(call: call, result: result)
        case "imGetConversation":
            imGetConversation(call: call, result: result)
        case "imGetUnreadConversations":
            imGetUnreadConversations(call: call, result: result)
        case "imUpdateConversation":
            imUpdateConversation(call: call, result: result)
        case "imCreateConversation":
            imCreateConversation(call: call, result: result)
        // ---------- 通知 ----------
        case "imGetNotificationUnreadCount":
            imGetNotificationUnreadCount(call: call, result: result)
        case "imPullNotifications":
            imPullNotifications(call: call, result: result)
        case "imMarkNotificationRead":
            imMarkNotificationRead(call: call, result: result)
        case "imDeleteConversation":
            imDeleteConversation(call: call, result: result)
        case "imMarkConversationRead":
            imMarkConversationRead(call: call, result: result)
        case "imClearConversationMessages":
            imClearConversationMessages(call: call, result: result)
        
        // ---------- 消息管理 ----------
        case "imSendTextMessage":
            imSendTextMessage(call: call, result: result)
        case "imSendImageMessage":
            imSendImageMessage(call: call, result: result)
        case "imSendVideoMessage":
            imSendVideoMessage(call: call, result: result)
        case "imSendVoiceMessage":
            imSendVoiceMessage(call: call, result: result)
        case "imSendGroupTextMessage":
            imSendGroupTextMessage(call: call, result: result)
        case "imSendGroupImageMessage":
            imSendGroupImageMessage(call: call, result: result)
        case "imSendGroupVoiceMessage":
            imSendGroupVoiceMessage(call: call, result: result)
        case "imSendGroupVideoMessage":
            imSendGroupVideoMessage(call: call, result: result)
        case "imSendGroupAtMessage":
            imSendGroupAtMessage(call: call, result: result)
        case "imPullMessages":
            imPullMessages(call: call, result: result)
        case "imPullGroupMessages":
            imPullGroupMessages(call: call, result: result)
        case "imRegisterMessageCallbacks":
            imRegisterMessageCallbacks(result: result)
        case "imUnregisterMessageCallbacks":
            imUnregisterMessageCallbacks(result: result)
        
        // ---------- 用户管理 ----------
        case "imUpdateUserInfo":
            imUpdateUserInfo(call: call, result: result)
        
        case "imLogout":
            imLogout(call: call, result: result)
        case "imDeactivateAccount":
            imDeactivateAccount(call: call, result: result)
        case "imGetDeactivateStatus":
            imGetDeactivateStatus(call: call, result: result)
            

        case "imChangePassword":
            imChangePassword(call: call, result: result)
        
        case "imResetPassword":
            imResetPassword(call: call, result: result)
        
        // ---------- 文件管理 ----------
        case "imPrepareUpload":
            imPrepareUpload(call: call, result: result)
        
        case "imUploadWithTencentSTS":
            imUploadWithTencentSTS(call: call, result: result)
        
        // ---------- 群组管理 ----------
        case "imCreateGroup":
            imCreateGroup(call: call, result: result)
        
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
            // 也可能是手机密码登录或邮箱密码登录，需要额外传递 phone 或 email
            if let accountId = args["account_id"] as? String {
                loginDict["account_id"] = accountId
            }
            if let password = args["password"] as? String {
                loginDict["password"] = password
            }
            // 手机密码登录时需要传递手机号
            if let phone = args["phone"] as? String {
                loginDict["phone"] = phone
            }
            // 邮箱密码登录时需要传递邮箱
            if let email = args["email"] as? String {
                loginDict["email"] = email
            }
            print("📋 密码登录: account_id=\(loginDict["account_id"] ?? "nil"), phone=\(loginDict["phone"] ?? "nil"), email=\(loginDict["email"] ?? "nil")")
            
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
            if let accountId = args["account_id"] as? String {
                            loginDict["account_id"] = accountId
                        }
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
            if let accountId = args["account_id"] as? String {
                                        loginDict["account_id"] = accountId
                                    }
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
    
    /// 刷新认证Token
    private func imRefreshToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let refreshToken = args["refreshToken"] as? String, !refreshToken.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "refreshToken不能为空", details: nil))
            return
        }
        
        print("🔄 刷新认证Token: \(refreshToken)")
        
        let code = IMSDKAuthManager.shared().refreshAuthToken(withToken: refreshToken) { errorCode, reqId, data in
            print("✅ 刷新Token回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            if errorCode == 0 {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "刷新成功",
                    "data": data ?? ""
                ])
            } else {
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": "刷新失败",
                    "data": data ?? ""
                ])
            }
        }
        
        if code != 0 {
            result(FlutterError(code: "REFRESH_ERROR",
                              message: "刷新Token请求发送失败: \(code)",
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
        
        guard let contact_user_id = args["contact_user_id"] as? String, !contact_user_id.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "用户ID不能为空", details: nil))
            return
        }
        
        print("🗑️ 删除联系人: \(contact_user_id)")
        
        let code = IMSDKContactManager.shared().deleteContact(withUserId: contact_user_id) { errorCode, reqId, data in
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
    
    /// 获取黑名单状态
    private func imGetBlackStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "用户ID不能为空", details: nil))
            return
        }
        
        print("🔍 获取黑名单状态: \(userId)")
        
        let code = IMSDKContactManager.shared().getBlackStatus(withUserId: userId) { errorCode, reqId, data in
            print("🔍 获取黑名单状态回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_BLACK_STATUS_ERROR",
                              message: "获取黑名单状态请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取联系人列表
    private func imGetContactList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        let relationship = args["relationship"] as? Int ?? -1  // 默认 -1 表示获取全部
        let groupId = args["group_id"] as? Int64 ?? 0  // 默认 0 表示不按分组过滤
        let keyword = args["keyword"] as? String  // 搜索关键词（可选）
        
        print("📋 获取联系人列表: page=\(page), pageSize=\(pageSize), relationship=\(relationship), groupId=\(groupId), keyword=\(keyword ?? "(nil)")")
        
        let code = IMSDKContactManager.shared().getContactList(withPage: Int32(page), pageSize: Int32(pageSize), relationship: Int32(relationship), groupId: groupId, keyword: keyword) { errorCode, reqId, data in
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
    
    /// 搜索联系人
    private func imSearchContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let keyword = (args["keyword"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 搜索联系人: keyword=\(keyword)")
        
        guard !keyword.isEmpty else {
            result([
                "errorCode": -1,
                "reqId": 0,
                "message": "搜索关键词不能为空",
                "data": ""
            ])
            return
        }
        
        let code = IMSDKContactManager.shared().searchContact(withKeyword: keyword) { errorCode, reqId, data in
            print("✅ 搜索联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "搜索成功" : "搜索失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEARCH_CONTACT_ERROR",
                              message: "搜索联系人请求发送失败: \(code)",
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
    
    /// 获取联系人分组列表
    private func imGetContactGroups(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 100
        
        print("📁 获取联系人分组列表: page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKContactManager.shared().getContactGroups(withPage: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("✅ 联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_CONTACT_GROUPS_ERROR",
                              message: "获取联系人分组列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 创建联系人分组
    private func imCreateContactGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupName = args["group_name"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let groupColor = args["group_color"] as? String
        let groupOrder = args["group_order"] as? Int32 ?? 0
        let groupIcon = args["group_icon"] as? String
        let groupDescription = args["group_description"] as? String
        
        print("📁 创建联系人分组: groupName=\(groupName)")
        
        let code = IMSDKContactManager.shared().createContactGroup(withName: groupName, groupColor: groupColor, groupOrder: groupOrder, groupIcon: groupIcon, groupDescription: groupDescription, completion: { errorCode, reqId, data in
            print("✅ 创建联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "创建成功" : "创建失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "CREATE_CONTACT_GROUP_ERROR",
                              message: "创建联系人分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 更新联系人分组
    private func imUpdateContactGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? Int64 ?? (args["group_id"] as? Int).map({ Int64($0) }) else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        let groupName = args["group_name"] as? String
        let groupColor = args["group_color"] as? String
        let groupOrder = (args["group_order"] as? Int32) ?? (args["group_order"] as? Int).map { Int32($0) } ?? 0
        let groupIcon = args["group_icon"] as? String
        let groupDescription = args["group_description"] as? String
        
        print("📁 更新联系人分组: groupId=\(groupId), name=\(groupName ?? "")")
        
        let code = IMSDKContactManager.shared().updateContactGroup(withId: groupId, groupName: groupName, groupColor: groupColor, groupOrder: groupOrder, groupIcon: groupIcon, groupDescription: groupDescription) { errorCode, reqId, data in
            print("✅ 更新联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "更新成功" : "更新失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_CONTACT_GROUP_ERROR",
                              message: "更新联系人分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 删除联系人分组
    private func imDeleteContactGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? Int64 ?? (args["group_id"] as? Int).map({ Int64($0) }) else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        print("📁 删除联系人分组: groupId=\(groupId)")
        
        let code = IMSDKContactManager.shared().deleteContactGroup(withId: groupId) { errorCode, reqId, data in
            print("✅ 删除联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "删除成功" : "删除失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "DELETE_CONTACT_GROUP_ERROR",
                              message: "删除联系人分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取群组列表
    private func imGetGroupList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let groupType = args["group_type"] as? Int ?? -1
        let status = args["status"] as? Int ?? -1
        let keyword = args["keyword"] as? String
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 50
        
        print("📁 获取群组列表: type=\(groupType), status=\(status), page=\(page), size=\(pageSize), keyword=\(keyword ?? "")")
        
        let code = IMSDKGroupManager.shared().getGroupList(withType: Int32(groupType), status: Int32(status), keyword: keyword, page: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("📁 群组列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_LIST_ERROR",
                                message: "获取群组列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取群成员列表
    private func imGetGroupMembers(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        let status = args["status"] as? Int ?? 0
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 50
        
        print("📁 获取群成员列表: groupId=\(groupId), status=\(status), page=\(page), size=\(pageSize)")
        
        let code = IMSDKGroupManager.shared().getGroupMembers(withGroupId: groupId, status: Int32(status), page: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("📁 群成员列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_MEMBERS_ERROR",
                                message: "获取群成员列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // 移除群成员
    
    /// 更新群信息（名称/头像/公告/描述）
    private func imUpdateGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        let groupName = args["group_name"] as? String
        let groupAvatar = args["group_avatar"] as? String
        let groupAnnouncement = args["group_announcement"] as? String
        let groupDescription = args["group_description"] as? String
        let version = (args["version"] as? Int32) ?? (args["version"] as? Int).map { Int32($0) } ?? 1
        
        print("📁 更新群信息: groupId=\(groupId), name=\(groupName ?? ""), avatar=\(groupAvatar ?? "")")
        
        let code = IMSDKGroupManager.shared().updateGroup(withId: groupId, groupName: groupName, groupAvatar: groupAvatar, groupAnnouncement: groupAnnouncement, groupDescription: groupDescription, version: version) { errorCode, reqId, data in
            print("📁 更新群信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "更新成功" : "更新失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_GROUP_ERROR",
                                message: "更新群信息请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 设置群内昵称
    private func imSetGroupAlias(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String,
              let alias = args["alias"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id 或 alias", details: nil))
            return
        }
        
        print("📁 设置群昵称: groupId=\(groupId), alias=\(alias)")
        
        let code = IMSDKGroupManager.shared().setGroupMemberAliasWithGroupId(groupId, memberAlias: alias, completion: { errorCode, reqId, data in
            print("📁 设置群昵称回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "设置成功" : "设置失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "SET_GROUP_ALIAS_ERROR",
                                message: "设置群昵称请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 获取群信息
    private func imGetGroupInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        print("📁 获取群信息: groupId=\(groupId)")
        
        let code = IMSDKGroupManager.shared().getGroupInfo(withId: groupId) { errorCode, reqId, data in
            print("📁 获取群信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_INFO_ERROR",
                                message: "获取群信息请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 解散群组
    private func imDissolveGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("📁 解散群组: groupId=\(groupId), reason=\(reason ?? "")")
        
        let code = IMSDKGroupManager.shared().dissolveGroup(withId: groupId, reason: reason) { errorCode, reqId, data in
            print("📁 解散群组回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "解散成功" : "解散失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "DISSOLVE_GROUP_ERROR",
                                message: "解散群组请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 退出群组
    private func imLeaveGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("📁 退出群组: groupId=\(groupId), reason=\(reason ?? "")")
        
        let code = IMSDKGroupManager.shared().leaveGroup(withId: groupId, reason: reason) { errorCode, reqId, data in
            print("📁 退出群组回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "退出成功" : "退出失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "LEAVE_GROUP_ERROR",
                                message: "退出群组请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 设置群组免打扰
    private func imSetGroupDisturb(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String,
              let disturb = args["disturb"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id 或 disturb", details: nil))
            return
        }
        
        print("📁 设置群组免打扰: groupId=\(groupId), disturb=\(disturb)")
        
        let code = IMSDKGroupManager.shared().setGroupDisturbWithGroupId(groupId, disturb: disturb, completion: { errorCode, reqId, data in
            print("📁 设置群组免打扰回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "设置成功" : "设置失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "SET_GROUP_DISTURB_ERROR",
                                message: "设置群组免打扰请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 查询群组免打扰状态
    private func imGetGroupDisturbStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        print("📁 查询群组免打扰状态: groupId=\(groupId)")
        
        let code = IMSDKGroupManager.shared().getGroupDisturbStatus(withGroupId: groupId) { errorCode, reqId, data in
            print("📁 查询群组免打扰状态回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "查询成功" : "查询失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_DISTURB_STATUS_ERROR",
                                message: "查询群组免打扰状态请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 添加群组成员
    private func imAddGroupMembers(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String,
              let userIds = args["user_ids"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id 或 user_ids", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("📁 添加群组成员: groupId=\(groupId), userIds=\(userIds), reason=\(reason ?? "")")
        
        let code = IMSDKGroupManager.shared().addGroupMembers(withGroupId: groupId, userIds: userIds, reason: reason) { errorCode, reqId, data in
            print("📁 添加群组成员回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "添加成功" : "添加失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "ADD_GROUP_MEMBERS_ERROR",
                                message: "添加群组成员请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 移除群组成员
    private func imRemoveGroupMembers(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String,
              let userIds = args["user_ids"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id 或 user_ids", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("📁 添加群组成员: groupId=\(groupId), userIds=\(userIds), reason=\(reason ?? "")")
        
        let code = IMSDKGroupManager.shared().removeGroupMembers(withGroupId: groupId, userIds: userIds, reason: reason, completion: { errorCode, reqId, data in
            print("📁 添加群组成员回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "添加成功" : "添加失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "ADD_GROUP_MEMBERS_ERROR",
                                message: "添加群组成员请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 设置联系人备注
    private func imSetContactRemark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["user_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 user_id", details: nil))
            return
        }
        
        let remark = args["remark"] as? String ?? ""
        
        print("📝 设置联系人备注: userId=\(userId), remark=\(remark)")
        
        let code = IMSDKContactManager.shared().setRemarkForUserId(userId, remark: remark, completion: { errorCode, reqId, data in
            print("✅ 设置备注回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "设置备注成功" : (data ?? "设置备注失败")
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "SET_REMARK_ERROR",
                              message: "设置备注请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 获取用户信息
    private func imGetUsersInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userIds = args["user_ids"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 user_ids", details: nil))
            return
        }
        
        print("👤 获取用户信息: userIds=\(userIds)")
        
        let reqId = IMSDKUserManager.shared().getUsersInfo(withUserIds: userIds) { errorCode, message, data, reqId in
            print("👤 获取用户信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 将返回的数据转换为 JSON 字符串
            var dataStr = ""
            if let data = data {
                if let users = data["users"] as? [[String: Any]] {
                    // 如果有 users 数组，转换为 JSON
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: users, options: [])
                        dataStr = String(data: jsonData, encoding: .utf8) ?? ""
                    } catch {
                        print("⚠️ 序列化用户信息失败: \(error)")
                    }
                } else if let rawData = data["raw_data"] as? String {
                    // 如果有原始数据，直接使用
                    dataStr = rawData
                } else {
                    // 尝试将整个 data 字典转换为 JSON
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                        dataStr = String(data: jsonData, encoding: .utf8) ?? ""
                    } catch {
                        print("⚠️ 序列化数据失败: \(error)")
                    }
                }
            }
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? (errorCode == 0 ? "获取成功" : "获取失败"),
                "data": dataStr
            ])
        }
        
        if reqId == 0 {
            result(FlutterError(code: "GET_USERS_INFO_ERROR",
                              message: "获取用户信息请求发送失败",
                              details: nil))
        }
    }
    
    /// 移动联系人到分组
    private func imMoveContactToGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contactUserId = args["contact_user_id"] as? String,
              let groupId = args["group_id"] as? Int64 ?? (args["group_id"] as? Int).map({ Int64($0) }) else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 contact_user_id 或 group_id", details: nil))
            return
        }
        
        print("📁 移动联系人到分组: contactUserId=\(contactUserId), groupId=\(groupId)")
        
        let code = IMSDKContactManager.shared().moveContactToGroup(withContactUserId: contactUserId, groupId: groupId, completion: { errorCode, reqId, data in
            print("✅ 移动联系人到分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "移动成功" : (data ?? "移动失败")
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "MOVE_CONTACT_TO_GROUP_ERROR",
                              message: "移动联系人到分组请求发送失败: \(code)",
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
    
    /// 获取未读会话列表
    private func imGetUnreadConversations(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("📋 获取未读会话列表")
        
        let args = call.arguments as? [String: Any]
        let page = args?["page"] as? Int ?? 1
        let pageSize = args?["page_size"] as? Int ?? 20
        let convTypeValue = args?["conv_type"] as? Int ?? -1
        let convType = IMConversationType(rawValue: convTypeValue) ?? IMConversationType(rawValue: -1) ?? .single
        
        let code = IMSDKConversationManager.shared().getUnreadConversations(withPage: Int32(page), pageSize: Int32(pageSize), convType: convType, completion: { errorCode, reqId, data in
            print("✅ 获取未读会话列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_UNREAD_CONVERSATIONS_ERROR",
                              message: "获取未读会话列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    /// 更新会话信息
    private func imUpdateConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        var params: [String: Any] = [:]
        if let displayName = args["display_name"] as? String {
            params["display_name"] = displayName
        }
        if let avatarUrl = args["avatar_url"] as? String {
            params["avatar_url"] = avatarUrl
        }
        if let description = args["description"] as? String {
            params["description"] = description
        }
        
        print("📋 更新会话: convId=\(convId), params=\(params)")
        
        let code = IMSDKConversationManager.shared().updateConversation(withId: convId, params: params) { errorCode, reqId, data in
            print("✅ 更新会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "更新成功" : "更新失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_CONVERSATION_ERROR",
                              message: "更新会话请求发送失败: \(code)",
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
    
    // MARK: - 通知
    
    /// 获取通知未读数量
    private func imGetNotificationUnreadCount(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let types = args["types"] as? [String]
        
        print("🔔 获取通知未读数量: types=\(types ?? [])")
        
        let code = IMSDKMessageManager.shared().getNotificationUnreadCount(withTypes: types) { errorCode, reqId, data in
            print("🔔 通知未读回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "GET_NOTIFICATION_UNREAD_ERROR",
                                message: "获取通知未读请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 拉取通知列表
    private func imPullNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let types = args["types"] as? [String]
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        
        print("🔔 拉取通知: page=\(page), pageSize=\(pageSize), types=\(types ?? [])")
        
        let code = IMSDKMessageManager.shared().pullNotifications(withTypes: types, page: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("🔔 拉取通知回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "PULL_NOTIFICATION_ERROR",
                                message: "拉取通知请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 标记通知已读
    private func imMarkNotificationRead(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        guard let ids = args["notification_ids"] as? [Any], !ids.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "notification_ids 不能为空", details: nil))
            return
        }
        let readTimeArg = args["read_time"]
        let readTime = (readTimeArg as? Int64) ?? (readTimeArg as? Int).map { Int64($0) } ?? 0
        
        let idNumbers: [NSNumber] = ids.compactMap {
            if let n = $0 as? NSNumber { return n }
            if let s = $0 as? String, let v = Int64(s) { return NSNumber(value: v) }
            return nil
        }
        
        if idNumbers.isEmpty {
            result(FlutterError(code: "INVALID_ARGS", message: "notification_ids 解析失败", details: nil))
            return
        }
        
        print("🔔 标记通知已读: ids=\(idNumbers), readTime=\(readTime)")
        
        let code = IMSDKMessageManager.shared().markNotificationsRead(idNumbers, readTime: readTime) { errorCode, reqId, data in
            print("🔔 标记通知已读回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "标记成功" : "标记失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "MARK_NOTIFICATION_READ_ERROR",
                                message: "标记通知已读请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 消息管理
    
    /// 发送文本消息
    private func imSendTextMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let content = args["content"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let receiverId = args["receiver_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let ext = args["ext"] as? String
        
        print("📤 发送文本消息: content=\(content), conversationId=\(conversationId), receiverId=\(receiverId)")
        
        let code = IMSDKMessageManager.shared().sendTextMessage(
            content,
            ext: ext,
            conversationId: conversationId,
            receiverId: receiverId
        ) { errorCode, reqId, data in
            print("✅ 发送消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_MESSAGE_ERROR",
                              message: "发送消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送图片消息
    private func imSendImageMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageUrl = args["image_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let receiverId = args["receiver_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let thumbnailUrl = args["thumbnail_url"] as? String
        let width = args["width"] as? Int ?? 0
        let height = args["height"] as? Int ?? 0
        
        print("📤 发送图片消息: imageUrl=\(imageUrl), thumbnailUrl=\(thumbnailUrl ?? ""), width=\(width), height=\(height), conversationId=\(conversationId), receiverId=\(receiverId)")
        
        let code = IMSDKMessageManager.shared().sendImageMessage(
            imageUrl,
            thumbnailUrl: thumbnailUrl,
            width: Int32(width),
            height: Int32(height),
            conversationId: conversationId,
            receiverId: receiverId
        ) { errorCode, reqId, data in
            print("✅ 发送图片消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_MESSAGE_ERROR",
                              message: "发送图片消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送语音消息
    private func imSendVoiceMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let audioUrl = args["audio_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let receiverId = args["receiver_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let duration = args["duration"] as? Int ?? 0
        
        print("📤 发送语音消息: audioUrl=\(audioUrl), duration=\(duration), conversationId=\(conversationId), receiverId=\(receiverId)")
        
        let code = IMSDKMessageManager.shared().sendVoiceMessage(
            audioUrl,
            duration: Int32(duration),
            conversationId: conversationId,
            receiverId: receiverId
        ) { errorCode, reqId, data in
            print("✅ 发送语音消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_MESSAGE_ERROR",
                              message: "发送语音消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送视频消息
    private func imSendVideoMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoUrl = args["video_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let receiverId = args["receiver_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let coverUrl = args["cover_url"] as? String
        let duration = args["duration"] as? Int ?? 0
        let width = args["width"] as? Int ?? 0
        let height = args["height"] as? Int ?? 0
        let size = args["size"] as? Int64 ?? 0
        
        print("📤 发送视频消息: videoUrl=\(videoUrl), coverUrl=\(coverUrl ?? ""), duration=\(duration), size=\(size), conversationId=\(conversationId), receiverId=\(receiverId)")
        
        let code = IMSDKMessageManager.shared().sendVideoMessage(
            videoUrl,
            coverURL: coverUrl,
            duration: Int32(duration),
            width: Int32(width),
            height: Int32(height),
            size: size,
            conversationId: conversationId,
            receiverId: receiverId
        ) { errorCode, reqId, data in
            print("✅ 发送视频消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_MESSAGE_ERROR",
                              message: "发送视频消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 拉取历史消息
    private func imPullMessages(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let conversationId = args["conversation_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let convType = args["conv_type"] as? Int ?? 0
        let targetId = args["target_id"] as? String ?? ""
        let lastSeq = args["last_seq"] as? Int64 ?? 0
        let limit = args["limit"] as? Int ?? 50
        
        print("📥 拉取历史消息: conversationId=\(conversationId), convType=\(convType), targetId=\(targetId), lastSeq=\(lastSeq), limit=\(limit)")
        
        let code = IMSDKMessageManager.shared().pullMessages(
            withConversationId: conversationId,
            convType: Int32(convType),
            targetId: targetId,
            lastSeq: lastSeq,
            limit: Int32(limit)
        ) { errorCode, reqId, data in
            print("✅ 拉取消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "拉取成功" : "拉取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "PULL_MESSAGES_ERROR",
                              message: "拉取消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送群聊文本消息
    private func imSendGroupTextMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let content = args["content"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📤 发送群聊文本消息: content=\(content), conversationId=\(conversationId), groupId=\(groupId)")
        
        let code = IMSDKMessageManager.shared().sendGroupTextMessage(
            content,
            conversationId: conversationId,
            groupId: groupId
        ) { errorCode, reqId, data in
            print("✅ 发送群聊消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_GROUP_MESSAGE_ERROR",
                              message: "发送群聊消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送群聊图片消息
    private func imSendGroupImageMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageUrl = args["image_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let thumbnailUrl = args["thumbnail_url"] as? String
        let width = args["width"] as? Int ?? 0
        let height = args["height"] as? Int ?? 0
        
        print("📤 发送群聊图片消息: imageUrl=\(imageUrl), thumbnailUrl=\(thumbnailUrl ?? ""), width=\(width), height=\(height), conversationId=\(conversationId), groupId=\(groupId)")
        
        let code = IMSDKMessageManager.shared().sendGroupImageMessage(
            imageUrl,
            thumbnailUrl: thumbnailUrl,
            width: Int32(width),
            height: Int32(height),
            conversationId: conversationId,
            groupId: groupId
        ) { errorCode, reqId, data in
            print("✅ 发送群聊图片消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_GROUP_MESSAGE_ERROR",
                              message: "发送群聊图片消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送群聊语音消息
    private func imSendGroupVoiceMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let audioUrl = args["audio_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let duration = args["duration"] as? Int ?? 0
        
        print("📤 发送群聊语音消息: audioUrl=\(audioUrl), duration=\(duration), conversationId=\(conversationId), groupId=\(groupId)")
        
        let code = IMSDKMessageManager.shared().sendGroupVoiceMessage(
            audioUrl,
            duration: Int32(duration),
            conversationId: conversationId,
            groupId: groupId
        ) { errorCode, reqId, data in
            print("✅ 发送群聊语音消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_GROUP_MESSAGE_ERROR",
                              message: "发送群聊语音消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送群聊视频消息
    private func imSendGroupVideoMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoUrl = args["video_url"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let coverUrl = args["cover_url"] as? String
        let duration = args["duration"] as? Int ?? 0
        let width = args["width"] as? Int ?? 0
        let height = args["height"] as? Int ?? 0
        let size = args["size"] as? Int64 ?? 0
        
        print("📤 发送群聊视频消息: videoUrl=\(videoUrl), coverUrl=\(coverUrl ?? ""), duration=\(duration), width=\(width), height=\(height), size=\(size), conversationId=\(conversationId), groupId=\(groupId)")
        
        let code = IMSDKMessageManager.shared().sendGroupVideoMessage(
            videoUrl,
            coverURL: coverUrl,
            duration: Int32(duration),
            width: Int32(width),
            height: Int32(height),
            size: size,
            conversationId: conversationId,
            groupId: groupId
        ) { errorCode, reqId, data in
            print("✅ 发送群聊视频消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_GROUP_MESSAGE_ERROR",
                              message: "发送群聊视频消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 发送群聊@消息
    private func imSendGroupAtMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let content = args["content"] as? String,
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String,
              let atInfoList = args["at_info_list"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let isAll = args["is_all"] as? Bool ?? false
        
        print("📤 发送群聊@消息: content=\(content), conversationId=\(conversationId), groupId=\(groupId), isAll=\(isAll), atInfoList=\(atInfoList)")
        
        // 转换atInfoList格式
        let atInfoArray = atInfoList.map { info -> [String: String] in
            var dict: [String: String] = [:]
            if let userId = info["user_id"] as? String {
                dict["user_id"] = userId
            }
            if let nickname = info["nickname"] as? String {
                dict["nickname"] = nickname
            }
            return dict
        }
        
        let code = IMSDKMessageManager.shared().sendGroup(atMessage: content, conversationId: conversationId, groupId: groupId, atInfoList: atInfoArray, isAll: isAll, completion:{ errorCode, reqId, data in
            print("✅ 发送群聊@消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "SEND_GROUP_AT_MESSAGE_ERROR",
                              message: "发送群聊@消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 拉取群聊历史消息
    private func imPullGroupMessages(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let conversationId = args["conversation_id"] as? String,
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let lastSeq = args["last_seq"] as? Int64 ?? 0
        let limit = args["limit"] as? Int ?? 50
        
        print("📥 拉取群聊历史消息: conversationId=\(conversationId), groupId=\(groupId), lastSeq=\(lastSeq), limit=\(limit)")
        
        let code = IMSDKMessageManager.shared().pullGroupMessages(
            withConversationId: conversationId,
            groupId: groupId,
            lastSeq: lastSeq,
            limit: Int32(limit)
        ) { errorCode, reqId, data in
            print("✅ 拉取群聊消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "拉取成功" : "拉取失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "PULL_GROUP_MESSAGES_ERROR",
                              message: "拉取群聊消息请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 注册消息回调（单聊、群聊、社区、系统、命令）
    private func imRegisterMessageCallbacks(result: @escaping FlutterResult) {
        print("📝 注册消息回调...")
        
        let messageManager = IMSDKMessageManager.shared()
        
        // 设置消息接收回调，将消息通过 EventChannel 推送到 Flutter
        messageManager.onMessageReceived = { [weak self] convType, messageData in
            guard let self = self else { return }
            
            // 构建推送数据
            var eventData: [String: Any] = [
                "conv_type": convType.rawValue,
            ]
            
            // 合并消息数据（转换 key 为 String）
            for (key, value) in messageData {
                if let stringKey = key as? String {
                    eventData[stringKey] = value
                }
            }
            
            // 通过 MethodChannel 推送消息到 Flutter
            self.sendMessageToFlutter(eventData)
        }
        
        // 设置系统消息回调
        messageManager.onSystemMessage = { [weak self] messageData in
            guard let self = self else { return }
            
            var eventData: [String: Any] = [
                "message_type": "system",
            ]
            
            for (key, value) in messageData {
                if let stringKey = key as? String {
                    eventData[stringKey] = value
                }
            }
            
            print("📨 转发系统消息到 Flutter: \(eventData)")
            self.sendSystemMessageToFlutter(eventData)
        }
        
        // 设置命令消息回调
        messageManager.onCommandMessage = { [weak self] eventType, messageData in
            guard let self = self else { return }
            
            var eventData: [String: Any] = [
                "message_type": "command",
                "event_type": eventType,
            ]
            
            for (key, value) in messageData {
                if let stringKey = key as? String {
                    eventData[stringKey] = value
                }
            }
            
            print("📨 转发命令消息到 Flutter: \(eventData)")
            self.sendCommandMessageToFlutter(eventData)
        }
        
        // 注册底层回调
        messageManager.registerMessageCallbacks()
        
        result([
            "errorCode": 0,
            "message": "消息回调注册成功"
        ])
    }
    
    /// 取消注册消息回调
    private func imUnregisterMessageCallbacks(result: @escaping FlutterResult) {
        print("📝 取消注册消息回调...")
        
        let messageManager = IMSDKMessageManager.shared()
        messageManager.onMessageReceived = nil
        messageManager.onSystemMessage = nil
        messageManager.onCommandMessage = nil
        messageManager.unregisterMessageCallbacks()
        
        result([
            "errorCode": 0,
            "message": "消息回调取消注册成功"
        ])
    }
    
    /// 发送消息到 Flutter（通过 MethodChannel 反向调用）
    private func sendMessageToFlutter(_ data: [String: Any]) {
        guard let messenger = binaryMessenger else {
            print("⚠️ binaryMessenger 未初始化")
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.bell_bird_talk/native_bridge",
            binaryMessenger: messenger
        )
        
        channel.invokeMethod("onMessageReceived", arguments: data)
        print("📤 消息已推送到 Flutter: \(data)")
    }
    
    /// 发送系统消息到 Flutter
    private func sendSystemMessageToFlutter(_ data: [String: Any]) {
        guard let messenger = binaryMessenger else {
            print("⚠️ binaryMessenger 未初始化")
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.bell_bird_talk/native_bridge",
            binaryMessenger: messenger
        )
        
        channel.invokeMethod("onSystemMessage", arguments: data)
        print("📤 系统消息已推送到 Flutter: \(data)")
    }
    
    /// 发送命令消息到 Flutter
    private func sendCommandMessageToFlutter(_ data: [String: Any]) {
        guard let messenger = binaryMessenger else {
            print("⚠️ binaryMessenger 未初始化")
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.bell_bird_talk/native_bridge",
            binaryMessenger: messenger
        )
        
        channel.invokeMethod("onCommandMessage", arguments: data)
        print("📤 命令消息已推送到 Flutter: \(data)")
    }
    
    // MARK: - 用户管理
    
    /// 更新用户信息
    /// @param args 参数字典，可包含以下字段：
    ///   - user_id: 用户ID（可选，默认使用当前登录用户）
    ///   - nickname: 昵称
    ///   - sex: 性别 (0=男, 1=女)
    ///   - signature: 个性签名
    ///   - avatar: 头像URL
    ///   - region: 地区
    private func imUpdateUserInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📝 更新用户信息: \(args)")
        
        // 构建用户信息字典
        var userInfo: [String: Any] = [:]
        
        if let userId = args["user_id"] as? String {
            userInfo["user_id"] = userId
        }
        if let nickname = args["nickname"] as? String {
            userInfo["nickname"] = nickname
        }
        if let sex = args["sex"] as? Int {
            userInfo["sex"] = sex
        }
        if let signature = args["signature"] as? String {
            userInfo["signature"] = signature
        }
        if let avatar = args["avatar"] as? String {
            userInfo["avatar"] = avatar
        }
        if let region = args["region"] as? String {
            userInfo["region"] = region
        }
        if let backgroundFile = args["background_file"] as? String {
            userInfo["background_file"] = backgroundFile
        }
        
        let reqId = IMSDKUserManager.shared().updateUser(withInfo: userInfo) { errorCode, message, data, reqId in
            print("✅ 更新用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 构建返回数据
            var response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? ""
            ]
            
            if let data = data {
                // 将数据转换为 JSON 字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    response["data"] = jsonString
                }
            }
            
            result(response)
        }
        
        if reqId == 0 {
            result(FlutterError(code: "UPDATE_USER_ERROR",
                              message: "更新用户请求失败",
                              details: nil))
        }
    }
    
    /// 退出登录
    private func imLogout(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🚪 Flutter调用退出登录")
        let args = call.arguments as? [String: Any] ?? [:]
        let userId = args["user_id"] as? String
        let clientIp = args["client_ip"] as? String
        let reason = args["reason"] as? NSNumber
        
        let reqId = IMSDKUserManager.shared().logout(withUserId: userId, clientIp: clientIp, reason: reason) { errorCode, message, data, reqId in
            print("✅ 退出登录回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            let response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? ""
            ]
            
            result(response)
        }
        
        if reqId == 0 {
            result(FlutterError(code: "LOGOUT_ERROR",
                              message: "退出登录请求失败",
                              details: nil))
        }
    }
    
    /// 注销用户
//    private func imDeleteUser(call: FlutterMethodCall, result: @escaping FlutterResult) {
//        print("🗑 Flutter调用注销用户")
//        
//        let code = IMSDKAuthManager.shared().deleteCurrentUser(completion:  { errorCode, reqId, data in
//            print("✅ 注销用户回调: errorCode=\(errorCode), reqId=\(reqId)")
//            
//            result([
//                "errorCode": errorCode,
//                "reqId": reqId,
//                "message": errorCode == 0 ? "注销成功" : "注销失败",
//                "data": data ?? ""
//            ])
//        })
//        
//        if code != 0 {
//            result(FlutterError(code: "DELETE_USER_ERROR",
//                              message: "注销用户请求失败: \(code)",
//                              details: nil))
//        }
//    }
    
    
    /// 注销用户
    /// 参数:
    ///   - reason: 注销原因（可选）
    private func imDeactivateAccount(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "user_id 不能为空", details: nil))
            return
        }
        
        let reason = args["reason"] as? String
        
        print("🗑️ 注销用户: userId=\(userId), reason=\(reason ?? "无")")
        
        let reqId = IMSDKUserManager.shared().deactivateAccount(withUserId: userId, reason: reason, completion: { errorCode, message, data, reqId in
            print("✅ 注销用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 构建返回数据
            var response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? ""
            ]
            
            if let data = data {
                // 将数据转换为 JSON 字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    response["data"] = jsonString
                }
            }
            
            result(response)
        })
        
        if reqId == 0 {
            result(FlutterError(code: "DEACTIVATE_ACCOUNT_ERROR",
                              message: "注销用户请求失败",
                              details: nil))
        }
    }
    
    /// 获取注销状态
    private func imGetDeactivateStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "user_id 不能为空", details: nil))
            return
        }
        
        print("🔍 获取注销状态: userId=\(userId)")
        
        let reqId = IMSDKUserManager.shared().getDeactivateStatus(withUserId: userId) { errorCode, message, data, reqId in
            print("🔍 获取注销状态回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 构建返回数据
            var response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? (errorCode == 0 ? "获取成功" : "获取失败")
            ]
            
            if let data = data {
                // 将数据转换为 JSON 字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    response["data"] = jsonString
                } else {
                    response["data"] = ""
                }
            } else {
                response["data"] = ""
            }
            
            result(response)
        }
        
        if reqId == 0 {
            result(FlutterError(code: "GET_DEACTIVATE_STATUS_ERROR",
                              message: "获取注销状态请求发送失败",
                              details: nil))
        }
    }
    
    /// 修改密码
    private func imChangePassword(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["user_id"] as? String,
              let oldPassword = args["old_password"] as? String,
              let newPassword = args["new_password"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("🔐 修改密码: userId=\(userId)")
        
        let code = IMSDKAuthManager.shared().changePassword(withUserId: userId, oldPassword: oldPassword, newPassword: newPassword, completion: { errorCode, reqId, data in
            print("✅ 修改密码回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "修改成功" : "修改失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "CHANGE_PASSWORD_ERROR",
                              message: "修改密码请求失败: \(code)",
                              details: nil))
        }
    }
    
    /// 重置密码
    private func imResetPassword(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let captchaId = args["captcha_id"] as? String,
              let code = args["code"] as? String,
              let newPassword = args["new_password"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let phone = args["phone"] as? String
        let email = args["email"] as? String
        
        if phone == nil && email == nil {
            result(FlutterError(code: "INVALID_ARGS", message: "必须提供手机号或邮箱", details: nil))
            return
        }
        
        print("🔐 重置密码: phone=\(phone ?? ""), email=\(email ?? ""), captchaId=\(captchaId)")
        
        let resultCode = IMSDKAuthManager.shared().resetPassword(withPhone: phone, email: email, captchaId: captchaId, captchaCode: code, newPassword: newPassword, completion:{ errorCode, reqId, data in
            print("✅ 重置密码回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "重置成功" : "重置失败",
                "data": data ?? ""
            ])
        })
        
        if resultCode != 0 {
            result(FlutterError(code: "RESET_PASSWORD_ERROR",
                              message: "重置密码请求失败: \(resultCode)",
                              details: nil))
        }
    }
    
    // MARK: - 文件管理
    
    /// 准备上传文件
    /// 参数:
    ///   - business_module: 业务模块（必填，如: avatar, group_avatar, message等）
    ///   - file_name: 文件名（必填）
    ///   - file_size: 文件大小（字节，可选）
    ///   - content_type: 文件MIME类型（可选）
    private func imPrepareUpload(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let businessModule = args["business_module"] as? String, !businessModule.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "业务模块不能为空", details: nil))
            return
        }
        
        guard let fileName = args["file_name"] as? String, !fileName.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "文件名不能为空", details: nil))
            return
        }
        
        let fileSize = args["file_size"] as? Int64 ?? 0
        let contentType = args["content_type"] as? String
        
        print("📤 准备上传: businessModule=\(businessModule), fileName=\(fileName), fileSize=\(fileSize)")
        
        let reqId = IMSDKFileManager.shared().prepareUpload(withBusinessModule: businessModule,
                                                            fileName: fileName,
                                                            fileSize: fileSize,
                                                            contentType: contentType) { errorCode, message, data, reqId in
            print("✅ 准备上传回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            // 构建返回数据
            var response: [String: Any] = [
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? ""
            ]
            
            if let data = data {
                // 将数据转换为 JSON 字符串
                if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    response["data"] = jsonString
                }
            }
            
            result(response)
        }
        
        if reqId == 0 {
            result(FlutterError(code: "PREPARE_UPLOAD_ERROR",
                              message: "准备上传请求失败",
                              details: nil))
        }
    }
    
    /// 使用腾讯云 STS 临时凭证上传文件
    /// 参数:
    ///   - local_file_path: 本地文件路径（必填）
    ///   - object_key: 对象键/远程路径（必填）
    ///   - bucket_name: 存储桶名称（必填）
    ///   - region: 区域（必填）
    ///   - secret_id: 临时 AccessKeyId（必填）
    ///   - secret_key: 临时 SecretKey（必填）
    ///   - token: 临时 Token（必填）
    private func imUploadWithTencentSTS(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let localFilePath = args["local_file_path"] as? String, !localFilePath.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "本地文件路径不能为空", details: nil))
            return
        }
        
        guard let objectKey = args["object_key"] as? String, !objectKey.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "对象键不能为空", details: nil))
            return
        }
        
        guard let bucketName = args["bucket_name"] as? String, !bucketName.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "存储桶名称不能为空", details: nil))
            return
        }
        
        guard let region = args["region"] as? String, !region.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "区域不能为空", details: nil))
            return
        }
        
        guard let secretId = args["secret_id"] as? String, !secretId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "SecretId 不能为空", details: nil))
            return
        }
        
        guard let secretKey = args["secret_key"] as? String, !secretKey.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "SecretKey 不能为空", details: nil))
            return
        }
        
        guard let token = args["token"] as? String, !token.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "Token 不能为空", details: nil))
            return
        }
        
        print("📤 腾讯云 STS 上传: localPath=\(localFilePath), objectKey=\(objectKey), bucket=\(bucketName)")
        
        // 创建上传器并上传
        let uploader = TencentCOSUploader(
            region: region,
            secretId: secretId,
            secretKey: secretKey,
            bucketName: bucketName,
            token: token
        )
        
        uploader.upload(filePath: localFilePath, objectKey: objectKey, progress: { progress in
            print("📊 上传进度: \(Int(progress * 100))%")
        }) { uploadResult in
            if uploadResult.success {
                print("✅ 腾讯云上传成功: \(uploadResult.url ?? "")")
                result([
                    "success": true,
                    "url": uploadResult.url ?? "",
                    "error": NSNull()
                ])
            } else {
                print("❌ 腾讯云上传失败: \(uploadResult.error ?? "未知错误")")
                result([
                    "success": false,
                    "url": NSNull(),
                    "error": uploadResult.error ?? "上传失败"
                ])
            }
        }
    }
    
    // MARK: - 群组管理
    
    /// 创建群聊
    private func imCreateGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupName = args["group_name"] as? String, !groupName.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "群名称不能为空", details: nil))
            return
        }
        
        let avatarUrl = args["avatar_url"] as? String
        let memberIds = args["member_ids"] as? [String] ?? []
        
        // 群组类型：0=普通群, 1=超级群（默认使用普通群）
        let groupType = args["group_type"] as? Int ?? 0
        // 最大成员数（默认500）
        let maxMemberCount = args["max_member_count"] as? Int32 ?? 500
        
        print("📋 创建群聊: groupName=\(groupName), memberIds=\(memberIds), avatarUrl=\(avatarUrl ?? "nil")")
        
        let code = IMSDKGroupManager.shared().createGroup(
            withName: groupName,
            groupAvatar: avatarUrl,
            groupDescription: nil,
            groupType: Int32(groupType),
            maxMemberCount: maxMemberCount,
            initialMembers: memberIds.isEmpty ? nil : memberIds as [String],
            completion: { errorCode, reqId, data in
            print("✅ 创建群聊回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "创建成功" : "创建失败",
                "data": data ?? ""
            ])
        }
        )
        
        if code != 0 {
            result(FlutterError(code: "CREATE_GROUP_ERROR",
                              message: "创建群聊请求发送失败: \(code)",
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
