//
//  IMSDKManager.mm
//  Runner
//
//  IM SDK 管理类实现 - Objective-C++
//

#import "IMSDKManager.h"
#import "IMSDKAuthManager.h"
#import <UIKit/UIKit.h>
#include "network_lib.h"
#include "callback_types.h"
#include "common_definitions.h"

// 网络连通性测试相关
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

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

// ==================== SDK 初始化 ====================

- (int)initSDKWithConfig:(NSString *)config {
    NSLog(@"🚀 初始化 IM SDK（按照官方文档顺序）");
    @try {
        // 步骤1: 初始化网络库
        int result = network_init();
        if (result != 0) {
            NSLog(@"❌ network_init 失败: %d", result);
            return result;
        }
        
        // 步骤2: 设置客户端信息
        NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        set_client_info("ios", "16.0", [deviceId UTF8String], "Asia/Shanghai");
        NSLog(@"📱 设备ID: %@", deviceId);
        
        // 步骤3: 设置回调
        network_set_event_callback(GlobalEventCallback);
        network_set_data_callback(GlobalDataCallback);
        
        // 步骤4: 设置用户认证信息（从持久化存储中读取）
        NSDictionary<NSString *, NSString *> *authInfo = [IMSDKAuthManager loadAuthInfo];
        NSString *userId = authInfo[@"userId"];
        NSString *token = authInfo[@"token"];
        NSString *refreshToken = authInfo[@"refreshToken"];
        
        if (userId && token && refreshToken) {
            set_user_auth_info([userId UTF8String], [token UTF8String], [refreshToken UTF8String]);
            NSLog(@"✅ 已设置用户认证信息: userId=%@", userId);
        } else {
            NSLog(@"⚠️ 未找到持久化的认证信息，跳过设置");
            // 如果没有持久化的认证信息，传递空字符串
//            set_user_auth_info("", "", "");
        }
        
        // 步骤4: 启动网络服务
        int startResult = network_start();
        if (startResult != 0) {
            NSLog(@"❌ network_start 失败: %d", startResult);
            return startResult;
        }
        
        // 初始化信号量用于等待回调
        g_initSemaphore = dispatch_semaphore_create(0);
        g_initResult = -1;
        
         // 添加目标服务器
//        NSString *serverIP = @"175.178.227.41";
//        int serverPort = 8885;
//        
//        NSString *serverIP = @"10.226.7.239";
//        int serverPort = 5280;

        // 先测试服务器连通性
//        NSLog(@"🔍 正在测试服务器连通性: %@:%d", serverIP, serverPort);
//        BOOL isReachable = [self pingHost:serverIP port:serverPort timeout:3.0];
//        if (isReachable) {
//            NSLog(@"✅ 服务器可达: %@:%d", serverIP, serverPort);
//        } else {
//            NSLog(@"⚠️ 服务器可能不可达: %@:%d（继续尝试连接）", serverIP, serverPort);
//        }
        
//        NSLog(@"🌐 添加目标服务器: %@:%d", serverIP, serverPort);
//        network_add_target_to_group([serverIP UTF8String], serverPort);
//        NSLog(@"✅ 目标服务器已添加");
        
        network_set_httpdns_params(
                "222222",
                "222222.loadingworks.com",           // domain_name - 要解析的域名
                28,                                // type - 记录类型 (28 = AAAA记录)
                nullptr,
                nullptr,
                nullptr
            );

            // 配置 HttpDns 服务器（可配置多个备份服务器）
            network_add_httpdns_server("https://223.5.5.5/resolve");
        
        // 步骤5: 启动网络检测
        int checkResult = network_start_net_check();
        if (checkResult != 0) {
            NSLog(@"⚠️ network_start_net_check 失败: %d（不影响初始化）", checkResult);
        }
        
        // 等待初始化成功回调（event_code = 6），超时时间 10 秒
        NSLog(@"⏳ 等待 SDK 初始化成功回调 (event_code=6)...");
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC);
        long waitResult = dispatch_semaphore_wait(g_initSemaphore, timeout);
        
        if (waitResult == 0) {
            // 信号量被触发，检查结果
            if (g_initResult == 0) {
                NSLog(@"✅ SDK 初始化成功 (收到 event_code=6)");
                return 0;
            } else {
                NSLog(@"❌ SDK 初始化失败: 回调返回错误结果 %d", g_initResult);
                return g_initResult;
            }
        } else {
            // 超时
            NSLog(@"⏱️ SDK 初始化超时: 未收到 event_code=6 回调");
            g_initSemaphore = NULL; // 清理信号量
            return -1000; // 自定义超时错误码
        }
    } @catch (NSException *exception) {
        NSLog(@"❌ SDK 初始化异常: %@", exception);
        return -9999;
    }
}

// 全局回调函数（C 函数，SDK 需要）
static dispatch_semaphore_t g_initSemaphore = NULL;
static int g_initResult = -1;

static void GlobalEventCallback(uint8_t event_code, const char* event_desc, uint32_t length) {
    NSLog(@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    NSLog(@"🔔 网络事件回调");
    NSLog(@"   事件代码: %d", event_code);
    NSLog(@"   描述长度: %u", length);
    
    // 检查是否是初始化成功事件
    if (event_code == 6 && g_initSemaphore != NULL) {
        NSLog(@"🎉 SDK 初始化成功事件 (event_code=6)");
        g_initResult = 0;
        dispatch_semaphore_signal(g_initSemaphore);
        g_initSemaphore = NULL; // 重置信号量
    }
    
    if (event_desc && length > 0) {
        // 使用 length 创建字符串，确保完整读取
        NSString *descStr = [[NSString alloc] initWithBytes:event_desc 
                                                     length:length 
                                                   encoding:NSUTF8StringEncoding];
        NSLog(@"   事件描述: %@", descStr);
        
        // 尝试解析为 JSON（如果是 JSON 格式）
        NSData *jsonData = [descStr dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *error = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                        options:0 
                                                          error:&error];
            if (!error && jsonObj) {
                NSLog(@"   JSON 解析: %@", jsonObj);
            }
        }
    } else {
        NSLog(@"   事件描述: (空)");
    }
    NSLog(@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
}

static void GlobalDataCallback(const char* data, uint32_t length) {
    NSLog(@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    NSLog(@"📥 数据回调");
    NSLog(@"   数据长度: %u", length);
    
    if (data && length > 0) {
        // 使用 length 创建字符串
        NSString *dataStr = [[NSString alloc] initWithBytes:data 
                                                     length:length 
                                                   encoding:NSUTF8StringEncoding];
        NSLog(@"   数据内容: %@", dataStr);
        
        // 尝试解析为 JSON
        NSData *jsonData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *error = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                        options:NSJSONReadingMutableContainers 
                                                          error:&error];
            if (!error && jsonObj) {
                NSLog(@"   JSON 解析: %@", jsonObj);
            }
        }
    } else {
        NSLog(@"   数据内容: (空)");
    }
    NSLog(@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
}

// SDK 初始化回调
static void SDKInitCallback(int errorCode, const char* data, int dataLen) {
    NSLog(@"🔔 SDK 初始化回调: errorCode=%d, dataLen=%d", errorCode, dataLen);
    if (data && dataLen > 0) {
        NSString *dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
        NSLog(@"   数据: %@", dataStr);
    }
}



// ==================== 网络库管理 ====================

- (int)initializeNetwork {
    NSLog(@"🔧 初始化网络库（不推荐，请使用 initSDKWithConfig）");
    return [self initSDKWithConfig:nil];
}

- (int)startNetwork {
    NSLog(@"🚀 启动网络服务");
    int result = network_start();
    NSLog(@"📊 启动结果: %d", result);
    return result;
}

- (int)startNetworkCheckWithURL:(NSString *)url {
    NSLog(@"🔍 启动网络检查: %@", url);
    const char *cUrl = [url UTF8String];
    int result = network_start_net_check();
    NSLog(@"📊 检查结果: %d", result);
    return result;
}

- (void)setIPTable:(NSArray<NSString *> *)ips {
    NSLog(@"🌐 设置 IP 地址表: %lu 个", (unsigned long)ips.count);
    // 转换 NSArray 为 C 字符串数组
    const char **cIps = (const char **)malloc(ips.count * sizeof(char *));
    for (NSUInteger i = 0; i < ips.count; i++) {
        cIps[i] = [ips[i] UTF8String];
    }
    
    network_set_ip_table(cIps, (uint32_t)ips.count);
    
    free(cIps);
}

- (NSArray<NSNumber *> *)getIPStatus {
    NSLog(@"📊 获取 IP 延迟状态");
    // 假设最多支持 10 个 IP
    const int maxCount = 10;
    int latencies[maxCount];
    
    network_get_ip_status(latencies, maxCount);
    
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (int i = 0; i < maxCount; i++) {
        [result addObject:@(latencies[i])];
    }
    
    return [result copy];
}

- (void)stopNetwork {
    NSLog(@"🛑 停止网络服务");
    network_stop();
}

- (void)cleanupNetwork {
    NSLog(@"🧹 清理网络库");
    network_cleanup();
}

// ==================== 回调管理 ====================

// C 函数回调 - 网络事件
static void NetworkEventCallbackWrapper(uint8_t event_code, const char* event_desc, uint32_t length) {
    // 1. 先调用全局日志回调（总是执行，用于调试）
    GlobalEventCallback(event_code, event_desc, length);
    
    // 2. 如果有业务回调，再调用业务回调
    IMSDKManager *manager = [IMSDKManager sharedManager];
    if (manager.networkEventCallback) {
        NSString *desc = event_desc ? [[NSString alloc] initWithBytes:event_desc 
                                                                length:length 
                                                              encoding:NSUTF8StringEncoding] : @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            manager.networkEventCallback(event_code, desc);
        });
    }
}

// C 函数回调 - 数据接收
static void DataReceivedCallbackWrapper(const char* data, uint32_t length) {
    // 1. 先调用全局日志回调（总是执行，用于调试）
    GlobalDataCallback(data, length);
    
    // 2. 如果有业务回调，再调用业务回调
    IMSDKManager *manager = [IMSDKManager sharedManager];
    if (manager.dataReceivedCallback) {
        NSString *dataStr = [[NSString alloc] initWithBytes:data 
                                                     length:length 
                                                   encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            manager.dataReceivedCallback(dataStr);
        });
    }
}

- (void)setNetworkEventCallback:(void (^)(uint8_t, NSString *))callback {
    NSLog(@"📝 设置网络事件回调: callback=%p, isNil=%@", callback, callback ? @"NO" : @"YES");
    self.networkEventCallback = callback;
    network_set_event_callback(NetworkEventCallbackWrapper);
    NSLog(@"✅ 网络事件回调已设置完成");
}

- (void)setDataReceivedCallback:(void (^)(NSString *))callback {
    NSLog(@"📝 设置数据接收回调: callback=%p, isNil=%@", callback, callback ? @"NO" : @"YES");
    self.dataReceivedCallback = callback;
    network_set_data_callback(DataReceivedCallbackWrapper);
    NSLog(@"✅ 数据接收回调已设置完成");
}

// ==================== 连接管理 ====================

/// 测试服务器连通性（TCP端口测试）
/// @param host 主机地址
/// @param port 端口号
/// @param timeout 超时时间（秒）
/// @return YES 可达，NO 不可达
- (BOOL)pingHost:(NSString *)host port:(int)port timeout:(NSTimeInterval)timeout {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        NSLog(@"❌ 创建 socket 失败: %s", strerror(errno));
        return NO;
    }
    
    // 设置非阻塞模式
    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    
    if (inet_pton(AF_INET, [host UTF8String], &server_addr.sin_addr) <= 0) {
        NSLog(@"❌ 无效的 IP 地址: %@", host);
        close(sockfd);
        return NO;
    }
    
    // 尝试连接
    int result = connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    
    if (result == 0) {
        // 立即连接成功
        close(sockfd);
        return YES;
    }
    
    if (errno != EINPROGRESS) {
        NSLog(@"❌ 连接失败: %s", strerror(errno));
        close(sockfd);
        return NO;
    }
    
    // 使用 select 等待连接完成
    fd_set writefds;
    FD_ZERO(&writefds);
    FD_SET(sockfd, &writefds);
    
    struct timeval tv;
    tv.tv_sec = (long)timeout;
    tv.tv_usec = (long)((timeout - tv.tv_sec) * 1000000);
    
    result = select(sockfd + 1, NULL, &writefds, NULL, &tv);
    
    if (result > 0) {
        // 检查连接是否成功
        int error = 0;
        socklen_t len = sizeof(error);
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len);
        
        close(sockfd);
        
        if (error == 0) {
            NSLog(@"✅ TCP 端口测试成功: %@:%d (延迟 < %.1f秒)", host, port, timeout);
            return YES;
        } else {
            NSLog(@"❌ TCP 端口测试失败: %@:%d - %s", host, port, strerror(error));
            return NO;
        }
    } else if (result == 0) {
        NSLog(@"⏱️ TCP 端口测试超时: %@:%d (%.1f秒)", host, port, timeout);
        close(sockfd);
        return NO;
    } else {
        NSLog(@"❌ select 错误: %s", strerror(errno));
        close(sockfd);
        return NO;
    }
}

- (void)addTargetToGroupWithIP:(NSString *)ip port:(int)port {
    NSLog(@"➕ 添加目标服务器: %@:%d", ip, port);
    const char *cIp = [ip UTF8String];
    network_add_target_to_group(cIp, port);
}

- (int)triggerImmediateReconnect:(BOOL)resetRetryCount {
    NSLog(@"🔄 触发立即重连 (重置计数: %@)", resetRetryCount ? @"是" : @"否");
    int result = network_trigger_immediate_reconnect(resetRetryCount);
    NSLog(@"📊 重连结果: %d", result);
    return result;
}

// ==================== 消息管理 ====================

- (int)sendMessageWithId:(NSString *)messageId
                 content:(NSData *)content
                 msgType:(int)msgType
                senderId:(NSString *)senderId
              receiverId:(NSString *)receiverId {
    
    NSLog(@"📤 发送消息: %@ -> %@", senderId, receiverId);
    // 这里需要根据实际 SDK 的消息发送接口来实现
    // 示例代码，实际需要查看 network_lib.h 中的消息发送函数
    NSLog(@"⚠️ 消息发送功能待实现");
    return 0;
}

// ==================== 事件循环 ====================

- (void)runEventLoop {
    network_event_loop();
}

@end

