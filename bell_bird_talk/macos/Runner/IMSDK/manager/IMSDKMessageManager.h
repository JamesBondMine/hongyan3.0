//
//  IMSDKMessageManager.h
//  Runner
//
//  IM SDK 消息管理类 - 发送消息、获取历史消息等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 消息类型枚举
typedef NS_ENUM(NSInteger, IMMessageConvType) {
    IMMessageConvTypeSingle = 0,      // 单聊消息
    IMMessageConvTypeGroup = 2,       // 群聊消息
    IMMessageConvTypeCommunity = 4,   // 社区消息
};

/// 消息操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKMessageCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// 收到消息回调
/// @param convType 会话类型（单聊/群聊/社区）
/// @param messageData 消息数据（解析后的字典）
typedef void (^IMSDKMessageReceivedCallback)(IMMessageConvType convType, NSDictionary *messageData);

/// 系统消息回调
/// @param messageData 消息数据（解析后的字典）
typedef void (^IMSDKSystemMessageCallback)(NSDictionary *messageData);

/// 命令消息回调
/// @param eventType 命令类型
/// @param messageData 消息数据（解析后的字典）
typedef void (^IMSDKCommandMessageCallback)(int eventType, NSDictionary *messageData);

/// IM SDK 消息管理类
@interface IMSDKMessageManager : NSObject

/// 收到消息的回调（统一回调，包含会话类型）
@property (nonatomic, copy, nullable) IMSDKMessageReceivedCallback onMessageReceived;

/// 系统消息回调
@property (nonatomic, copy, nullable) IMSDKSystemMessageCallback onSystemMessage;

/// 命令消息回调
@property (nonatomic, copy, nullable) IMSDKCommandMessageCallback onCommandMessage;

/// 单例实例
+ (instancetype)sharedManager;

// ==================== 消息监听注册 ====================

/// 注册所有消息回调（单聊、群聊、社区）
/// 应在进入首页时调用
- (void)registerMessageCallbacks;

/// 取消注册所有消息回调
- (void)unregisterMessageCallbacks;

// ==================== 发送消息 ====================

/// 发送文本消息
/// @param content 文本内容
/// @param conversationId 会话ID
/// @param receiverId 接收者ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendTextMessage:(NSString *)content
        conversationId:(NSString *)conversationId
            receiverId:(NSString *)receiverId
            completion:(IMSDKMessageCompletion)completion;

/// 发送文本消息（扩展）
/// @param content 文本内容
/// @param ext 扩展字段
/// @param conversationId 会话ID
/// @param receiverId 接收者ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendTextMessage:(NSString *)content
                   ext:(NSString * _Nullable)ext
        conversationId:(NSString *)conversationId
            receiverId:(NSString *)receiverId
            completion:(IMSDKMessageCompletion)completion;

/// 发送图片消息
/// @param imageUrl 图片URL
/// @param thumbnailUrl 缩略图URL（可选）
/// @param width 图片宽度（可选）
/// @param height 图片高度（可选）
/// @param conversationId 会话ID
/// @param receiverId 接收者ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendImageMessage:(NSString *)imageUrl
            thumbnailUrl:(NSString * _Nullable)thumbnailUrl
                  width:(int32_t)width
                 height:(int32_t)height
         conversationId:(NSString *)conversationId
             receiverId:(NSString *)receiverId
             completion:(IMSDKMessageCompletion)completion;

/// 发送语音消息
/// @param audioUrl 语音文件URL
/// @param duration 语音时长（秒）
/// @param conversationId 会话ID
/// @param receiverId 接收者ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendVoiceMessage:(NSString *)audioUrl
                duration:(int32_t)duration
          conversationId:(NSString *)conversationId
              receiverId:(NSString *)receiverId
              completion:(IMSDKMessageCompletion)completion;

/// 发送视频消息
/// @param videoUrl 视频文件URL
/// @param coverURL 封面图URL（可选）
/// @param duration 视频时长（秒，可选）
/// @param width 视频宽度（可选）
/// @param height 视频高度（可选）
/// @param size 视频文件大小（字节，可选）
/// @param conversationId 会话ID
/// @param receiverId 接收者ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendVideoMessage:(NSString *)videoUrl
               coverURL:(NSString * _Nullable)coverURL
               duration:(int32_t)duration
                  width:(int32_t)width
                 height:(int32_t)height
                   size:(int64_t)size
         conversationId:(NSString *)conversationId
             receiverId:(NSString *)receiverId
             completion:(IMSDKMessageCompletion)completion;

// ==================== 群聊消息发送 ====================

/// 发送群聊文本消息
/// @param content 文本内容
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendGroupTextMessage:(NSString *)content
            conversationId:(NSString *)conversationId
                   groupId:(NSString *)groupId
                completion:(IMSDKMessageCompletion)completion;

/// 发送群聊图片消息
/// @param imageUrl 图片URL
/// @param thumbnailUrl 缩略图URL（可选）
/// @param width 图片宽度（可选）
/// @param height 图片高度（可选）
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendGroupImageMessage:(NSString *)imageUrl
                thumbnailUrl:(NSString * _Nullable)thumbnailUrl
                      width:(int32_t)width
                     height:(int32_t)height
             conversationId:(NSString *)conversationId
                    groupId:(NSString *)groupId
                 completion:(IMSDKMessageCompletion)completion;

/// 发送群聊语音消息
/// @param audioUrl 语音文件URL
/// @param duration 语音时长（秒）
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendGroupVoiceMessage:(NSString *)audioUrl
                    duration:(int32_t)duration
              conversationId:(NSString *)conversationId
                     groupId:(NSString *)groupId
                  completion:(IMSDKMessageCompletion)completion;

/// 发送群聊视频消息
/// @param videoUrl 视频文件URL
/// @param coverURL 封面图URL（可选）
/// @param duration 视频时长（秒）
/// @param width 视频宽度（可选）
/// @param height 视频高度（可选）
/// @param size 视频文件大小（字节，可选）
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendGroupVideoMessage:(NSString *)videoUrl
                     coverURL:(NSString * _Nullable)coverURL
                     duration:(int32_t)duration
                        width:(int32_t)width
                       height:(int32_t)height
                         size:(int64_t)size
               conversationId:(NSString *)conversationId
                      groupId:(NSString *)groupId
                   completion:(IMSDKMessageCompletion)completion;

/// 发送群聊@消息
/// @param content 消息内容
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param atInfoList @成员信息列表，格式：[{'user_id': 'xxx', 'nickname': 'xxx'}]
/// @param isAll 是否@所有人
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendGroupAtMessage:(NSString *)content
          conversationId:(NSString *)conversationId
                 groupId:(NSString *)groupId
              atInfoList:(NSArray<NSDictionary *> *)atInfoList
                   isAll:(BOOL)isAll
              completion:(IMSDKMessageCompletion)completion;

// ==================== 频道发言 ====================

/// 发送频道文本消息（频道发言）
/// @param content 文本内容
/// @param ext 扩展字段（可选）
/// @param cmtyId 社群ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)sendChannelMessage:(NSString *)content
                      ext:(NSString * _Nullable)ext
                   cmtyId:(NSString *)cmtyId
               completion:(IMSDKMessageCompletion)completion;

// ==================== 删除消息 ====================

/// 删除消息
/// @param conversationId 会话ID
/// @param clientMsgId 客户端消息ID
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)deleteMessage:(NSString *)conversationId
          clientMsgId:(NSString *)clientMsgId
           completion:(IMSDKMessageCompletion)completion;

// ==================== 拉取历史消息 ====================

/// 拉取历史消息
/// @param conversationId 会话ID
/// @param convType 会话类型（0=单聊, 2=群聊）
/// @param targetId 目标ID（单聊为对方用户ID）
/// @param lastSeq 最后消息序号（0表示从最新开始拉取）
/// @param limit 拉取数量限制
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)pullMessagesWithConversationId:(NSString *)conversationId
                             convType:(int)convType
                             targetId:(NSString *)targetId
                              lastSeq:(int64_t)lastSeq
                                limit:(int)limit
                           completion:(IMSDKMessageCompletion)completion;

/// 拉取群聊历史消息
/// @param conversationId 会话ID
/// @param groupId 群组ID
/// @param lastSeq 最后消息序号（0表示从最新开始拉取）
/// @param limit 拉取数量限制
/// @param completion 结果回调
/// @return 0表示请求发送成功，其他为错误码
- (int)pullGroupMessagesWithConversationId:(NSString *)conversationId
                                   groupId:(NSString *)groupId
                                  lastSeq:(int64_t)lastSeq
                                    limit:(int)limit
                               completion:(IMSDKMessageCompletion)completion;

// ==================== 通知 ====================

/// 获取通知未读数量
/// @param notificationTypes 通知类型过滤（可选）
/// @param completion 结果回调
- (int)getNotificationUnreadCountWithTypes:(NSArray<NSString *> * _Nullable)notificationTypes
                                completion:(IMSDKMessageCompletion)completion;

/// 拉取通知列表
/// @param notificationTypes 通知类型过滤（可选）
/// @param page 页码（从1开始）
/// @param pageSize 每页数量
/// @param completion 结果回调
- (int)pullNotificationsWithTypes:(NSArray<NSString *> * _Nullable)notificationTypes
                             page:(int32_t)page
                             state:(int32_t)state
                         pageSize:(int32_t)pageSize
                        completion:(IMSDKMessageCompletion)completion;

/// 标记通知已读
/// @param notificationIds 通知ID列表
/// @param readTime 读取时间（毫秒，可选，默认当前时间）
/// @param completion 结果回调
- (int)markNotificationsRead:(NSArray<NSNumber *> *)notificationIds
                    readTime:(int64_t)readTime
                           completion:(IMSDKMessageCompletion)completion;

// ==================== 回调管理（内部使用） ====================

/// 设置回调
- (void)setCallback:(IMSDKMessageCompletion)callback forReqId:(uint64_t)reqId;

/// 获取回调
- (IMSDKMessageCompletion _Nullable)getCallbackForReqId:(uint64_t)reqId;

/// 移除回调
- (void)removeCallbackForReqId:(uint64_t)reqId;

@end

NS_ASSUME_NONNULL_END

