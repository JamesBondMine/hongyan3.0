//
//  IMSDKManager.h
//  Runner
//
//  IM SDK 管理类 - Objective-C++ 封装
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// IM SDK 管理类（单例）
@interface IMSDKManager : NSObject

/// 单例实例
+ (instancetype)sharedManager;

// ==================== SDK 初始化 ====================

/// 初始化 SDK（推荐优先调用此方法）
/// @param config SDK 配置（JSON 格式，可选）
/// @return 0表示成功，其他为错误码
- (int)initSDKWithConfig:(NSString *)config;

// ==================== 网络库管理 ====================

/// 初始化网络库（底层初始化，如果 initSDK 失败可尝试）
/// @return 0表示成功，其他为错误码
- (int)initializeNetwork;

/// 启动网络服务
/// @return 0表示成功，其他为错误码
- (int)startNetwork;

/// 启动网络检查
/// @param url 检查的 URL
/// @return 0表示成功，其他为错误码
- (int)startNetworkCheckWithURL:(NSString *)url;

/// 设置 IP 地址表
/// @param ips IP 地址数组
- (void)setIPTable:(NSArray<NSString *> *)ips;

/// 获取 IP 延迟状态
/// @return IP 延迟数组（毫秒）
- (NSArray<NSNumber *> *)getIPStatus;

/// 停止网络服务
- (void)stopNetwork;

/// 清理网络库
- (void)cleanupNetwork;

// ==================== 回调管理 ====================

/// 设置网络事件回调
/// @param callback 回调 block
- (void)setNetworkEventCallback:(void (^)(uint8_t eventCode, NSString *eventDesc))callback;

/// 设置数据接收回调
/// @param callback 回调 block
- (void)setDataReceivedCallback:(void (^)(NSString *data))callback;

// ==================== 连接管理 ====================

/// 添加目标服务器到组
/// @param ip IP 地址
/// @param port 端口号
- (void)addTargetToGroupWithIP:(NSString *)ip port:(int)port;

/// 触发立即重连
/// @param resetRetryCount 是否重置重试计数
/// @return 0表示成功
- (int)triggerImmediateReconnect:(BOOL)resetRetryCount;

// ==================== 消息管理 ====================

/// 发送消息
/// @param messageId 消息ID
/// @param content 消息内容
/// @param contentLen 内容长度
/// @param msgType 消息类型
/// @param senderId 发送者ID
/// @param receiverId 接收者ID
/// @return 0表示成功
- (int)sendMessageWithId:(NSString *)messageId
                 content:(NSData *)content
                 msgType:(int)msgType
                senderId:(NSString *)senderId
              receiverId:(NSString *)receiverId;

// ==================== 事件循环 ====================

/// 主线程事件驱动（需要定期调用）
- (void)runEventLoop;

@end

NS_ASSUME_NONNULL_END

