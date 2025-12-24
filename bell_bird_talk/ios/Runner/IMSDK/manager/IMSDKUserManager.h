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

/// 注销用户
/// @param userId 用户ID（必填）
/// @param reason 注销原因（可选）
/// @param completion 完成回调
/// @return 请求ID
- (uint64_t)deactivateAccountWithUserId:(NSString *)userId
                                  reason:(NSString * _Nullable)reason
                              completion:(IMSDKUserCompletion)completion;

/// 获取用户信息
/// @param userIds 用户ID数组（支持多个用户ID）
/// @param completion 完成回调，data 字段包含用户信息数组（JSON 字符串）
/// @return 请求ID，失败返回0
- (uint64_t)getUsersInfoWithUserIds:(NSArray<NSString *> *)userIds
                          completion:(IMSDKUserCompletion)completion;

/// 批量获取用户公开信息
/// @param userIds 用户ID数组（支持多个用户ID）
/// @param completion 完成回调，data 字段包含公开信息数组（JSON 字符串）
/// @return 请求ID，失败返回0
- (uint64_t)batchGetUserPublicInfoWithUserIds:(NSArray<NSString *> *)userIds
                                    completion:(IMSDKUserCompletion)completion;

/// 获取注销状态
/// @param userId 用户ID（必填）
/// @param completion 完成回调，data 字段包含注销状态信息（JSON 字符串）
/// @return 请求ID，失败返回0
- (uint64_t)getDeactivateStatusWithUserId:(NSString *)userId
                               completion:(IMSDKUserCompletion)completion;

@end

NS_ASSUME_NONNULL_END

