//
//  IMSDKUserManager.mm
//  Runner
//
//  用户信息管理实现
//

#import "IMSDKUserManager.h"
#import "network_lib.h"
#import "UserPb.pbobjc.h"
#import <UIKit/UIKit.h>

// 存储回调的字典
static NSMutableDictionary<NSNumber *, IMSDKUserCompletion> *g_userCallbacks = nil;
// 存储 operationID 到 reqId 的映射（用于 get_users_info）
static NSMutableDictionary<NSString *, NSNumber *> *g_operationIdToReqId = nil;


// 注销用户回调
void DeleteUserCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 注销用户回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // 立即拷贝数据
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKUserCompletion completion = g_userCallbacks[@(reqId)];
        if (!completion) {
            NSLog(@"⚠️ 未找到回调: reqId=%llu", reqId);
            return;
        }
        
        [g_userCallbacks removeObjectForKey:@(reqId)];
        
        if (errorCode != 0) {
            NSString *errorMsg = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"注销失败";
            completion(errorCode, errorMsg, nil, reqId);
            return;
        }
        
        // 解析返回的数据
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        
        if (responseData && responseData.length > 0) {
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (responseStr) {
                result[@"message"] = responseStr;
            }
        }
        
        NSLog(@"✅ 注销用户成功");
        completion(0, @"注销成功", result, reqId);
    });
}


// 更新用户信息回调
void UpdateUserCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 更新用户回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // 立即拷贝数据
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKUserCompletion completion = g_userCallbacks[@(reqId)];
        if (!completion) {
            NSLog(@"⚠️ 未找到回调: reqId=%llu", reqId);
            return;
        }
        
        [g_userCallbacks removeObjectForKey:@(reqId)];
        
        if (errorCode != 0) {
            NSString *errorMsg = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"更新失败";
            completion(errorCode, errorMsg, nil, reqId);
            return;
        }
        
        // 解析返回的用户信息
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        
        if (responseData && responseData.length > 0) {
            NSError *error = nil;
            User *user = [User parseFromData:responseData error:&error];
            
            if (user && !error) {
                result[@"user_id"] = user.userId ?: @"";
                result[@"nickname"] = user.nickname ?: @"";
                result[@"sex"] = @(user.sex);
                result[@"signature"] = user.signature ?: @"";
                result[@"avatar"] = user.avatar ?: @"";
                result[@"region"] = user.region ?: @"";
                result[@"phone"] = user.phone ?: @"";
                result[@"email"] = user.email ?: @"";
                
                NSLog(@"✅ 更新用户成功: nickname=%@", user.nickname);
            } else {
                NSLog(@"⚠️ 解析用户信息失败: %@", error);
            }
        }
        
        completion(0, @"更新成功", result, reqId);
    });
}

@implementation IMSDKUserManager

+ (instancetype)shared {
    static IMSDKUserManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKUserManager alloc] init];
        g_userCallbacks = [NSMutableDictionary dictionary];
        g_operationIdToReqId = [NSMutableDictionary dictionary];
    });
    return instance;
}

- (uint64_t)updateUserWithInfo:(NSDictionary *)userInfo
                    completion:(IMSDKUserCompletion)completion {
    NSLog(@"📤 更新用户信息: %@", userInfo);
    
    // 创建 UpdateUser 对象
    UpdateUser *updateUser = [[UpdateUser alloc] init];
    
    // 用户ID (可选，SDK 内部会自动从 MqttSession 中获取)
    if (userInfo[@"user_id"]) {
//        updateUser.userId = userInfo[@"user_id"];
    }
    
    // 设置要更新的字段
    if (userInfo[@"nickname"]) {
        updateUser.nickname = userInfo[@"nickname"];
    }
    if (userInfo[@"sex"]) {
        updateUser.sex = (UserSex)[userInfo[@"sex"] intValue];
    }
    if (userInfo[@"signature"]) {
        updateUser.signature = userInfo[@"signature"];
    }
    if (userInfo[@"avatar"]) {
        updateUser.avatar = userInfo[@"avatar"];
    }
    if (userInfo[@"region"]) {
        updateUser.region = userInfo[@"region"];
    }
    if (userInfo[@"background_file"]) {
        updateUser.backgroundFile = userInfo[@"background_file"];
    }
    if (userInfo[@"phone"]) {
        updateUser.phone = userInfo[@"phone"];
    }
    if (userInfo[@"email"]) {
        updateUser.email = userInfo[@"email"];
    }
    
    // 序列化
    NSData *serializedData = [updateUser data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化用户数据失败");
        if (completion) {
            completion(-2, @"序列化失败", nil, 0);
        }
        return 0;
    }
    
    NSLog(@"📦 序列化成功: %lu 字节", (unsigned long)serializedData.length);
    
    // 保存回调
    uint64_t reqId = 0;
    int result = update_user(UpdateUserCallback,
                             (const char *)serializedData.bytes,
                             (int)serializedData.length,
                             reqId);
    
    if (result == 0 && reqId > 0) {
        if (completion) {
            g_userCallbacks[@(reqId)] = [completion copy];
        }
        NSLog(@"✅ 更新用户请求已发送: reqId=%llu", reqId);
    } else {
        NSLog(@"❌ 更新用户请求失败: result=%d", result);
        if (completion) {
            completion(result, @"发送请求失败", nil, 0);
        }
    }
    
    return reqId;
}

- (uint64_t)updateNickname:(NSString *)nickname
                completion:(IMSDKUserCompletion)completion {
    return [self updateUserWithInfo:@{@"nickname": nickname} completion:completion];
}

- (uint64_t)updateSignature:(NSString *)signature
                 completion:(IMSDKUserCompletion)completion {
    return [self updateUserWithInfo:@{@"signature": signature} completion:completion];
}

- (uint64_t)updateSex:(int)sex
           completion:(IMSDKUserCompletion)completion {
    return [self updateUserWithInfo:@{@"sex": @(sex)} completion:completion];
}

- (uint64_t)updateAvatar:(NSString *)avatarUrl
              completion:(IMSDKUserCompletion)completion {
    return [self updateUserWithInfo:@{@"avatar": avatarUrl} completion:completion];
}

#pragma mark - 退出登录

// 退出登录回调
static void LogoutCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 退出登录回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKUserCompletion completion = g_userCallbacks[@(reqId)];
        if (!completion) {
            NSLog(@"⚠️ 未找到退出登录回调: reqId=%llu", reqId);
            return;
        }
        
        [g_userCallbacks removeObjectForKey:@(reqId)];
        
        if (errorCode != 0) {
            NSString *errorMsg = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"退出登录失败";
            completion(errorCode, errorMsg, nil, reqId);
            return;
        }
        
        NSLog(@"✅ 退出登录成功");
        completion(0, @"退出登录成功", @{}, reqId);
    });
}

- (uint64_t)logoutWithUserId:(NSString * _Nullable)userId
                    clientIp:(NSString * _Nullable)clientIp
                      reason:(NSNumber * _Nullable)reason
                  completion:(IMSDKUserCompletion)completion {
    NSLog(@"🚪 开始退出登录...");
    
    Logout *lo = [[Logout alloc] init];
    if (userId && userId.length > 0) {
        lo.userId = userId;
    }
    if (clientIp && clientIp.length > 0) {
        lo.clientIp = clientIp;
    }
    if (reason != nil) {
        lo.reason = (LogoutReason)[reason intValue];
    }
    
    NSData *protoBody = [lo data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ 退出登录 Protobuf 序列化失败");
        if (completion) {
            completion(-1, @"序列化失败", nil, 0);
        }
        return 0;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    
    uint64_t reqId = 0;
    int result = logout(LogoutCallback, data, dataLen, reqId);
    
    if (result == 0 && reqId > 0) {
        if (completion) {
            g_userCallbacks[@(reqId)] = [completion copy];
        }
        NSLog(@"✅ 退出登录请求已发送: reqId=%llu", reqId);
    } else {
        NSLog(@"❌ 退出登录请求失败: result=%d", result);
        if (completion) {
            completion(result, @"发送退出请求失败", nil, 0);
        }
    }
    
    return reqId;
}

- (uint64_t)logoutWithCompletion:(IMSDKUserCompletion)completion {
    return [self logoutWithUserId:nil clientIp:nil reason:nil completion:completion];
}



- (uint64_t)deactivateAccountWithUserId:(NSString *)userId
                                  reason:(NSString *)reason
                              completion:(IMSDKUserCompletion)completion {
    NSLog(@"📤 注销用户: userId=%@, reason=%@", userId ?: @"无", reason ?: @"无");
    
    // 验证 userId
    if (!userId || userId.length == 0) {
        NSLog(@"❌ userId 不能为空");
        if (completion) {
            completion(-1, @"userId 不能为空", nil, 0);
        }
        return 0;
    }
    
    // 创建 DeactivateAccount 对象
    DeactivateAccount *deactivateAccount = [[DeactivateAccount alloc] init];
    deactivateAccount.userId = userId;
    
    // 设置注销原因（可选）
    if (reason && reason.length > 0) {
        deactivateAccount.reason = reason;
    }
    
    // 序列化
    NSData *serializedData = [deactivateAccount data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化注销数据失败");
        if (completion) {
            completion(-2, @"序列化失败", nil, 0);
        }
        return 0;
    }
    
    NSLog(@"📦 序列化成功: %lu 字节", (unsigned long)serializedData.length);
    
    // 保存回调
    uint64_t reqId = 0;
    int result = deactivate_user(DeleteUserCallback,
                             (const char *)serializedData.bytes,
                             (int)serializedData.length,
                             reqId);
    
    if (result == 0 && reqId > 0) {
        if (completion) {
            g_userCallbacks[@(reqId)] = [completion copy];
        }
        NSLog(@"✅ 注销用户请求已发送: reqId=%llu", reqId);
    } else {
        NSLog(@"❌ 注销用户请求失败: result=%d", result);
        if (completion) {
            completion(result, @"发送请求失败", nil, 0);
        }
    }
    
    return reqId;
}

#pragma mark - 获取用户信息

// 获取用户信息回调
// CB_S_I_S_S 签名: void callback(const char* operationID, int errorCode, const char* data, const char* extra)
static void GetUsersInfoCallback(const char* operationID, int errorCode, const char* data, const char* extra) {
    NSLog(@"📨 获取用户信息回调: operationID=%s, errorCode=%d, data=%s, extra=%s", 
          operationID ? operationID : "nil", 
          errorCode, 
          data ? data : "nil",
          extra ? extra : "nil");
    
    // 立即拷贝数据
    NSData *responseData = nil;
    int dataLen = 0;
    if (data) {
        dataLen = (int)strlen(data);
        if (dataLen > 0) {
            responseData = [NSData dataWithBytes:data length:dataLen];
        }
    }
    
    // 从 operationID 获取 reqId
    NSString *opIDStr = operationID ? [NSString stringWithUTF8String:operationID] : nil;
    NSNumber *reqIdNum = opIDStr ? g_operationIdToReqId[opIDStr] : nil;
    uint64_t reqId = reqIdNum ? [reqIdNum unsignedLongLongValue] : 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 通过 reqId 查找回调
        IMSDKUserCompletion completion = nil;
        if (reqId > 0) {
            completion = g_userCallbacks[@(reqId)];
        }
        
        if (completion == nil) {
            NSLog(@"⚠️ 未找到回调: operationID=%s, reqId=%llu", operationID ? operationID : "nil", reqId);
            // 如果找不到，尝试使用第一个回调（临时方案）
            if (g_userCallbacks.count > 0) {
                NSNumber *firstKey = g_userCallbacks.allKeys.firstObject;
                completion = g_userCallbacks[firstKey];
                [g_userCallbacks removeObjectForKey:firstKey];
                NSLog(@"⚠️ 使用第一个可用回调");
            } else {
                NSLog(@"❌ 没有可用的回调");
                return;
            }
        } else {
            [g_userCallbacks removeObjectForKey:@(reqId)];
            if (opIDStr) {
                [g_operationIdToReqId removeObjectForKey:opIDStr];
            }
        }
        
        if (errorCode != 0) {
            NSString *errorMsg = data ? [NSString stringWithUTF8String:data] : @"获取用户信息失败";
            completion(errorCode, errorMsg, nil, reqId);
            return;
        }
        
        // 解析返回的用户信息列表
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        
        if (data && dataLen > 0) {
            // 尝试解析为 JSON 字符串（通常返回的是 JSON 数组）
            NSString *jsonStr = [NSString stringWithUTF8String:data];
            if (jsonStr && jsonStr.length > 0) {
                NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError = nil;
                id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
                
                if (!jsonError && jsonObj) {
                    // 如果返回的是数组，直接使用
                    if ([jsonObj isKindOfClass:[NSArray class]]) {
                        result[@"users"] = jsonObj;
                        NSLog(@"✅ 获取用户信息成功: %lu 个用户", (unsigned long)[(NSArray *)jsonObj count]);
                    } else if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                        // 如果返回的是字典，尝试提取 users 字段
                        NSDictionary *dict = (NSDictionary *)jsonObj;
                        if (dict[@"users"]) {
                            result[@"users"] = dict[@"users"];
                        } else {
                            // 如果没有 users 字段，将整个字典作为单个用户
                            result[@"users"] = @[dict];
                        }
                        NSLog(@"✅ 获取用户信息成功: 字典格式");
                    } else {
                        // 尝试作为 Protobuf 解析（如果 SDK 返回的是 Protobuf）
                        // 暂时先使用 JSON 字符串
                        result[@"raw_data"] = jsonStr;
                        NSLog(@"⚠️ 返回数据格式未知，使用原始数据");
                    }
                } else {
                    // JSON 解析失败，尝试作为 Protobuf 解析
                    // 暂时先使用原始字符串
                    result[@"raw_data"] = jsonStr;
                    NSLog(@"⚠️ JSON 解析失败，使用原始数据: %@", jsonError);
                }
            } else {
                NSLog(@"⚠️ 响应数据为空或无法转换为字符串");
            }
        }
        
        completion(0, @"获取成功", result, reqId);
    });
}

- (uint64_t)getUsersInfoWithUserIds:(NSArray<NSString *> *)userIds
                          completion:(IMSDKUserCompletion)completion {
    NSLog(@"📤 获取用户信息: userIds=%@", userIds);
    
    // 验证参数
    if (!userIds || userIds.count == 0) {
        NSLog(@"❌ userIds 不能为空");
        if (completion) {
            completion(-1, @"userIds 不能为空", nil, 0);
        }
        return 0;
    }
    
    // 将用户ID数组转换为 JSON 字符串
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userIds options:0 error:&jsonError];
    if (!jsonData || jsonError) {
        NSLog(@"❌ 序列化用户ID数组失败: %@", jsonError);
        if (completion) {
            completion(-2, @"序列化用户ID失败", nil, 0);
        }
        return 0;
    }
    
    NSString *userIdsJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"📦 用户ID JSON: %@", userIdsJson);
    
    // 生成操作ID
    NSString *operationID = [[NSUUID UUID] UUIDString];
    
    // 生成一个唯一的 reqId 来标识这次请求
    uint64_t reqId = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    
    // 保存回调（使用 reqId 作为 key）
    if (completion) {
        g_userCallbacks[@(reqId)] = [completion copy];
        // 同时保存 operationID 到 reqId 的映射
        g_operationIdToReqId[operationID] = @(reqId);
    }
    
    // 调用 SDK 接口
    get_users_info(GetUsersInfoCallback,
                   (char *)[operationID UTF8String],
                   (char *)[userIdsJson UTF8String]);
    
    NSLog(@"✅ 获取用户信息请求已发送: operationID=%@, reqId=%llu", operationID, reqId);
    
    return reqId;
}


@end

