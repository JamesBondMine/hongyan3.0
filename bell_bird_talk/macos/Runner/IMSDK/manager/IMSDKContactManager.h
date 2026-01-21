//
//  IMSDKContactManager.h
//  Runner
//
//  IM SDK 联系人管理类 - 好友添加、删除、拉黑等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 联系人操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKContactCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 联系人管理类
@interface IMSDKContactManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 好友申请 ====================

/// 添加好友（发送好友申请）
/// @param targetUserId 目标用户ID（必填）
/// @param channel 添加渠道：0=用户ID, 1=用户名, 2=手机号, 3=邮箱, 4=邀请码, 5=二维码
/// @param message 验证消息（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)addContactWithUserId:(NSString *)targetUserId
                    channel:(int)channel
                    message:(NSString * _Nullable)message
                 completion:(IMSDKContactCompletion)completion;

/// 添加好友（使用字典参数）
/// @param params 参数字典，支持以下字段：
///   - target_user_id: 目标用户ID（必填）
///   - target_value: 目标值（用户ID/手机号/邮箱等，必填）
///   - channel: 添加渠道（可选，默认0=用户ID）
///   - message: 验证消息（可选）
///   - target_phone: 目标手机号（可选，用于验证）
///   - target_email: 目标邮箱（可选，用于验证）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)addContactWithParams:(NSDictionary *)params
                 completion:(IMSDKContactCompletion)completion;

// ==================== 好友管理 ====================

/// 删除好友
/// @param userId 好友用户ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)deleteContactWithUserId:(NSString *)userId
                    completion:(IMSDKContactCompletion)completion;

/// 拉黑用户
/// @param userId 用户ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)blockContactWithUserId:(NSString *)userId
                   completion:(IMSDKContactCompletion)completion;

/// 取消拉黑
/// @param userId 用户ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)unblockContactWithUserId:(NSString *)userId
                     completion:(IMSDKContactCompletion)completion;

/// 获取黑名单状态
/// @param userId 用户ID
/// @param completion 结果回调，data 字段包含黑名单状态（JSON 格式，包含 blockDirection 字段）
/// @return 0表示请求发送成功，其他为错误码
- (int)getBlackStatusWithUserId:(NSString *)userId
                      completion:(IMSDKContactCompletion)completion;

// ==================== 好友查询 ====================

/// 获取联系人列表
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param relationship 关系类型：0=好友, 1=关注, 2=黑名单, 3=待确认, -1=全部
/// @param groupId 分组ID（可选，0表示不按分组过滤）
/// @param keyword 搜索关键词（可选，nil或空字符串表示不搜索）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getContactListWithPage:(int)page
                     pageSize:(int)pageSize
                 relationship:(int)relationship
                       groupId:(int64_t)groupId
                       keyword:(NSString * _Nullable)keyword
                   completion:(IMSDKContactCompletion)completion;

/// 搜索联系人
/// @param keyword 搜索关键词
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)searchContactWithKeyword:(NSString *)keyword
                     completion:(IMSDKContactCompletion)completion;

// ==================== 好友申请 ====================

/// 获取好友申请列表
/// @param status 申请状态过滤（0=待处理, 1=已同意, 2=已拒绝, -1=全部）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getFriendRequestsWithStatus:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKContactCompletion)completion;

/// 同意好友申请
/// @param requestId 申请ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)acceptFriendRequestWithId:(int64_t)requestId
                      completion:(IMSDKContactCompletion)completion;

/// 拒绝好友申请
/// @param requestId 申请ID
/// @param reason 拒绝原因（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)rejectFriendRequestWithId:(int64_t)requestId
                          reason:(NSString * _Nullable)reason
                      completion:(IMSDKContactCompletion)completion;

// ==================== 联系人分组 ====================

/// 获取联系人分组列表
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getContactGroupsWithPage:(int)page
                       pageSize:(int)pageSize
                     completion:(IMSDKContactCompletion)completion;

/// 创建联系人分组
/// @param groupName 分组名称（必填）
/// @param groupColor 分组颜色（可选）
/// @param groupOrder 排序权重（可选）
/// @param groupIcon 分组图标（可选）
/// @param groupDescription 分组描述（可选）
/// @param userIds 用户ID列表（可选，创建分组时批量添加的联系人）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)createContactGroupWithName:(NSString *)groupName
                        groupColor:(NSString * _Nullable)groupColor
                        groupOrder:(int32_t)groupOrder
                         groupIcon:(NSString * _Nullable)groupIcon
                   groupDescription:(NSString * _Nullable)groupDescription
                           userIds:(NSArray<NSString *> * _Nullable)userIds
                      completion:(IMSDKContactCompletion)completion;

/// 更新联系人分组
/// @param groupId 分组ID（必填）
/// @param groupName 分组名称（可选）
/// @param groupColor 分组颜色（可选）
/// @param groupOrder 排序权重（可选）
/// @param groupIcon 分组图标（可选）
/// @param groupDescription 分组描述（可选）
/// @param completion 结果回调
- (int)updateContactGroupWithId:(int64_t)groupId
                      groupName:(NSString * _Nullable)groupName
                      groupColor:(NSString * _Nullable)groupColor
                      groupOrder:(int32_t)groupOrder
                       groupIcon:(NSString * _Nullable)groupIcon
                 groupDescription:(NSString * _Nullable)groupDescription
                      completion:(IMSDKContactCompletion)completion;

/// 删除联系人分组
/// @param groupId 分组ID（必填）
/// @param completion 结果回调
- (int)deleteContactGroupWithId:(int64_t)groupId
                      completion:(IMSDKContactCompletion)completion;

/// 移动联系人到分组
/// @param contactUserId 联系人用户ID（必填）
/// @param groupId 目标分组ID（必填，0表示移除分组）
/// @param completion 结果回调
- (int)moveContactToGroupWithContactUserId:(NSString *)contactUserId
                                    groupId:(int64_t)groupId
                                 completion:(IMSDKContactCompletion)completion;

// ==================== 联系人备注 ====================

/// 设置联系人备注
/// @param userId 联系人用户ID
/// @param remark 备注名称
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)setRemarkForUserId:(NSString *)userId remark:(NSString *)remark completion:(IMSDKContactCompletion)completion;

@end

NS_ASSUME_NONNULL_END

