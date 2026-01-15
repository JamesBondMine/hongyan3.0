//
//  AuthAPIHandler.swift
//  Runner
//
//  认证相关 API 处理器
//  包括：注册、登录、登出、密码管理、用户信息等
//

import Flutter
import Foundation

class AuthAPIHandler {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // 认证相关
        case "imRegister":
            imRegister(call: call, result: result)
        case "imGetCaptcha":
            imGetCaptcha(call: call, result: result)
        case "imLogin":
            imLogin(call: call, result: result)
        case "imSearchUser":
            imSearchUser(call: call, result: result)
        case "imLogout":
            imLogout(call: call, result: result)
        // 账户管理
        case "imDeactivateAccount":
            imDeactivateAccount(call: call, result: result)
        case "imGetDeactivateStatus":
            imGetDeactivateStatus(call: call, result: result)
        case "imCancelDeactivateAccount":
            imCancelDeactivateAccount(call: call, result: result)
        // 密码管理
        case "imChangePassword":
            imChangePassword(call: call, result: result)
        case "imResetPassword":
            imResetPassword(call: call, result: result)
        // 用户信息
        case "imUpdateUserInfo":
            imUpdateUserInfo(call: call, result: result)
        case "imGetUsersInfo":
            imGetUsersInfo(call: call, result: result)
        case "imBatchGetUserPublicInfo":
            imBatchGetUserPublicInfo(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 认证相关
    
    /// 用户注册
    private func imRegister(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        print("📝 注册请求: \(args)")
        
        // 调用 IMSDKAuthManager 注册（使用 protobuf）
        let code = IMSDKAuthManager.shared().register(with: args) { errorCode, reqId, data in
            print("AppDeleate 注册回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            
        default:
            // 兼容旧的 userId + token 方式
            if let userId = args["userId"] as? String, let token = args["token"] as? String {
                let code = IMSDKAuthManager.shared().login(withUserId: userId, token: token) { errorCode, reqId, data in
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
            print("AppDeleate 用户搜索回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    /// 退出登录
    private func imLogout(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🚪 Flutter调用退出登录")
        let args = call.arguments as? [String: Any] ?? [:]
        let userId = args["user_id"] as? String
        let clientIp = args["client_ip"] as? String
        let reason = args["reason"] as? NSNumber
        
        let reqId = IMSDKUserManager.shared().logout(withUserId: userId, clientIp: clientIp, reason: reason) { errorCode, message, data, reqId in
            print("AppDeleate 退出登录回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    // MARK: - 账户管理
    
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
            print("AppDeleate 注销用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    /// 撤回注销用户
    private func imCancelDeactivateAccount(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
            return
        }
        
        guard let userId = args["user_id"] as? String, !userId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "user_id 不能为空", details: nil))
            return
        }
        
        print("🔄 撤回注销用户: userId=\(userId)")
        
        let reqId = IMSDKUserManager.shared().cancelDeactivateAccount(withUserId: userId, completion: { errorCode, message, data, reqId in
            print("AppDeleate 撤回注销用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            result(FlutterError(code: "CANCEL_DEACTIVATE_ACCOUNT_ERROR",
                              message: "撤回注销用户请求失败",
                              details: nil))
        }
    }
    
    // MARK: - 密码管理
    
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
            print("AppDeleate 修改密码回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
            print("AppDeleate 重置密码回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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
    
    // MARK: - 用户信息
    
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
        // 构建用户信息字典
        var userInfo: [String: Any] = [:]
        
        if let userId = args["user_id"] as? String {
            userInfo["user_id"] = userId
        }
        if let nickname = args["nickname"] as? String {
            userInfo["nickname"] = nickname
        }
        if let username = args["username"] as? String {
            userInfo["username"] = username
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
            print("AppDeleate 更新用户回调: errorCode=\(errorCode), reqId=\(reqId)")
            
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

    /// 批量获取用户公开信息
    private func imBatchGetUserPublicInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userIds = args["user_ids"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "参数错误，缺少 user_ids", details: nil))
            return
        }
        
        print("👤 批量获取用户公开信息: userIds=\(userIds)")
        
        let reqId = IMSDKUserManager.shared().batchGetUserPublicInfo(withUserIds: userIds) { errorCode, message, data, reqId in
            var dataStr = "[]"
            if let data = data, let usersValue = data["users"] {
                // 处理 NSArray 或 Array 类型
                var usersArray: Any?
                
                if let nsArray = usersValue as? NSArray {
                    // 将 NSArray 转换为 Swift Array
                    usersArray = nsArray as? [[String: Any]] ?? nsArray
                } else if let swiftArray = usersValue as? [[String: Any]] {
                    usersArray = swiftArray
                } else if let anyArray = usersValue as? [Any] {
                    usersArray = anyArray
                }
                
                if let array = usersArray {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            dataStr = jsonString
                        }
                    } catch {
                        print("❌ JSON 序列化失败: \(error)")
                        dataStr = "[]"
                    }
                } else {
                    print("⚠️ users 数据格式不正确: \(type(of: usersValue))")
                }
            } else {
                print("⚠️ 未找到 users 字段")
            }
            
            result([
                "errorCode": errorCode,
                "reqId": reqId,
                "message": message ?? (errorCode == 0 ? "获取成功" : "获取失败"),
                "data": dataStr
            ])
        }
        
        if reqId == 0 {
            result(FlutterError(code: "BATCH_GET_USER_PUBLIC_INFO_ERROR",
                              message: "批量获取用户公开信息请求发送失败",
                              details: nil))
        }
    }
}
