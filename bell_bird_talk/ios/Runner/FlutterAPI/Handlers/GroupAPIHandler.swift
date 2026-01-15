//
//  GroupAPIHandler.swift
//  Runner
//
//  群组管理 API 处理器
//  包括：创建群组、群组信息、成员管理等
//

import Flutter
import Foundation

class GroupAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "imCreateGroup":
            imCreateGroup(call: call, result: result)
        case "imGetGroupList":
            imGetGroupList(call: call, result: result)
        case "imGetGroupMembers":
            imGetGroupMembers(call: call, result: result)
        case "imGetGroupInfo":
            imGetGroupInfo(call: call, result: result)
        case "imGetGroupPreview":
            imGetGroupPreview(call: call, result: result)
        case "imUpdateGroup":
            imUpdateGroup(call: call, result: result)
        case "imSetGroupAlias":
            imSetGroupAlias(call: call, result: result)
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
        default:
            result(FlutterMethodNotImplemented)
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
            print("AppDeleate 创建群聊回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    /// 获取群组成员列表
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
    
    /// 获取群组信息
    private func imGetGroupInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        print("📋 获取群组信息: groupId=\(groupId)")
        
        let code = IMSDKGroupManager.shared().getGroupInfo(withId: groupId, completion: { errorCode, reqId, data in
            print("📋 获取群组信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_INFO_ERROR",
                                message: "获取群组信息请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 获取群组预览信息
    private func imGetGroupPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let groupId = args["group_id"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 group_id", details: nil))
            return
        }
        
        let code = IMSDKGroupManager.shared().getGroupPerview(withId: groupId, completion: { errorCode, reqId, data in
            print("📁 获取群信息回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "获取成功" : "获取失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "GET_GROUP_INFO_ERROR",
                                message: "获取群信息请求发送失败: \(code)",
                                details: nil))
        }
    }
    
    /// 更新群组信息
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
    
    /// 设置群组别名
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
        
        let userId = args["user_id"] as? String
        let code = IMSDKGroupManager.shared().getGroupDisturbStatus(withGroupId: groupId, userId: userId!) { errorCode, reqId, data in
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
        
        print("📁 移除群组成员: groupId=\(groupId), userIds=\(userIds), reason=\(reason ?? "")")
        
        let code = IMSDKGroupManager.shared().removeGroupMembers(withGroupId: groupId, userIds: userIds, reason: reason, completion: { errorCode, reqId, data in
            print("📁 移除群组成员回调: errorCode=\(errorCode), reqId=\(reqId)")
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": errorCode == 0 ? "移除成功" : "移除失败",
                "data": data ?? ""
            ])
        })
        
        if code != 0 {
            result(FlutterError(code: "REMOVE_GROUP_MEMBERS_ERROR",
                                message: "移除群组成员请求发送失败: \(code)",
                                details: nil))
        }
    }
}
