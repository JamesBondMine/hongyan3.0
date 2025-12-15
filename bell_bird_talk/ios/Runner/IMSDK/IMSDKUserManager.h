//
//  IMSDKUserManager.h
//  Runner
//
//  用户信息管理
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用户管理回调
typedef void (^IMSDKUserCompletion)(int errorCode, NSString * _Nullable message, NSDictionary * _Nullable data, uint64_t reqId);

/// 用户管理器
@interface IMSDKUserManager : NSObject

/// 单例
+ (instancetype)shared;

/// 更新用户信息
/// @param userInfo 用户信息字典，可包含以下字段：
///   - user_id: 用户ID（必填）
///   - nickname: 昵称
///   - sex: 性别 (0=男, 1=女)
///   - signature: 个性签名
///   - avatar: 头像URL
///   - region: 地区
///   - background_file: 背景图片URL
/// @param completion 完成回调
/// @return 请求ID，失败返回0
- (uint64_t)updateUserWithInfo:(NSDictionary *)userInfo
                    completion:(IMSDKUserCompletion)completion;

/// 更新昵称
/// @param nickname 新昵称
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)updateNickname:(NSString *)nickname
                completion:(IMSDKUserCompletion)completion;

/// 更新个性签名
/// @param signature 新签名
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)updateSignature:(NSString *)signature
                 completion:(IMSDKUserCompletion)completion;

/// 更新性别
/// @param sex 性别 (0=男, 1=女)
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)updateSex:(int)sex
           completion:(IMSDKUserCompletion)completion;

/// 更新头像
/// @param avatarUrl 新头像URL
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)updateAvatar:(NSString *)avatarUrl
              completion:(IMSDKUserCompletion)completion;

/// 退出登录
/// @param userId 用户ID（可选，传入则写入 Logout proto）
/// @param clientIp 客户端 IP（可选）
/// @param reason 登出原因（可选，遵循 LogoutReason 枚举，缺省 USER_LOGOUT）
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)logoutWithUserId:(NSString * _Nullable)userId
                    clientIp:(NSString * _Nullable)clientIp
                      reason:(NSNumber * _Nullable)reason
                  completion:(IMSDKUserCompletion)completion;

/// 退出登录（兼容旧签名）
- (uint64_t)logoutWithCompletion:(IMSDKUserCompletion)completion;

@end

NS_ASSUME_NONNULL_END

