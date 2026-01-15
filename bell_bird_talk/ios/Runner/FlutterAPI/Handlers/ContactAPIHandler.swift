//
//  ContactAPIHandler.swift
//  Runner
//
//  联系人管理 API 处理器
//  包括：添加/删除联系人、黑名单、好友申请、分组管理等
//

import Flutter
import Foundation

class ContactAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // 联系人管理
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
        // 好友申请
        case "imGetFriendRequests":
            imGetFriendRequests(call: call, result: result)
        case "imAcceptFriendRequest":
            imAcceptFriendRequest(call: call, result: result)
        case "imRejectFriendRequest":
            imRejectFriendRequest(call: call, result: result)
        // 联系人分组
        case "imGetContactGroups":
            imGetContactGroups(call: call, result: result)
        case "imCreateContactGroup":
            imCreateContactGroup(call: call, result: result)
        case "imUpdateContactGroup":
            imUpdateContactGroup(call: call, result: result)
        case "imDeleteContactGroup":
            imDeleteContactGroup(call: call, result: result)
        // 联系人操作
        case "imSetContactRemark":
            imSetContactRemark(call: call, result: result)
        case "imMoveContactToGroup":
            imMoveContactToGroup(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
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
        let code = IMSDKContactManager.shared().addContact(withParams: args) { errorCode, reqId, data in
            print("AppDeleate 添加联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 删除联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 拉黑用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
        
        print("AppDeleate 取消拉黑用户: \(userId)")
        
        let code = IMSDKContactManager.shared().unblockContact(withUserId: userId) { errorCode, reqId, data in
            print("AppDeleate 取消拉黑回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 联系人列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 搜索联系人回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 好友申请列表回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
        
        print("AppDeleate 同意好友申请: requestId=\(requestId)")
        
        let code = IMSDKContactManager.shared().acceptFriendRequest(withId: Int64(requestId)) { errorCode, reqId, data in
            print("AppDeleate 同意申请回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 拒绝申请回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    // MARK: - 联系人分组
    
    /// 获取联系人分组列表
    private func imGetContactGroups(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        let page = args["page"] as? Int ?? 1
        let pageSize = args["page_size"] as? Int ?? 100
        
        print("📁 获取联系人分组列表: page=\(page), pageSize=\(pageSize)")
        
        let code = IMSDKContactManager.shared().getContactGroups(withPage: Int32(page), pageSize: Int32(pageSize)) { errorCode, reqId, data in
            print("AppDeleate 联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
        let friendIds = args["friend_ids"] as? [String]
        
        print("📁 创建联系人分组: groupName=\(groupName), friendIds=\(friendIds ?? [])")
        
        let code = IMSDKContactManager.shared().createContactGroup(withName: groupName, groupColor: groupColor, groupOrder: groupOrder, groupIcon: groupIcon, groupDescription: groupDescription, userIds: friendIds, completion: { errorCode, reqId, data in
            print("AppDeleate 创建联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 更新联系人分组回调: errorCode=\(errorCode), reqId=\(reqId)")
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
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📁 删除联系人分组: groupId=\(groupId)")
        
        let code = IMSDKContactManager.shared().deleteContactGroup(withId: groupId) { errorCode, reqId, data in
            print("AppDeleate 删除分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    // MARK: - 联系人操作
    
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
            print("AppDeleate 设置备注回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 移动联系人到分组回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
}
