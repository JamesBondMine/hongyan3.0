//
//  IMSDKCommunityManager.h
//  Runner
//
//  IM SDK 社群管理类 - 社群列表、加入、退出等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 社群操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKCommunityCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 社群管理类
@interface IMSDKCommunityManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 社群查询 ====================

/// 获取社群列表
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCommunityListWithPage:(int)page
                        pageSize:(int)pageSize
                      completion:(IMSDKCommunityCompletion)completion;

/// 获取社群信息
/// @param cmtyId 社群ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCommunityInfoWithCmtyId:(NSString *)cmtyId
                        completion:(IMSDKCommunityCompletion)completion;

/// 加入社群
/// @param cmtyId 社群ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)joinCommunityWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion;


/// 离开社群
/// /// @param cmtyId 社群ID
- (int)leaveCommunityWithCmtyId:(NSString *)cmtyId
                     completion:(IMSDKCommunityCompletion)completion;

// ==================== 分组和频道 ====================

/// 获取分组列表
/// @param cmtyId 社群ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getCommunityGroupsWithCmtyId:(NSString *)cmtyId
                          completion:(IMSDKCommunityCompletion)completion;

/// 获取频道列表
/// @param cmtyId 社群ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getChannelsWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion;

/// 创建频道
/// @param cmtyId 社群ID
/// @param categoryId 分类ID
/// @param channelName 频道名称
/// @param channelType 频道类型（0=文字频道，1=语音频道）
/// @param description 频道描述（可选）
/// @param maxMembers 最大成员数（可选，语音频道默认50）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)createChannelWithCmtyId:(NSString *)cmtyId
                      categoryId:(NSString *)categoryId
                      channelName:(NSString *)channelName
                      channelType:(int)channelType
                      description:(NSString * _Nullable)description
                      maxMembers:(int32_t)maxMembers
                      completion:(IMSDKCommunityCompletion)completion;

@end

NS_ASSUME_NONNULL_END

