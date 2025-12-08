//
//  IMSDKConversationManager.h
//  Runner
//
//  IM SDK 会话管理类 - 会话列表、创建会话、删除会话等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 会话类型
typedef NS_ENUM(NSInteger, IMConversationType) {
    IMConversationTypeSingle = 0,      // 单聊
    IMConversationTypeGroup = 2,       // 群聊
    IMConversationTypeSystem = 3,      // 系统
    IMConversationTypeCommunity = 4,   // 社区
};

/// 会话操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKConversationCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 会话管理类
@interface IMSDKConversationManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 会话列表 ====================

/// 获取会话列表
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param convType 会话类型过滤（可选，-1表示不过滤）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getConversationListWithPage:(int)page
                          pageSize:(int)pageSize
                          convType:(IMConversationType)convType
                        completion:(IMSDKConversationCompletion)completion;

/// 获取会话列表（不过滤类型）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getConversationListWithPage:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKConversationCompletion)completion;

// ==================== 会话操作 ====================

/// 获取单个会话
/// @param convId 会话ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)getConversationWithId:(NSString *)convId
                  completion:(IMSDKConversationCompletion)completion;

/// 创建会话
/// @param convType 会话类型
/// @param targetId 目标ID（单聊为对方用户ID，群聊为群ID）
/// @param displayName 显示名称
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)createConversationWithType:(IMConversationType)convType
                         targetId:(NSString *)targetId
                      displayName:(NSString *)displayName
                       completion:(IMSDKConversationCompletion)completion;

/// 创建会话（使用字典参数）
/// @param params 参数字典，支持以下字段：
///   - conv_type: 会话类型（必填）
///   - target_id: 目标ID（必填）
///   - display_name: 显示名称（必填）
///   - avatar_url: 头像URL（可选）
///   - description: 描述（可选）
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)createConversationWithParams:(NSDictionary *)params
                         completion:(IMSDKConversationCompletion)completion;

/// 删除会话
/// @param convId 会话ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)deleteConversationWithId:(NSString *)convId
                     completion:(IMSDKConversationCompletion)completion;

/// 清空会话消息
/// @param convId 会话ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)clearConversationMessagesWithId:(NSString *)convId
                            completion:(IMSDKConversationCompletion)completion;

/// 标记会话已读
/// @param convId 会话ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)markConversationReadWithId:(NSString *)convId
                       completion:(IMSDKConversationCompletion)completion;

/// 更新会话信息
/// @param convId 会话ID
/// @param params 更新参数字典，支持以下字段：
///   - display_name: 显示名称
///   - avatar_url: 头像URL
///   - description: 描述
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)updateConversationWithId:(NSString *)convId
                         params:(NSDictionary *)params
                     completion:(IMSDKConversationCompletion)completion;

@end

NS_ASSUME_NONNULL_END

