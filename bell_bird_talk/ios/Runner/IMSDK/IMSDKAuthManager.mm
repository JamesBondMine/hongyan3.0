//
//  IMSDKAuthManager.mm
//  Runner
//
//  IM SDK 认证管理类实现
//

#import "IMSDKAuthManager.h"
#include "network_lib.h"
#include "callback_types.h"

@interface IMSDKAuthManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, IMSDKAuthCompletion> *authCallbacks;

@end

@implementation IMSDKAuthManager

// ==================== 单例模式 ====================

+ (instancetype)sharedManager {
    static IMSDKAuthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _authCallbacks = [NSMutableDictionary dictionary];
        NSLog(@"🔐 IMSDKAuthManager 初始化");
    }
    return self;
}

// ==================== C 回调函数 ====================

// 登录回调函数
static void LoginCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 登录回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    IMSDKAuthManager *manager = [IMSDKAuthManager sharedManager];
    NSNumber *reqIdKey = @(reqId);
    
    IMSDKAuthCompletion completion = manager.authCallbacks[reqIdKey];
    if (completion) {
        NSString *dataStr = nil;
        if (data && dataLen > 0) {
            dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, dataStr);
        });
        
        // 回调完成后移除
        [manager.authCallbacks removeObjectForKey:reqIdKey];
    } else {
        NSLog(@"⚠️ 未找到 reqId=%llu 对应的回调", reqId);
    }
}

// 注册回调函数
static void RegisterCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 注册回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    IMSDKAuthManager *manager = [IMSDKAuthManager sharedManager];
    NSNumber *reqIdKey = @(reqId);
    
    IMSDKAuthCompletion completion = manager.authCallbacks[reqIdKey];
    if (completion) {
        NSString *dataStr = nil;
        if (data && dataLen > 0) {
            dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, dataStr);
        });
        
        [manager.authCallbacks removeObjectForKey:reqIdKey];
    }
}

// 验证码回调函数
static void CaptchaCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 验证码回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    IMSDKAuthManager *manager = [IMSDKAuthManager sharedManager];
    NSNumber *reqIdKey = @(reqId);
    
    IMSDKAuthCompletion completion = manager.authCallbacks[reqIdKey];
    if (completion) {
        NSString *dataStr = nil;
        if (data && dataLen > 0) {
            dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, dataStr);
        });
        
        [manager.authCallbacks removeObjectForKey:reqIdKey];
    }
}

// ==================== 用户登录 ====================

- (int)loginWithUserId:(NSString *)userId
                 token:(NSString *)token
            completion:(IMSDKAuthCompletion)completion {
    NSLog(@"👤 用户登录: userId=%@", userId);
    
    if (!userId || userId.length == 0) {
        NSLog(@"❌ userId 不能为空");
        return -1;
    }
    
    // 构造简单的 JSON 格式数据（实际应该使用 protobuf 序列化）
    // 注意：这是临时方案，实际应该使用 user_pb::AuthUser 序列化
    NSDictionary *authData = @{
        @"user_id": userId,
        @"token": token ?: @""
    };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:authData options:0 error:&error];
    if (error) {
        NSLog(@"❌ JSON 序列化失败: %@", error);
        return -2;
    }
    
    return [self loginWithSerializedData:jsonData completion:completion];
}

- (int)loginWithToken:(NSString *)token
           completion:(IMSDKAuthCompletion)completion {
    NSLog(@"🎫 Token快速登录");
    
    if (!token || token.length == 0) {
        NSLog(@"❌ token 不能为空");
        return -1;
    }
    
    // 构造 token 登录数据
    NSDictionary *authData = @{
        @"token": token
    };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:authData options:0 error:&error];
    if (error) {
        NSLog(@"❌ JSON 序列化失败: %@", error);
        return -2;
    }
    
    const char *data = (const char *)jsonData.bytes;
    int dataLen = (int)jsonData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        // 使用临时 ID 先保存回调
        static uint64_t tempId = 2000;
        NSNumber *tempKey = @(tempId++);
        self.authCallbacks[tempKey] = completion;
        
        int result = login_by_token(LoginCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ Token登录请求发送成功: reqId=%llu", reqId);
            // 用真实 reqId 更新
            if (reqId != 0) {
                self.authCallbacks[@(reqId)] = completion;
                [self.authCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ Token登录请求失败: %d", result);
            [self.authCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return login_by_token(LoginCallback, data, dataLen, reqId);
}

- (int)loginWithSerializedData:(NSData *)serializedData
                    completion:(IMSDKAuthCompletion)completion {
    NSLog(@"🔐 用户登录（序列化数据）: dataLen=%lu", (unsigned long)serializedData.length);
    
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化数据不能为空");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        // 使用临时 ID 先保存回调
        static uint64_t tempId = 1000;
        NSNumber *tempKey = @(tempId++);
        self.authCallbacks[tempKey] = completion;
        
        int result = login_by_user_id(LoginCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 登录请求发送成功: reqId=%llu", reqId);
            // 用真实 reqId 更新
            if (reqId != 0) {
                self.authCallbacks[@(reqId)] = completion;
                [self.authCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 登录请求失败: %d", result);
            [self.authCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return login_by_user_id(LoginCallback, data, dataLen, reqId);
}

// ==================== 用户注册 ====================

- (int)registerWithSerializedData:(NSData *)serializedData
                        completion:(IMSDKAuthCompletion)completion {
    NSLog(@"📝 用户注册: dataLen=%lu", (unsigned long)serializedData.length);
    
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化数据不能为空");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 3000;
        NSNumber *tempKey = @(tempId++);
        self.authCallbacks[tempKey] = completion;
        
        int result = register_user(RegisterCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 注册请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.authCallbacks[@(reqId)] = completion;
                [self.authCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 注册请求失败: %d", result);
            [self.authCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return register_user(RegisterCallback, data, dataLen, reqId);
}

// ==================== 验证码 ====================

- (int)getCaptchaWithSerializedData:(NSData *)serializedData
                          completion:(IMSDKAuthCompletion)completion {
    NSLog(@"🔢 获取验证码: dataLen=%lu", (unsigned long)serializedData.length);
    
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化数据不能为空");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 4000;
        NSNumber *tempKey = @(tempId++);
        self.authCallbacks[tempKey] = completion;
        
        int result = get_captcha(CaptchaCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 验证码请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.authCallbacks[@(reqId)] = completion;
                [self.authCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 验证码请求失败: %d", result);
            [self.authCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return get_captcha(CaptchaCallback, data, dataLen, reqId);
}

@end

