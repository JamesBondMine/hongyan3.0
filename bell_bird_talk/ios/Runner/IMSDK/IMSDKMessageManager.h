//
//  IMSDKMessageManager.h
//  Runner
//
//  IM SDK 消息管理类 - 发送消息、获取历史消息等
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 消息类型
typedef NS_ENUM(NSInteger, IMMessageType) {
    IMMessageTypeText = 0,          // 文本消息
    IMMessageTypeImage = 1,         // 图片消息
    IMMessageTypeVideo = 2,         // 视频消息
    IMMessageTypeVoice = 3,         // 语音消息
    IMMessageTypeFile = 4,          // 文件消息
    IMMessageTypeLocation = 5,      // 位置消息
    IMMessageTypeCard = 6,          // 名片消息
    IMMessageTypeShareURL = 7,      // 分享链接消息
    IMMessageTypeSticker = 8,       // 表情消息
    IMMessageTypeCustom = 9,        // 自定义消息
};

/// 消息操作结果回调
/// @param errorCode 错误码，0表示成功
/// @param reqId 请求ID
/// @param data 返回数据（JSON 格式）
typedef void (^IMSDKMessageCompletion)(int errorCode, uint64_t reqId, NSString * _Nullable data);

/// IM SDK 消息管理类
@interface IMSDKMessageManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

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

// ==================== 回调管理（内部使用） ====================

/// 设置回调
- (void)setCallback:(IMSDKMessageCompletion)callback forReqId:(uint64_t)reqId;

/// 获取回调
- (IMSDKMessageCompletion _Nullable)getCallbackForReqId:(uint64_t)reqId;

/// 移除回调
- (void)removeCallbackForReqId:(uint64_t)reqId;

@end

NS_ASSUME_NONNULL_END

