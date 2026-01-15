//
//  MessageAPIHandler.swift
//  Runner
//
//  消息管理 API 处理器
//  包括：发送消息、拉取消息、删除消息、消息回调等
//

import Flutter
import Foundation

class MessageAPIHandler {
    private weak var binaryMessenger: FlutterBinaryMessenger?
    
    init(binaryMessenger: FlutterBinaryMessenger?) {
        self.binaryMessenger = binaryMessenger
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "imDeleteMessage":
            imDeleteMessage(call: call, result: result)
        case "imSendTextMessage":
            imSendTextMessage(call: call, result: result)
        case "imSendImageMessage":
            imSendImageMessage(call: call, result: result)
        case "imSendVideoMessage":
            imSendVideoMessage(call: call, result: result)
        case "imSendVoiceMessage":
            imSendVoiceMessage(call: call, result: result)
        case "imSendChannelMessage":
            imSendChannelMessage(call: call, result: result)
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 消息管理
    
    /// 删除消息
    private func imDeleteMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Implement message deletion
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "删除消息功能待实现", details: nil))
    }
    
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
            print("AppDeleate 发送消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    /// 发送频道文本消息（频道发言）
    private func imSendChannelMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let content = args["content"] as? String,
              let cid = args["cid"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        let ext = args["ext"] as? String
        let code = IMSDKMessageManager.shared().sendChannelMessage(
            content,
            ext: ext,
            cmtyId: cid
        ) { errorCode, reqId, data in
            print("AppDeleate 发送频道消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "发送成功" : "发送失败",
                "data": data ?? ""
            ])
        }
        
        if code != 0 {
            result(FlutterError(code: "SEND_CHANNEL_MESSAGE_ERROR",
                              message: "发送频道消息请求失败: \(code)",
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
            print("AppDeleate 发送图片消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送语音消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送视频消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 拉取消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送群聊消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送群聊图片消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送群聊语音消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送群聊视频消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 发送群聊@消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 拉取群聊消息回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
}
