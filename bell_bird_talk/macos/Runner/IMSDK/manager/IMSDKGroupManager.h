//
//  IMSDKGroupManager.h
//  Runner
//
//  IM SDK 群组管理类 - 群组创建、加入、成员管理等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 群组操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKGroupCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 群组管理类
@interface IMSDKGroupManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 群组创建和管理 ====================

/// 创建群组
/// @param groupName 群组名称（必填）
/// @param groupAvatar 群组头像URL（可选）
/// @param groupDescription 群组描述（可选）
/// @param groupType 群组类型：0=普通群, 1=超级群（可选，默认0）
/// @param maxMemberCount 最大成员数（可选，默认500）
/// @param initialMembers 初始成员ID列表（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
///
- (int)createGroupWithName:(NSString *)groupName
                groupAvatar:(NSString * _Nullable)groupAvatar
           groupDescription:(NSString * _Nullable)groupDescription
                   groupType:(int)groupType
              maxMemberCount:(int32_t)maxMemberCount
             initialMembers:(NSArray<NSString *> * _Nullable)initialMembers
                  completion:(IMSDKGroupCompletion)completion;

/// 加入群组（申请加入）
/// @param groupId 群组ID（必填）
/// @param requestMessage 申请理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)joinGroupWithId:(NSString *)groupId
        requestMessage:(NSString * _Nullable)requestMessage
             completion:(IMSDKGroupCompletion)completion;

/// 获取群组信息
/// @param groupId 群组ID（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getGroupInfoWithId:(NSString *)groupId
               completion:(IMSDKGroupCompletion)completion;

/// 更新群组信息
/// @param groupId 群组ID（必填）
/// @param groupName 群组名称（可选）
/// @param groupAvatar 群组头像URL（可选）
/// @param groupAnnouncement 群组公告（可选）
/// @param groupDescription 群组描述（可选）
/// @param version 乐观锁版本号（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)updateGroupWithId:(NSString *)groupId
               groupName:(NSString * _Nullable)groupName
              groupAvatar:(NSString * _Nullable)groupAvatar
        groupAnnouncement:(NSString * _Nullable)groupAnnouncement
          groupDescription:(NSString * _Nullable)groupDescription
                  version:(int32_t)version
               completion:(IMSDKGroupCompletion)completion;

/// 解散群组
/// @param groupId 群组ID（必填）
/// @param reason 解散原因（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)dissolveGroupWithId:(NSString *)groupId
                    reason:(NSString * _Nullable)reason
                completion:(IMSDKGroupCompletion)completion;

/// 退出群组
/// @param groupId 群组ID（必填）
/// @param reason 退出原因（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)leaveGroupWithId:(NSString *)groupId
                 reason:(NSString * _Nullable)reason
             completion:(IMSDKGroupCompletion)completion;

// ==================== 群组成员管理 ====================

/// 添加群组成员
/// @param groupId 群组ID（必填）
/// @param userIds 用户ID列表（必填）
/// @param reason 邀请理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)addGroupMembersWithGroupId:(NSString *)groupId
                          userIds:(NSArray<NSString *> *)userIds
                            reason:(NSString * _Nullable)reason
                        completion:(IMSDKGroupCompletion)completion;

/// 移除群组成员
/// @param groupId 群组ID（必填）
/// @param userIds 用户ID列表（必填）
/// @param reason 移除理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)removeGroupMembersWithGroupId:(NSString *)groupId
                             userIds:(NSArray<NSString *> *)userIds
                               reason:(NSString * _Nullable)reason
                           completion:(IMSDKGroupCompletion)completion;

/// 获取群组成员列表
/// @param groupId 群组ID（必填）
/// @param status 成员状态过滤：0=正常, 1=被踢, 2=主动退出, -1=全部（可选，默认0）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getGroupMembersWithGroupId:(NSString *)groupId
                            status:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKGroupCompletion)completion;

/// 设置群内昵称
/// @param groupId 群组ID（必填）
/// @param memberAlias 群内昵称（必填，字符范围【2，50】）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)setGroupMemberAliasWithGroupId:(NSString *)groupId
                          memberAlias:(NSString *)memberAlias
                           completion:(IMSDKGroupCompletion)completion;

// ==================== 群组查询 ====================

/// 获取群组列表
/// @param groupType 群组类型过滤：0=普通群, 1=超级群, -1=全部（可选，默认-1）
/// @param status 群组状态过滤：0=正常, 1=禁用, 2=解散, -1=全部（可选，默认0）
/// @param keyword 搜索关键词（可选）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getGroupListWithType:(int)groupType
                     status:(int)status
                    keyword:(NSString * _Nullable)keyword
                      page:(int)page
                  pageSize:(int)pageSize
                completion:(IMSDKGroupCompletion)completion;

// ==================== 群组申请和审批 ====================

/// 获取加入申请列表
/// @param groupId 群组ID（必填）
/// @param status 申请状态过滤：0=待审批, 1=已通过, 2=已拒绝, 3=已过期, 4=已取消, -1=全部（可选，默认0）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getJoinRequestsWithGroupId:(NSString *)groupId
                            status:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKGroupCompletion)completion;

/// 审批加入申请（通过）
/// @param groupId 群组ID（必填）
/// @param applicantId 申请人ID（必填）
/// @param reviewMessage 审批意见（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)approveJoinRequestWithGroupId:(NSString *)groupId
                          applicantId:(NSString *)applicantId
                        reviewMessage:(NSString * _Nullable)reviewMessage
                           completion:(IMSDKGroupCompletion)completion;

/// 拒绝加入申请
/// @param groupId 群组ID（必填）
/// @param applicantId 申请人ID（必填）
/// @param reviewMessage 拒绝理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)rejectJoinRequestWithGroupId:(NSString *)groupId
                         applicantId:(NSString *)applicantId
                       reviewMessage:(NSString * _Nullable)reviewMessage
                          completion:(IMSDKGroupCompletion)completion;

// ==================== 群组策略和权限 ====================

/// 获取群组策略
/// @param groupId 群组ID（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getGroupPolicyWithGroupId:(NSString *)groupId
                       completion:(IMSDKGroupCompletion)completion;

/// 设置群组策略
/// @param groupId 群组ID（必填）
/// @param policy 群组策略字典（可选字段：needVerify, allowInvite, allowAddFriend, showMemberList, allowPrivateChat, enableAudioVideoCall, showHistoryMessage, showQrCode, messageNotification, allowSearchMember, speakIntervalSec, muteRoles）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)setGroupPolicyWithGroupId:(NSString *)groupId
                           policy:(NSDictionary * _Nullable)policy
                       completion:(IMSDKGroupCompletion)completion;

/// 设置全员禁言
/// @param groupId 群组ID（必填）
/// @param mute 是否全员禁言（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)setGroupMuteWithGroupId:(NSString *)groupId
                          mute:(BOOL)mute
                    completion:(IMSDKGroupCompletion)completion;

/// 禁言成员
/// @param groupId 群组ID（必填）
/// @param userId 用户ID（必填）
/// @param muteUntil 禁言到期时间戳（必填，0表示永久禁言）
/// @param reason 禁言理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)muteGroupMemberWithGroupId:(NSString *)groupId
                            userId:(NSString *)userId
                         muteUntil:(int64_t)muteUntil
                             reason:(NSString * _Nullable)reason
                         completion:(IMSDKGroupCompletion)completion;

/// 查询禁言状态
/// @param groupId 群组ID（必填）
/// @param userId 用户ID（可选，不填则查询群组状态）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getMuteStatusWithGroupId:(NSString *)groupId
                          userId:(NSString * _Nullable)userId
                      completion:(IMSDKGroupCompletion)completion;

// ==================== 群主转让 ====================

/// 转让群主
/// @param groupId 群组ID（必填）
/// @param newOwnerId 新群主ID（必填）
/// @param keepAsAdmin 原群主是否保持管理员身份（可选，默认true）
/// @param reason 转让理由（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)transferGroupOwnerWithGroupId:(NSString *)groupId
                          newOwnerId:(NSString *)newOwnerId
                         keepAsAdmin:(BOOL)keepAsAdmin
                               reason:(NSString * _Nullable)reason
                           completion:(IMSDKGroupCompletion)completion;

// ==================== 群组免打扰 ====================

/// 设置群组免打扰
/// @param groupId 群组ID（必填）
/// @param disturb 是否免打扰（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)setGroupDisturbWithGroupId:(NSString *)groupId
                            disturb:(BOOL)disturb
                        completion:(IMSDKGroupCompletion)completion;

/// 查询群组免打扰状态
/// @param groupId 群组ID（必填）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getGroupDisturbStatusWithGroupId:(NSString *)groupId
userId:(NSString *)userId
                             completion:(IMSDKGroupCompletion)completion;


- (int)getGroupPerviewWithId:(NSString *)groupId
                  completion:(IMSDKGroupCompletion)completion;
@end

NS_ASSUME_NONNULL_END

