//
//  CommunityAPIHandler.swift
//  Runner
//
//  社群管理 API 处理器
//  包括：社群列表、加入/离开社群、频道管理、成员管理等
//

import Flutter
import Foundation

class CommunityAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // 社群查询
        case "imGetCommunityList":
            getCommunityList(call: call, result: result)
        case "imJoinCommunity":
            joinCommunity(call: call, result: result)
        case "imLeaveCommunity":
            leaveCommunity(call: call, result: result)
        case "imGetCommunityInfo":
            getCommunityInfo(call: call, result: result)
            
        // 分组和频道
        case "imGetCommunityGroups":
            getCommunityGroups(call: call, result: result)
        case "imGetChannels":
            getChannels(call: call, result: result)
        case "imCreateChannel":
            createChannel(call: call, result: result)
        case "imUpdateChannel":
            updateChannel(call: call, result: result)
        case "imDeleteChannel":
            deleteChannel(call: call, result: result)
        case "imEnterChannel":
            enterChannel(call: call, result: result)
        case "imCreateChannelGroup":
            createChannelGroup(call: call, result: result)
        case "imUpdateChannelGroup":
            updateChannelGroup(call: call, result: result)
        case "imDeleteChannelGroup":
            deleteChannelGroup(call: call, result: result)
            
        // 成员管理
        case "imGetCommunityMembers":
            getCommunityMembers(call: call, result: result)
        case "imGetCommunityBannedMembers":
            getCommunityBannedMembers(call: call, result: result)
        case "imMuteCommunityMember":
            muteCommunityMember(call: call, result: result)
        case "imKickCommunityMember":
            kickCommunityMember(call: call, result: result)
        case "imGetCommunitySettings":
            getCommunitySettings(call: call, result: result)
        case "imUpdateCommunitySettings":
            updateCommunitySettings(call: call, result: result)
        case "imListJoinRequests":
            listJoinRequests(call: call, result: result)
        case "imReviewJoinRequest":
            reviewJoinRequest(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 社群查询
    
    private func getCommunityList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let page = args["page"] as? Int ?? 1
        let pageSize = args["pageSize"] as? Int ?? 20
        
        print("📁 获取社群列表: page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKCommunityManager.shared().getCommunityList(withPage: Int32(page), pageSize: Int32(pageSize), completion: { errorCode, reqId, data in
            print("📁 获取社群列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_LIST_ERROR",
                              message: "获取社群列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func joinCommunity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        print("📁 加入社群: cmtyId=\(cmtyId)")
        
        let code = IMSDKCommunityManager.shared().joinCommunity(withCmtyId: cmtyId, completion: { errorCode, reqId, data in
            print("📁 加入社群回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "加入成功" : "加入失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "JOIN_COMMUNITY_ERROR",
                              message: "加入社群请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func leaveCommunity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        print("📁 离开社群: cmtyId=\(cmtyId)")
        
        let code = IMSDKCommunityManager.shared().leaveCommunity(withCmtyId: cmtyId, completion: { errorCode, reqId, data in
            print("📁 离开社群回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "离开成功" : "离开失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "LEAVE_COMMUNITY_ERROR",
                              message: "离开社群请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func getCommunityInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        print("📁 获取社群信息: cmtyId=\(cmtyId)")
        
        let code = IMSDKCommunityManager.shared().getCommunityInfo(withCmtyId: cmtyId, completion: { errorCode, reqId, data in
            print("📁 获取社群信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_INFO_ERROR",
                              message: "获取社群信息请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 分组和频道
    
    private func getCommunityGroups(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().getCommunityGroups(withCmtyId: cmtyId, completion: { errorCode, reqId, data in
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_GROUPS_ERROR",
                              message: "获取分组列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func getChannels(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().getChannelsWithCmtyId(cmtyId, completion: { errorCode, reqId, data in
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_CHANNELS_ERROR",
                              message: "获取频道列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func createChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let categoryId = args["categoryId"] as? String ?? ""
        let channelName = args["channelName"] as? String ?? ""
        let channelType = args["channelType"] as? Int ?? 0
        let description = args["description"] as? String
        let maxMembers = args["maxMembers"] as? Int ?? 50
        
        let code = IMSDKCommunityManager.shared().createChannel(
            withCmtyId: cmtyId,
            categoryId: categoryId,
            channelName: channelName,
            channelType: Int32(channelType),
            description: description,
            maxMembers: Int32(maxMembers),
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "创建成功" : "创建失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "CREATE_CHANNEL_ERROR",
                              message: "创建频道请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func updateChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let channelId = args["channelId"] as? String ?? ""
        let channelName = args["channelName"] as? String
        let pauseInvite = args["pauseInvite"] as? Bool ?? false
        let muteAll = args["muteAll"] as? Bool ?? false
        let notificationType = args["notificationType"] as? Int ?? 0
        
        let code = IMSDKCommunityManager.shared().updateChannel(
            withChannelId: channelId,
            channelName: channelName,
            pauseInvite: pauseInvite,
            muteAll: muteAll,
            notificationType: Int32(notificationType),
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "更新成功" : "更新失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_CHANNEL_ERROR",
                              message: "更新频道请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func deleteChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let channelId = args["channelId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().deleteChannel(withChannelId: channelId, completion: { errorCode, reqId, data in
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "删除成功" : "删除失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "DELETE_CHANNEL_ERROR",
                              message: "删除频道请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func enterChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let channelId = args["channelId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().enterChannel(withChannelId: channelId, completion: { errorCode, reqId, data in
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "进入成功" : "进入失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "ENTER_CHANNEL_ERROR",
                              message: "进入频道请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func createChannelGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let categoryName = args["categoryName"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().createChannelGroup(
            withCmtyId: cmtyId,
            categoryName: categoryName,
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "创建成功" : "创建失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "CREATE_CHANNEL_GROUP_ERROR",
                              message: "创建分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func updateChannelGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let categoryId = args["categoryId"] as? String ?? ""
        let categoryName = args["categoryName"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().updateChannelGroup(
            withCmtyId: cmtyId,
            categoryId: categoryId,
            categoryName: categoryName,
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "更新成功" : "更新失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_CHANNEL_GROUP_ERROR",
                              message: "更新分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func deleteChannelGroup(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let categoryId = args["categoryId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().deleteChannelGroup(
            withCmtyId: cmtyId,
            categoryId: categoryId,
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "删除成功" : "删除失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "DELETE_CHANNEL_GROUP_ERROR",
                              message: "删除分组请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    // MARK: - 成员管理
    
    private func getCommunityMembers(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let page = args["page"] as? Int ?? 1
        let pageSize = args["pageSize"] as? Int ?? 20
        
        let code = IMSDKCommunityManager.shared().getCommunityMembers(
            withCmtyId: cmtyId,
            page: Int32(page),
            pageSize: Int32(pageSize),
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "获取成功" : "获取失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_MEMBERS_ERROR",
                              message: "获取社群成员列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func getCommunityBannedMembers(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let page = args["page"] as? Int ?? 1
        let pageSize = args["pageSize"] as? Int ?? 20
        
        print("📁 获取社群封禁成员列表: cmtyId=\(cmtyId), page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKCommunityManager.shared().getCommunityBannedMembers(
            withCmtyId: cmtyId,
            page: Int32(page),
            pageSize: Int32(pageSize),
            completion: { errorCode, reqId, data in
                print("📁 获取社群封禁成员列表回调: errorCode=\(errorCode), reqId=\(reqId)")
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "获取成功" : "获取失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_BANNED_MEMBERS_ERROR",
                              message: "获取社群封禁成员列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func muteCommunityMember(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let userId = args["userId"] as? String ?? ""
        let mute = args["mute"] as? Bool ?? true
        let muteUntil = args["muteUntil"] as? Int64 ?? 0
        
        let code = IMSDKCommunityManager.shared().muteCommunityMember(
            withCmtyId: cmtyId,
            userId: userId,
            mute: mute,
            muteUntil: muteUntil,
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "操作成功" : "操作失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "MUTE_COMMUNITY_MEMBER_ERROR",
                              message: "禁言社群成员请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func kickCommunityMember(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let userId = args["userId"] as? String ?? ""
        
        let code = IMSDKCommunityManager.shared().kickCommunityMember(
            withCmtyId: cmtyId,
            userId: userId,
            completion: { errorCode, reqId, data in
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "踢出成功" : "踢出失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "KICK_COMMUNITY_MEMBER_ERROR",
                              message: "踢出社群成员请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func getCommunitySettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        
        print("⚙️ 获取社群设置: cmtyId=\(cmtyId)")
        
        let code = IMSDKCommunityManager.shared().getCommunitySettings(
            withCmtyId: cmtyId,
            completion: { errorCode, reqId, data in
                print("⚙️ 获取社群设置回调: errorCode=\(errorCode), reqId=\(reqId)")
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "获取成功" : "获取失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "GET_COMMUNITY_SETTINGS_ERROR",
                              message: "获取社群设置请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func updateCommunitySettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let settings = args["settings"] as? [String: Any] ?? [:]
        
        print("⚙️ 更新社群设置: cmtyId=\(cmtyId)")
        
        // 将 Swift Dictionary 转换为 NSDictionary
        let settingsDict = settings as NSDictionary
        
        let code = IMSDKCommunityManager.shared().updateCommunitySettings(
            withCmtyId: cmtyId,
            settings: settingsDict as! [String : Any],
            completion: { errorCode, reqId, data in
                print("⚙️ 更新社群设置回调: errorCode=\(errorCode), reqId=\(reqId)")
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "更新成功" : "更新失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "UPDATE_COMMUNITY_SETTINGS_ERROR",
                              message: "更新社群设置请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func listJoinRequests(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let status = args["status"] as? Int ?? 0
        let page = args["page"] as? Int ?? 1
        let pageSize = args["pageSize"] as? Int ?? 20
        
        print("📋 查询加入申请列表: cmtyId=\(cmtyId), status=\(status), page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKCommunityManager.shared().listJoinRequests(
            withCmtyId: cmtyId,
            status: Int32(status),
            page: Int32(page),
            pageSize: Int32(pageSize),
            completion: { errorCode, reqId, data in
                print("📋 查询加入申请列表回调: errorCode=\(errorCode), reqId=\(reqId)")
                result([
                    "errorCode": errorCode,
                    "reqId": reqId,
                    "message": errorCode == 0 ? "查询成功" : "查询失败",
                    "data": data ?? ""
                ])
            })
        
        if code != 0 {
            result(FlutterError(code: "LIST_JOIN_REQUESTS_ERROR",
                              message: "查询加入申请列表请求发送失败: \(code)",
                              details: nil))
        }
    }
    
    private func reviewJoinRequest(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let cmtyId = args["cmtyId"] as? String ?? ""
        let requestId = args["requestId"] as? Int ?? 0
        let approve = args["approve"] as? Bool ?? false
        let reviewMessage = args["reviewMessage"] as? String ?? ""
        print("\(approve ? "✅" : "❌") 审核加入申请: cmtyId=\(cmtyId), requestId=\(requestId), approve=\(approve), reviewMessage=\(reviewMessage)")
        let code: Int32
        if approve {
            code = IMSDKCommunityManager.shared().approveJoinRequest(
                withCmtyId: cmtyId,
                requestId: Int64(requestId),
                reviewMessage: reviewMessage.isEmpty ? nil : reviewMessage,
                completion: { errorCode, reqId, data in
                    print("\(approve ? "✅" : "❌") 审核加入申请回调: errorCode=\(errorCode), reqId=\(reqId)")
                    result([
                        "errorCode": errorCode,
                        "reqId": reqId,
                        "message": errorCode == 0 ? "审核成功" : "审核失败",
                        "data": data ?? ""
                    ])
                })
        } else {
            code = IMSDKCommunityManager.shared().rejectJoinRequest(
                withCmtyId: cmtyId,
                requestId: Int64(requestId),
                reviewMessage: reviewMessage.isEmpty ? nil : reviewMessage,
                completion: { errorCode, reqId, data in
                    print("\(approve ? "✅" : "❌") 审核加入申请回调: errorCode=\(errorCode), reqId=\(reqId)")
                    result([
                        "errorCode": errorCode,
                        "reqId": reqId,
                        "message": errorCode == 0 ? "审核成功" : "审核失败",
                        "data": data ?? ""
                    ])
                })
        }
        
        if code != 0 {
            result(FlutterError(code: "REVIEW_JOIN_REQUEST_ERROR",
                              message: "审核加入申请请求发送失败: \(code)",
                              details: nil))
        }
    }
}
