//
//  ConversationAPIHandler.swift
//  Runner
//
//  会话管理 API 处理器
//  包括：会话列表、会话操作、通知管理等
//

import Flutter
import Foundation

class ConversationAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
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
        case "imDeleteConversation":
            imDeleteConversation(call: call, result: result)
        case "imMarkConversationRead":
            imMarkConversationRead(call: call, result: result)
        case "imClearConversationMessages":
            imClearConversationMessages(call: call, result: result)
        case "imGetNotificationUnreadCount":
            imGetNotificationUnreadCount(call: call, result: result)
        case "imPullNotifications":
            imPullNotifications(call: call, result: result)
        case "imMarkNotificationRead":
            imMarkNotificationRead(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 会话管理
    
    /// 获取会话列表
    private func imGetConversationList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        let convType = args["conv_type"] as? Int ?? -1
        let isAtMe = args["is_at_me"] as? Bool ?? false
        let isUnread = args["is_unread"] as? Bool ?? false
        
        var code = 0;
        if isAtMe || isUnread {
            code = Int(IMSDKConversationManager.shared().getConversationATUnreadList(withPage: Int32(page), pageSize: Int32(pageSize), convType: IMConversationType(rawValue: convType) ?? IMConversationType.all, atMe: isAtMe, completion: { errorCode, reqId, data in
                print("AppDeleate 会话列表回调: errorCode=\(errorCode), reqId=\(reqId)")
                
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "获取成功" : "获取失败",
                    "data": data ?? ""
                ])
            }))
        } else {
            code = Int(IMSDKConversationManager.shared().getConversationList(withPage: Int32(page), pageSize: Int32(pageSize), convType: IMConversationType(rawValue: convType) ?? IMConversationType.all, atMe: isAtMe, completion: { errorCode, reqId, data in
                print("AppDeleate 会话列表回调: errorCode=\(errorCode), reqId=\(reqId)")
                
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "获取成功" : "获取失败",
                    "data": data ?? ""
                ])
            }))
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
            print("AppDeleate 获取会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 获取未读会话列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 更新会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 创建会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 删除会话回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
              let msgIds = args["msgIds"] as? String,
              let convId = args["conv_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let code = IMSDKConversationManager.shared().markConversationRead(withId: convId, msgIds: msgIds, completion:{ errorCode, reqId, data in
            print("AppDeleate 标记已读回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "标记成功" : "标记失败",
                "data": data ?? ""
            ])
        })
        
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
            print("AppDeleate 清空消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
        let state = args["state"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 20
        let code = IMSDKMessageManager.shared().pullNotifications(withTypes: types, page: Int32(page),state: Int32(state), pageSize: Int32(pageSize)) { errorCode, reqId, data in
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
}
