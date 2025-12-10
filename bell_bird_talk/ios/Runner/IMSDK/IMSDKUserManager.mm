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

@end

