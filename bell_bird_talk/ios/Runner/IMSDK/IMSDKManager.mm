//
//  IMSDKManager.mm
//  Runner
//
//  IM SDK 管理类实现 - Objective-C++
//

#import "IMSDKManager.h"

// 仅在真机上引入 C++ SDK 头文件
#if TARGET_OS_SIMULATOR
    // 模拟器环境 - 不引入 C++ SDK
    #warning "IM SDK 不支持模拟器，请在真机上测试 IM SDK 功能"
#else
    // 真机环境 - 引入 C++ SDK
    #include "network_lib.h"
    #include "callback_types.h"
    #include "common_definitions.h"
#endif

@interface IMSDKManager ()

@property (nonatomic, copy) void (^networkEventCallback)(uint8_t eventCode, NSString *eventDesc);
@property (nonatomic, copy) void (^dataReceivedCallback)(NSString *data);

@end

@implementation IMSDKManager

// ==================== 单例模式 ====================

+ (instancetype)sharedManager {
    static IMSDKManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"📱 IMSDKManager 初始化");
    }
    return self;
}

// ==================== 网络库管理 ====================

- (int)initializeNetwork {
    NSLog(@"🔧 初始化网络库");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK，请在真机上测试");
    return 0; // 模拟器错误码
// #else
//     int result = network_init();
//     NSLog(@"📊 初始化结果: %d", result);
//     return result;
// #endif
}

- (int)startNetwork {
    NSLog(@"🚀 启动网络服务");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
    return 0;
// #else
//     int result = network_start();
//     NSLog(@"📊 启动结果: %d", result);
//     return result;
// #endif
}

- (int)startNetworkCheckWithURL:(NSString *)url {
    NSLog(@"🔍 启动网络检查: %@", url);
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
    return 0;
// #else
//     const char *cUrl = [url UTF8String];
//     int result = network_start_net_check(cUrl);
//     NSLog(@"📊 检查结果: %d", result);
//     return result;
// #endif
}

- (void)setIPTable:(NSArray<NSString *> *)ips {
    NSLog(@"🌐 设置 IP 地址表: %lu 个", (unsigned long)ips.count);
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
// #else
//     // 转换 NSArray 为 C 字符串数组
//     const char **cIps = (const char **)malloc(ips.count * sizeof(char *));
//     for (NSUInteger i = 0; i < ips.count; i++) {
//         cIps[i] = [ips[i] UTF8String];
//     }
    
//     network_set_ip_table(cIps, (uint32_t)ips.count);
    
//     free(cIps);
// #endif
}

- (NSArray<NSNumber *> *)getIPStatus {
    NSLog(@"📊 获取 IP 延迟状态");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
    return @[@(-999), @(-999), @(-999)]; // 返回模拟数据
// #else
//     // 假设最多支持 10 个 IP
//     const int maxCount = 10;
//     int latencies[maxCount];
    
//     network_get_ip_status(latencies, maxCount);
    
//     NSMutableArray<NSNumber *> *result = [NSMutableArray array];
//     for (int i = 0; i < maxCount; i++) {
//         [result addObject:@(latencies[i])];
//     }
    
//     return [result copy];
// #endif
}

- (void)stopNetwork {
    NSLog(@"🛑 停止网络服务");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
// #else
//     network_stop();
// #endif
}

- (void)cleanupNetwork {
    NSLog(@"🧹 清理网络库");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
// #else
//     network_cleanup();
// #endif
}

// ==================== 回调管理 ====================

// #if !TARGET_OS_SIMULATOR
// // C 函数回调 - 网络事件（仅真机）
// static void NetworkEventCallbackWrapper(uint8_t event_code, const char* event_desc, uint32_t length) {
//     IMSDKManager *manager = [IMSDKManager sharedManager];
//     if (manager.networkEventCallback) {
//         NSString *desc = event_desc ? [NSString stringWithUTF8String:event_desc] : @"";
//         dispatch_async(dispatch_get_main_queue(), ^{
//             manager.networkEventCallback(event_code, desc);
//         });
//     }
// }

// // C 函数回调 - 数据接收（仅真机）
// static void DataReceivedCallbackWrapper(const char* data, uint32_t length) {
//     IMSDKManager *manager = [IMSDKManager sharedManager];
//     if (manager.dataReceivedCallback) {
//         NSString *dataStr = [[NSString alloc] initWithBytes:data 
//                                                      length:length 
//                                                    encoding:NSUTF8StringEncoding];
//         dispatch_async(dispatch_get_main_queue(), ^{
//             manager.dataReceivedCallback(dataStr);
//         });
//     }
// }
// #endif

- (void)setNetworkEventCallback:(void (^)(uint8_t, NSString *))callback {
    self.networkEventCallback = callback;
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK 回调");
// #else
//     network_set_event_callback(NetworkEventCallbackWrapper);
//     NSLog(@"✅ 网络事件回调已设置");
// #endif
}

- (void)setDataReceivedCallback:(void (^)(NSString *))callback {
    self.dataReceivedCallback = callback;
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK 回调");
// #else
//     network_set_data_callback(DataReceivedCallbackWrapper);
//     NSLog(@"✅ 数据接收回调已设置");
// #endif
}

// ==================== 连接管理 ====================

- (void)addTargetToGroupWithIP:(NSString *)ip port:(int)port {
    NSLog(@"➕ 添加目标服务器: %@:%d", ip, port);
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
// #else
//     const char *cIp = [ip UTF8String];
//     network_add_target_to_group(cIp, port);
// #endif
}

- (int)triggerImmediateReconnect:(BOOL)resetRetryCount {
    NSLog(@"🔄 触发立即重连 (重置计数: %@)", resetRetryCount ? @"是" : @"否");
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
    return -999;
// #else
//     int result = network_trigger_immediate_reconnect(resetRetryCount);
//     NSLog(@"📊 重连结果: %d", result);
//     return result;
// #endif
}

// ==================== 消息管理 ====================

- (int)sendMessageWithId:(NSString *)messageId
                 content:(NSData *)content
                 msgType:(int)msgType
                senderId:(NSString *)senderId
              receiverId:(NSString *)receiverId {
    
    NSLog(@"📤 发送消息: %@ -> %@", senderId, receiverId);
// #if TARGET_OS_SIMULATOR
    NSLog(@"⚠️ 模拟器不支持 IM SDK");
    return -999;
// #else
//     // 这里需要根据实际 SDK 的消息发送接口来实现
//     // 示例代码，实际需要查看 network_lib.h 中的消息发送函数
    
//     return 0; // 返回发送结果
// #endif
}

// ==================== 事件循环 ====================

- (void)runEventLoop {
// #if TARGET_OS_SIMULATOR
//     // 模拟器不执行事件循环
// #else
//     network_event_loop();
// #endif
}

@end

