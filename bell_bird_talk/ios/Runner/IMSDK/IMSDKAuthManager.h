//
//  IMSDKAuthManager.h
//  Runner
//
//  IM SDK 认证管理类 - 用户登录、注册、验证码
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 认证结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 或序列化数据）
typedef void (^IMSDKAuthCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 认证管理类
@interface IMSDKAuthManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 用户登录 ====================

/// 使用字典数据登录（推荐，支持多种登录方式）
/// @param loginDict 登录信息字典，支持以下字段：
///   - account_id: 账户ID（密码登录必填）
///   - password: 密码（密码登录必填）或验证码答案（验证码登录必填）
///   - login_type: 登录类型（password/sms_code/email_code）
///   - phone: 手机号（短信登录必填）
///   - email: 邮箱（邮箱登录必填）
///   - captcha_id: 验证码ID（验证码登录必填）
///   - device_id: 设备ID（可选）
///   - biz_code: 业务邀请码（可选）
/// @param completion 登录结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)loginWithDictionary:(NSDictionary *)loginDict
                completion:(IMSDKAuthCompletion)completion;

/// 使用用户ID登录（已弃用，请使用 loginWithDictionary:completion:）
/// @param userId 用户ID
/// @param token 用户token
/// @param completion 登录结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)loginWithUserId:(NSString *)userId
                 token:(NSString *)token
            completion:(IMSDKAuthCompletion)completion __attribute__((deprecated("Use loginWithDictionary:completion: instead")));

/// 使用Token快速登录
/// @param token 用户token
/// @param completion 登录结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)loginWithToken:(NSString *)token
           completion:(IMSDKAuthCompletion)completion;

/// 使用序列化数据登录（user_pb::AuthUser）
/// @param serializedData 序列化后的数据
/// @param completion 登录结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)loginWithSerializedData:(NSData *)serializedData
                    completion:(IMSDKAuthCompletion)completion;

// ==================== 用户注册 ====================

/// 用户注册（使用字典数据）
/// @param registerDict 注册信息字典
/// @param completion 注册结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)registerWithDictionary:(NSDictionary *)registerDict
                    completion:(IMSDKAuthCompletion)completion;

/// 用户注册（使用 protobuf 序列化数据）
/// @param serializedData 序列化后的 CreateUser 数据
/// @param completion 注册结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)registerWithSerializedData:(NSData *)serializedData
                        completion:(IMSDKAuthCompletion)completion;

// ==================== 验证码 ====================

/// 获取验证码（已弃用，请使用 getCaptchaWithScene:type:value:completion:）
/// @param serializedData 序列化后的 captcha_pb::GetCaptcha 数据
/// @param completion 验证码结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCaptchaWithSerializedData:(NSData *)serializedData
                          completion:(IMSDKAuthCompletion)completion __attribute__((deprecated("Use getCaptchaWithScene:type:value:completion: instead")));

/// 获取验证码（使用 Protobuf 序列化）
/// @param scene 使用场景：register/login 等
/// @param type 验证码类型：1=SMS短信, 2=EMAIL邮箱
/// @param value 目标值：手机号或邮箱
/// @param completion 验证码结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCaptchaWithScene:(NSString *)scene
                      type:(int)type
                     value:(NSString *)value
                completion:(IMSDKAuthCompletion)completion;

// ==================== 用户查询 ====================

/// 搜索用户（根据用户ID或账户ID）
/// @param userId 用户ID（可选）
/// @param accountId 账户ID（可选，可以是手机号、邮箱等）
/// @param completion 查询结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)searchUserWithUserId:(NSString * _Nullable)userId
                  accountId:(NSString * _Nullable)accountId
                 completion:(IMSDKAuthCompletion)completion;

// ==================== 密码管理 ====================

/// 修改密码
/// @param userId 用户ID（必填）
/// @param oldPassword 旧密码（必填）
/// @param newPassword 新密码（必填）
/// @param completion 修改结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)changePasswordWithUserId:(NSString *)userId
                     oldPassword:(NSString *)oldPassword
                     newPassword:(NSString *)newPassword
                      completion:(IMSDKAuthCompletion)completion;

/// 重置密码（忘记密码）
/// @param phone 手机号（可选，与email二选一）
/// @param email 邮箱（可选，与phone二选一）
/// @param captchaId 验证码ID（必填）
/// @param captchaCode 验证码答案（必填）
/// @param newPassword 新密码（必填）
/// @param completion 重置结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)resetPasswordWithPhone:(NSString * _Nullable)phone
                        email:(NSString * _Nullable)email
                    captchaId:(NSString *)captchaId
                  captchaCode:(NSString *)captchaCode
                  newPassword:(NSString *)newPassword
                   completion:(IMSDKAuthCompletion)completion;

@end

NS_ASSUME_NONNULL_END

