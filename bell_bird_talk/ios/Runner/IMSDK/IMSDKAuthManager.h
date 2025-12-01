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

/// 使用用户ID登录
/// @param userId 用户ID
/// @param token 用户token
/// @param completion 登录结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)loginWithUserId:(NSString *)userId
                 token:(NSString *)token
            completion:(IMSDKAuthCompletion)completion;

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

/// 用户注册
/// @param serializedData 序列化后的注册数据
/// @param completion 注册结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)registerWithSerializedData:(NSData *)serializedData
                        completion:(IMSDKAuthCompletion)completion;

// ==================== 验证码 ====================

/// 获取验证码
/// @param serializedData 序列化后的 captcha_pb::GetCaptcha 数据
/// @param completion 验证码结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCaptchaWithSerializedData:(NSData *)serializedData
                          completion:(IMSDKAuthCompletion)completion;

@end

NS_ASSUME_NONNULL_END

