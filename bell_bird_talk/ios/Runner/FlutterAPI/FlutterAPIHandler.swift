//
//  FlutterAPIHandler.swift
//  Runner
//
//  Flutter API 主路由处理器
//  负责将方法调用分发到各个功能模块
//

import Flutter
import Foundation

/// Flutter API 主路由处理器
class FlutterAPIHandler {
    
    // MARK: - 子处理器
    private let deviceHandler = DeviceAPIHandler()
    private let imsdkHandler = IMSDKAPIHandler()
    private let authHandler = AuthAPIHandler()
    private let contactHandler = ContactAPIHandler()
    private let conversationHandler = ConversationAPIHandler()
    private let messageHandler: MessageAPIHandler
    private let groupHandler = GroupAPIHandler()
    private let communityHandler = CommunityAPIHandler()
    private let storageHandler = StorageAPIHandler()
    private let legacyHandler = LegacyMethodsHandler()  // 遗留方法处理器
    
    // MARK: - 初始化
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.messageHandler = MessageAPIHandler(binaryMessenger: binaryMessenger)
    }
    
    // MARK: - 主路由方法
    
    /// 处理 Flutter 方法调用
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        // 根据方法前缀分发到对应的处理器
        if method.hasPrefix("im") || method.hasPrefix("network") {
            routeIMSDKMethod(call, result: result)
        } else {
            routeGeneralMethod(call, result: result)
        }
    }
    
    // MARK: - 路由分发
    
    /// 路由 IMSDK 相关方法
    private func routeIMSDKMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        // IM SDK 基础
        if method.hasPrefix("imInitialize") || method.hasPrefix("imStart") || 
           method.hasPrefix("imStop") || method.hasPrefix("imSetIP") || 
           method.hasPrefix("imGetIP") || method.hasPrefix("imAddTarget") {
            imsdkHandler.handle(call, result: result)
        }
        // 消息管理
        else if method.hasPrefix("imSend") || method.hasPrefix("imPull") ||
                method.hasPrefix("imDeleteMessage") ||
                method.hasPrefix("imRegisterMessageCallbacks") ||
                method.hasPrefix("imUnregisterMessageCallbacks") {
            messageHandler.handle(call, result: result)
        }
        // 认证相关
        else if method.hasPrefix("imRegister") || method.hasPrefix("imLogin") ||
                    method.hasPrefix("networkSetHttpdnsParams") ||
                method.hasPrefix("imLogout") || method.hasPrefix("imGetCaptcha") ||
                method.hasPrefix("imChangePassword") || method.hasPrefix("imResetPassword") ||
                method.hasPrefix("imSearchUser") || method.hasPrefix("imUpdateUser") ||
                method.hasPrefix("imDeactivate") || method.hasPrefix("imGetDeactivate") ||
                method.hasPrefix("imCancelDeactivate") || method.hasPrefix("imGetUsersInfo") ||
                method.hasPrefix("imBatchGetUserPublicInfo") {
            authHandler.handle(call, result: result)
        }
        // 联系人管理
        else if method.hasPrefix("imAddContact") || method.hasPrefix("imDeleteContact") ||
                method.hasPrefix("imBlockContact") || method.hasPrefix("imUnblockContact") ||
                method.hasPrefix("imGetBlackStatus") || method.hasPrefix("imGetContactList") ||
                method.hasPrefix("imSearchContact") || method.hasPrefix("imGetFriendRequests") ||
                method.hasPrefix("imAcceptFriendRequest") || method.hasPrefix("imRejectFriendRequest") ||
                method.hasPrefix("imGetContactGroups") || method.hasPrefix("imCreateContactGroup") ||
                method.hasPrefix("imUpdateContactGroup") || method.hasPrefix("imDeleteContactGroup") ||
                method.hasPrefix("imSetContactRemark") || method.hasPrefix("imMoveContactToGroup") {
            contactHandler.handle(call, result: result)
        }
        // 会话管理
        else if method.hasPrefix("imGetConversation") || method.hasPrefix("imUpdateConversation") ||
                method.hasPrefix("imDeleteConversation") || method.hasPrefix("imMarkConversation") ||
                method.hasPrefix("imClearConversation") || method.hasPrefix("imCreateConversation") ||
                method.hasPrefix("imGetUnreadConversations") || method.hasPrefix("imGetNotification") ||
                method.hasPrefix("imPullNotifications") || method.hasPrefix("imMarkNotification") {
            conversationHandler.handle(call, result: result)
        }
        
        // 群组管理
        else if method.hasPrefix("imCreateGroup") || method.hasPrefix("imGetGroup") ||
                method.hasPrefix("imUpdateGroup") || method.hasPrefix("imDissolveGroup") ||
                method.hasPrefix("imLeaveGroup") || method.hasPrefix("imSetGroupAlias") ||
                method.hasPrefix("imSetGroupDisturb") || method.hasPrefix("imGetGroupDisturb") ||
                method.hasPrefix("imAddGroupMembers") || method.hasPrefix("imRemoveGroupMembers") {
            groupHandler.handle(call, result: result)
        }
        // 社群管理
        else if method.hasPrefix("imGetCommunity") || method.hasPrefix("imJoinCommunity") ||
                    method.hasPrefix("imReviewJoinRequest") ||

                method.hasPrefix("imLeaveCommunity") || method.hasPrefix("imGetChannel") ||
                method.hasPrefix("imCreateChannel") || method.hasPrefix("imUpdateChannel") ||
                method.hasPrefix("imDeleteChannel") || method.hasPrefix("imEnterChannel") ||
                method.hasPrefix("imMuteCommunityMember") || method.hasPrefix("imKickCommunityMember") ||
                method.hasPrefix("imGetCommunitySettings") || method.hasPrefix("imUpdateCommunitySettings") ||
                method.hasPrefix("imListJoinRequests") {
            communityHandler.handle(call, result: result)
        }
        // 文件上传
        else if method.hasPrefix("imPrepareUpload") || method.hasPrefix("imUploadWith") {
            storageHandler.handle(call, result: result)
        }
        else {
            // 未匹配到任何 Handler，使用遗留方法处理器
            print("⚠️ IM方法 '\(method)' 未找到对应的 Handler，使用遗留处理器")
            legacyHandler.handle(call, result: result)
        }
    }
    
    /// 路由通用方法
    private func routeGeneralMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        // 设备相关
        if method.hasPrefix("getDevice") || method.hasPrefix("saveData") ||
           method.hasPrefix("loadData") || method.hasPrefix("getContacts") ||
           method.hasPrefix("openCamera") || method.hasPrefix("sendNotification") ||
           method.hasPrefix("openNativePage") || method.hasPrefix("showAlert") ||
           method.hasPrefix("processMessage") || method.hasPrefix("syncChatData") ||
           method.hasPrefix("generateCppData") || method.hasPrefix("processCppString") ||
           method.hasPrefix("calculateCppStatistics") || method.hasPrefix("simulateCppDataTransfer") ||
           method.hasPrefix("mergeAudioFiles") {
            deviceHandler.handle(call, result: result)
        }
        // 云存储
        else if method.hasPrefix("init") && (method.contains("Aliyun") || method.contains("Tencent") || method.contains("AWS")) ||
                method.hasPrefix("upload") || method.hasPrefix("downloadFile") {
            storageHandler.handle(call, result: result)
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
}
