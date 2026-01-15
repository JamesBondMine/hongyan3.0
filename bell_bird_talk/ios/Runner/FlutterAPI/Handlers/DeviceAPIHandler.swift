//
//  DeviceAPIHandler.swift
//  Runner
//
//  设备相关 API 处理器
//  包括：设备信息、数据存储、通讯录、相机、通知、原生UI、C++数据传输等
//

import Flutter
import UIKit
import Contacts
import UserNotifications

class DeviceAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // 数据互通
        case "getDeviceInfo":
            getDeviceInfo(result: result)
        case "saveData":
            saveData(call: call, result: result)
        case "loadData":
            loadData(call: call, result: result)
            
        // iOS SDK 调用
        case "getContacts":
            getContacts(result: result)
        case "openCamera":
            openCamera(result: result)
        case "sendNotification":
            sendLocalNotification(call: call, result: result)
            
        // 原生 UI
        case "openNativePage":
            openNativePage(call: call, result: result)
        case "showAlert":
            showNativeAlert(call: call, result: result)
            
        // 聊天功能
        case "processMessage":
            processMessage(call: call, result: result)
        case "syncChatData":
            syncChatData(call: call, result: result)
            
        // C++ 数据传输
        case "generateCppData":
            generateCppData(result: result)
        case "processCppString":
            processCppString(call: call, result: result)
        case "calculateCppStatistics":
            calculateCppStatistics(call: call, result: result)
        case "simulateCppDataTransfer":
            simulateCppDataTransfer(call: call, result: result)
            
        // 音频处理
        case "mergeAudioFiles":
            mergeAudioFiles(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 数据互通实现
    
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
    
    private func openCamera(result: @escaping FlutterResult) {
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "相机功能需要完整实现", details: nil))
    }
    
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
    
    private func openNativePage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let pageName = args["pageName"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            switch pageName {
            case "settings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                result(true)
            default:
                result(FlutterError(code: "PAGE_NOT_FOUND", message: "页面不存在: \(pageName)", details: nil))
            }
        }
    }
    
    private func showNativeAlert(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误：缺少 message", details: nil))
            return
        }
        
        let title = args["title"] as? String ?? "提示"
        let confirmText = args["confirmText"] as? String ?? "确定"
        let cancelText = args["cancelText"] as? String ?? "取消"
        let showCancel = args["showCancel"] as? Bool ?? true
        
        DispatchQueue.main.async {
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                result(FlutterError(code: "NO_CONTROLLER", message: "找不到根控制器", details: nil))
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: confirmText, style: .default) { _ in
                result(["action": "confirm", "value": true])
            })
            
            if showCancel {
                alert.addAction(UIAlertAction(title: cancelText, style: .cancel) { _ in
                    result(["action": "cancel", "value": false])
                })
            }
            
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - 聊天功能实现
    
    private func processMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let processedMessage: [String: Any] = [
            "original": message,
            "encrypted": message.data(using: .utf8)?.base64EncodedString() ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        result(processedMessage)
    }
    
    private func syncChatData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let messages = args["messages"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        UserDefaults.standard.set(messages, forKey: "chat_messages")
        UserDefaults.standard.synchronize()
        
        result(true)
    }
    
    // MARK: - C++ 数据传输实现
    
    private func generateCppData(result: @escaping FlutterResult) {
        let jsonString = DataTransViewController.generateSimulationDataFromCPP()
        
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            result(json)
        } else {
            result(FlutterError(code: "PARSE_ERROR", message: "解析 C++ 数据失败", details: nil))
        }
    }
    
    private func processCppString(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let input = args["input"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let processed = DataTransViewController.processString(withCPP: input)
        result(processed)
    }
    
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
    
    private func simulateCppDataTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? Int,
              let messageCount = args["messageCount"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let jsonString = DataTransViewController.simulateDataTransfer(withCPP: userId, messageCount: messageCount)
        
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            result(json)
        } else {
            result(FlutterError(code: "PARSE_ERROR", message: "解析 C++ 数据失败", details: nil))
        }
    }
    
    // MARK: - 音频处理
    
    private func mergeAudioFiles(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 音频合并实现
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "音频合并功能待实现", details: nil))
    }
}
