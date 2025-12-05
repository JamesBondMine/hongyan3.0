//
//  IMSDKAuthManager.mm
//  Runner
//
//  IM SDK 认证管理类实现
//

#import "IMSDKAuthManager.h"
#import "UserPb.pbobjc.h"
#import "CaptchaPb.pbobjc.h"
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

- (int)loginWithDictionary:(NSDictionary *)loginDict
                completion:(IMSDKAuthCompletion)completion {
    NSLog(@"🔐 用户登录（字典）: %@", loginDict);
    
    if (!loginDict) {
        NSLog(@"❌ 登录信息不能为空");
        return -1;
    }
    
    // 使用 protobuf 创建 AuthUser 对象
    AuthUser *authUser = [[AuthUser alloc] init];
    
    // 登录类型（默认密码登录）
    NSString *loginTypeStr = loginDict[@"login_type"];
    if ([loginTypeStr isEqualToString:@"password"]) {
        authUser.loginType = LoginType_Password;
    } else if ([loginTypeStr isEqualToString:@"sms_code"]) {
        authUser.loginType = LoginType_SmsCode;
    } else if ([loginTypeStr isEqualToString:@"email_code"]) {
        authUser.loginType = LoginType_EmailCode;
    } else if ([loginTypeStr isEqualToString:@"token"]) {
        authUser.loginType = LoginType_Token;
    } else {
        // 默认密码登录
        authUser.loginType = LoginType_Password;
    }
    
    NSLog(@"📋 登录类型: %@ -> %d", loginTypeStr, (int)authUser.loginType);
    
    // 账户ID（密码登录必填）
    if (loginDict[@"account_id"]) {
        authUser.accountId = loginDict[@"account_id"];
        NSLog(@"📋 账户ID: %@", authUser.accountId);
    }
    
    // 密码（密码登录时为密码，验证码登录时为验证码答案）
    if (loginDict[@"password"]) {
        authUser.password = loginDict[@"password"];
        NSLog(@"📋 密码/验证码: [已设置]");
    }
    
    // 手机号（短信验证码登录必填）
    if (loginDict[@"phone"]) {
        authUser.phone = loginDict[@"phone"];
        NSLog(@"📋 手机号: %@", authUser.phone);
    }
    
    // 邮箱（邮箱验证码登录必填）
    if (loginDict[@"email"]) {
        authUser.email = loginDict[@"email"];
        NSLog(@"📋 邮箱: %@", authUser.email);
    }
    
    // 验证码ID（验证码登录必填）
    if (loginDict[@"captcha_id"]) {
        authUser.captchaId = loginDict[@"captcha_id"];
        NSLog(@"📋 验证码ID: %@", authUser.captchaId);
    }
    
    // 设备ID（可选）
    if (loginDict[@"device_id"]) {
        authUser.deviceId = loginDict[@"device_id"];
        NSLog(@"📋 设备ID: %@", authUser.deviceId);
    }
    
    // 业务邀请码（可选）
    if (loginDict[@"biz_code"]) {
        authUser.bizCode = loginDict[@"biz_code"];
        NSLog(@"📋 业务邀请码: %@", authUser.bizCode);
    }
    
    // 客户端IP（可选）
    if (loginDict[@"client_ip"]) {
        authUser.clientIp = loginDict[@"client_ip"];
    }
    
    // 序列化 protobuf 对象
    NSData *serializedData = [authUser data];
    NSLog(@"📦 Protobuf 序列化成功: %lu bytes", (unsigned long)serializedData.length);
    
    // 打印十六进制数据（用于调试）
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    NSUInteger printLen = MIN(serializedData.length, 64);
    for (NSUInteger i = 0; i < printLen; i++) {
        [hexString appendFormat:@"%02x ", bytes[i]];
        if ((i + 1) % 16 == 0) [hexString appendString:@"\n                        "];
    }
    NSLog(@"🔍 Protobuf 数据 (HEX):\n                        %@", hexString);
    
    // 调用底层的序列化数据方法
    return [self loginWithSerializedData:serializedData completion:completion];
}

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
    
    // ✅ 使用纯数据格式（不带 varint32 头部）
    // 与 getCaptcha 验证通过的格式保持一致
    NSLog(@"📦 使用纯数据格式（不带 varint32 头部）");
    NSLog(@"📦 数据长度: %lu 字节", (unsigned long)jsonData.length);
    
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
    
    // ✅ 使用格式3: 纯 Protobuf 二进制（不带 varint32 头部）
    // 与 getCaptcha 验证通过的格式保持一致
    NSLog(@"📦 使用纯 Protobuf 二进制格式（不带 varint32 头部）");
    NSLog(@"📦 Protobuf 数据长度: %lu 字节", (unsigned long)serializedData.length);
    
    // 直接使用纯 Protobuf 二进制数据，不添加 varint32 头部
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

- (int)registerWithDictionary:(NSDictionary *)registerDict
                    completion:(IMSDKAuthCompletion)completion {
    NSLog(@"📝 用户注册（字典）: %@", registerDict);
    
    if (!registerDict) {
        NSLog(@"❌ 注册信息不能为空");
        return -1;
    }
    
    // 使用 protobuf 创建 CreateUser 对象
    CreateUser *createUser = [[CreateUser alloc] init];
    
    // 必填字段
    if (registerDict[@"account_id"]) {
        createUser.accountId = registerDict[@"account_id"];
    }
    if (registerDict[@"password"]) {
        createUser.password = registerDict[@"password"];
    }
    
    // 可选字段 - 手机号
    if (registerDict[@"phone"]) {
        createUser.phone = registerDict[@"phone"];
    }
    
    // 可选字段 - 邮箱
    if (registerDict[@"email"]) {
        createUser.email = registerDict[@"email"];
    }
    
    // 可选字段 - 昵称
    if (registerDict[@"nickname"]) {
        createUser.nickname = registerDict[@"nickname"];
    }
    
    // 可选字段 - 业务邀请码
    if (registerDict[@"biz_code"]) {
        createUser.bizCode = registerDict[@"biz_code"];
    }
    
    // 可选字段 - 注册方式
    if (registerDict[@"register_type"]) {
        NSString *typeStr = registerDict[@"register_type"];
        if ([typeStr isEqualToString:@"phone"]) {
            createUser.registerType = RegisterType_PhoneSms;
        } else if ([typeStr isEqualToString:@"account"]) {
            createUser.registerType = RegisterType_UsernamePassword;
        } else if ([typeStr isEqualToString:@"email"]) {
            createUser.registerType = RegisterType_EmailVerify;
        }
    }
    
    // 可选字段 - 验证码信息
    // CaptchaInfo 只有两个字段：captcha_id 和 answer
    if (registerDict[@"captcha"]) {
        NSDictionary *captchaDict = registerDict[@"captcha"];
        CaptchaInfo *captcha = [[CaptchaInfo alloc] init];
        
        if (captchaDict[@"captcha_id"]) {
            captcha.captchaId = captchaDict[@"captcha_id"];
        }
        if (captchaDict[@"captcha_code"] || captchaDict[@"answer"]) {
            // Flutter 可能传 captcha_code 或 answer，映射到 protobuf 的 answer 字段
            captcha.answer = captchaDict[@"captcha_code"] ?: captchaDict[@"answer"];
        }
        
        createUser.captcha = captcha;
    }
    
    // 序列化 protobuf 对象
    NSData *serializedData = [createUser data];
    NSLog(@"📦 Protobuf 序列化成功: %lu bytes", (unsigned long)serializedData.length);
    
    // 调用底层的序列化数据方法
    return [self registerWithSerializedData:serializedData completion:completion];
}

- (int)registerWithSerializedData:(NSData *)serializedData
                        completion:(IMSDKAuthCompletion)completion {
    NSLog(@"📝 用户注册（protobuf）: dataLen=%lu", (unsigned long)serializedData.length);
    
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ 序列化数据不能为空");
        return -1;
    }
    
    // ✅ 使用格式3: 纯 Protobuf 二进制（不带 varint32 头部）
    // 与 getCaptcha 验证通过的格式保持一致
    NSLog(@"📦 使用纯 Protobuf 二进制格式（不带 varint32 头部）");
    NSLog(@"📦 Protobuf 数据长度: %lu 字节", (unsigned long)serializedData.length);
    
    // 打印十六进制数据（用于验证格式）
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    NSUInteger printLen = MIN(serializedData.length, 64); // 打印前64字节
    for (NSUInteger i = 0; i < printLen; i++) {
        [hexString appendFormat:@"%02x ", bytes[i]];
        if ((i + 1) % 16 == 0) [hexString appendString:@"\n                        "];
    }
    NSLog(@"🔍 Protobuf 数据 (HEX):\n                        %@", hexString);
    
    // 直接使用纯 Protobuf 二进制数据，不添加 varint32 头部
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
    NSLog(@"🔢 获取验证码（旧方法）: dataLen=%lu", (unsigned long)serializedData.length);
    NSLog(@"⚠️ 此方法已弃用，请使用 getCaptchaWithScene:type:value:completion:");
    return -1;
}

/// 使用 Protobuf 序列化获取验证码
/// @param scene 使用场景：register/login 等
/// @param type 验证码类型：CaptchaType_SMS=1, CaptchaType_EMAIL=2
/// @param value 目标值：手机号或邮箱
/// @param completion 回调
- (int)getCaptchaWithScene:(NSString *)scene
                      type:(int)type
                     value:(NSString *)value
                completion:(IMSDKAuthCompletion)completion {
    NSLog(@"🔢 获取验证码: scene=%@, type=%d, value=%@", scene, type, value);
    
    // ⚠️ 数据格式测试开关（修改这个值来测试不同格式）
    // 1 = 原始二进制（varint32头部 + protobuf）
    // 2 = 十六进制字符串（带 varint32 头部）
    // 3 = 纯 Protobuf 二进制（不带 varint32 头部）
    // 4 = 纯 Protobuf 转十六进制字符串（不带头部）👈 这个应该是正确的！
    int dataFormat = 3;  // 👈 修改这里切换格式
    
    NSLog(@"🧪 当前测试格式: %d (1=二进制+头部, 2=HEX+头部, 3=纯二进制, 4=纯Protobuf转HEX)", dataFormat);
    
    // 1. 创建 GetCaptcha Protobuf 对象
    GetCaptcha *captchaRequest = [[GetCaptcha alloc] init];
    captchaRequest.scene = scene ?: @"register";
    captchaRequest.type = (CaptchaType)type;
    captchaRequest.value = value ?: @"";
    
    // 2. 序列化为 Protobuf 二进制数据
    NSData *protoBody = [captchaRequest data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 Protobuf 原始数据长度: %lu 字节", (unsigned long)protoBody.length);
    
    // 打印 Protobuf 原始数据（十六进制）
    NSMutableString *protoHex = [NSMutableString stringWithCapacity:protoBody.length * 2];
    const unsigned char *protoBytes = (const unsigned char *)protoBody.bytes;
    for (NSUInteger i = 0; i < protoBody.length; i++) {
        [protoHex appendFormat:@"%02x", protoBytes[i]];
    }
    NSLog(@"📦 Protobuf 原始数据 (HEX): %@", protoHex);
    
    const char *data = NULL;
    int dataLen = 0;
    NSData *finalData = nil;
    NSString *hexString = nil;
    
    switch (dataFormat) {
        case 1: {
            // ========== 格式1: 原始二进制（varint32头部 + protobuf）==========
            NSLog(@"🔸 使用格式1: 原始二进制（varint32头部 + protobuf）");
            NSData *hdr = [self encodeVarint32:(uint32_t)protoBody.length];
            NSMutableData *pkt = [NSMutableData dataWithData:hdr];
            [pkt appendData:protoBody];
            
            finalData = pkt;
            data = (const char *)pkt.bytes;
            dataLen = (int)pkt.length;
            
            NSLog(@"📦 头部长度: %lu, 总长度: %d", (unsigned long)hdr.length, dataLen);
            break;
        }
        case 2: {
            // ========== 格式2: 十六进制字符串 ==========
            NSLog(@"🔸 使用格式2: 十六进制字符串");
            
            // 先构建带头部的数据
            NSData *hdr = [self encodeVarint32:(uint32_t)protoBody.length];
            NSMutableData *pkt = [NSMutableData dataWithData:hdr];
            [pkt appendData:protoBody];
            
            // 转换为十六进制字符串
            NSMutableString *hexData = [NSMutableString stringWithCapacity:pkt.length * 2];
            const uint8_t *p = (const uint8_t *)pkt.bytes;
            for (size_t i = 0; i < pkt.length; i++) {
                [hexData appendFormat:@"%02x", p[i]];
            }
            
            hexString = hexData;
            data = [hexData UTF8String];
            dataLen = (int)[hexData length];
            
            NSLog(@"📦 HEX 字符串: %@", hexData);
            NSLog(@"📦 HEX 长度: %d", dataLen);
            break;
        }
        case 3: {
            // ========== 格式3: 纯 Protobuf 二进制（不带 varint32 头部）==========
            NSLog(@"🔸 使用格式3: 纯 Protobuf 二进制（不带 varint32 头部）");
            
            finalData = protoBody;
            data = (const char *)protoBody.bytes;
            dataLen = (int)protoBody.length;
            
            NSLog(@"📦 纯 Protobuf 长度: %d", dataLen);
            break;
        }
        case 4:
        default: {
            // ========== 格式4: 纯 Protobuf 转十六进制字符串（不带头部）==========
            // 这是根据用户示例确定的正确格式：
            // 示例: data = "0a056c6f67696e10021a03313130"
            // 解析: {"1": "login", "2": "2", "3": "110"}
            NSLog(@"🔸 使用格式4: 纯 Protobuf 转十六进制字符串（不带头部）");
            
            // 直接将 Protobuf 二进制数据转换为十六进制字符串
            NSMutableString *hexData = [NSMutableString stringWithCapacity:protoBody.length * 2];
            const uint8_t *p = (const uint8_t *)protoBody.bytes;
            for (size_t i = 0; i < protoBody.length; i++) {
                [hexData appendFormat:@"%02x", p[i]];
            }
            
            hexString = hexData;
            data = [hexData UTF8String];
            dataLen = (int)[hexData length];
            
            NSLog(@"📦 HEX 字符串: %@", hexData);
            NSLog(@"📦 HEX 字符串长度: %d", dataLen);
            NSLog(@"📦 原始 Protobuf 字节数: %lu", (unsigned long)protoBody.length);
            break;
        }
    }
    
   
    
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 4000;
        NSNumber *tempKey = @(tempId++);
        self.authCallbacks[tempKey] = completion;
        
         NSLog(@"🚀 ============== 准备调用 get_captcha ==============");
         NSLog(@"📍 data 指针: %p", data);
         NSLog(@"📍 data 内容: %s", data);
         NSLog(@"📍 dataLen: %d", dataLen);
         NSLog(@"📍 reqId: %llu", reqId);
         NSLog(@"🚀 ================================================");

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

// varint32 编码
- (NSData *)encodeVarint32:(uint32_t)value {
    NSMutableData *data = [NSMutableData data];
    while (YES) {
        if ((value & ~0x7F) == 0) {
            uint8_t byte = (uint8_t)value;
            [data appendBytes:&byte length:1];
            break;
        } else {
            uint8_t byte = (uint8_t)((value & 0x7F) | 0x80);
            [data appendBytes:&byte length:1];
            value >>= 7;
        }
    }
    return data;
}

@end

