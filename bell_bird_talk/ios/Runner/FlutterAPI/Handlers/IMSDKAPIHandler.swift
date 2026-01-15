//
//  IMSDKAPIHandler.swift
//  Runner
//
//  IM SDK 基础 API 处理器
//  包括：初始化、启动、停止、网络配置等
//

import Flutter
import Foundation

class IMSDKAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func imInitialize(result: @escaping FlutterResult) {
        let code = IMSDKManager.shared().initSDK(withConfig: "{\"platform\":\"iOS\"}")
        result(code == 0 ? true : false)
    }
    
    private func imStart(result: @escaping FlutterResult) {
        let code = IMSDKManager.shared().startNetwork()
        result(code == 0 ? true : false)
    }
    
    private func imStartNetCheck(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let code = IMSDKManager.shared().startNetworkCheck(withURL: url)
        result(code == 0 ? true : false)
    }
    
    private func imSetIPTable(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let ips = args["ips"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        IMSDKManager.shared().setIPTable(ips)
        result(true)
    }
    
    private func imGetIPStatus(result: @escaping FlutterResult) {
        let latencies = IMSDKManager.shared().getIPStatus()
        result(latencies)
    }
    
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
    
    private func imStop(result: @escaping FlutterResult) {
        IMSDKManager.shared().stopNetwork()
        result(true)
    }
}
