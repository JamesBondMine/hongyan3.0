//
//  IMSDKMessageManager.mm
//  Runner
//
//  IM SDK 消息管理类实现
//

#import "IMSDKMessageManager.h"
#import "network_lib.h"
#import "MessagePb.pbobjc.h"
#import "ConvPb.pbobjc.h"

// ==================== 回调函数 ====================

/// 发送消息回调
static void SendMessageCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📤 发送消息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];
        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析返回数据
                NSError *parseError = nil;
                ImMessage *result = [ImMessage parseFromData:responseData error:&parseError];
                
                if (result && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                    
                    // 消息元数据
                    if (result.hasMetadata) {
                        jsonDict[@"msg_id"] = result.metadata.msgId ?: @"";
                        jsonDict[@"server_msg_id"] = result.metadata.serverMsgId ?: @"";
                        jsonDict[@"send_time"] = @(result.metadata.sendTime);
                        jsonDict[@"receive_time"] = @(result.metadata.receiveTime);
                    }
                    
                    jsonDict[@"conversation_id"] = result.conversationId ?: @"";
                    jsonDict[@"conversation_seq"] = @(result.conversationSeq);
                    jsonDict[@"server_seq"] = @(result.serverSeq);
                    jsonDict[@"store_time"] = @(result.storeTime);
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 发送消息成功: %@", dataStr);
                } else {
                    // 尝试直接作为 JSON
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"⚠️ Protobuf 解析失败，尝试 JSON: %@", dataStr);
                }
            } else if (errorCode == 0) {
                // 成功但无数据
                dataStr = @"{\"success\":true}";
                NSLog(@"✅ 发送消息成功（无返回数据）");
            }
            
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}

// ==================== 实现类 ====================

@implementation IMSDKMessageManager {
    NSMutableDictionary<NSNumber *, IMSDKMessageCompletion> *_callbacks;
}

+ (instancetype)sharedManager {
    static IMSDKMessageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKMessageManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbacks = [NSMutableDictionary dictionary];
    }
    return self;
}

// ==================== 回调管理 ====================

- (void)setCallback:(IMSDKMessageCompletion)callback forReqId:(uint64_t)reqId {
    if (callback) {
        _callbacks[@(reqId)] = callback;
    }
}

- (IMSDKMessageCompletion)getCallbackForReqId:(uint64_t)reqId {
    return _callbacks[@(reqId)];
}

- (void)removeCallbackForReqId:(uint64_t)reqId {
    [_callbacks removeObjectForKey:@(reqId)];
}

// ==================== 发送消息 ====================

- (int)sendTextMessage:(NSString *)content
        conversationId:(NSString *)conversationId
            receiverId:(NSString *)receiverId
            completion:(IMSDKMessageCompletion)completion {
    return [self sendTextMessage:content ext:nil conversationId:conversationId receiverId:receiverId completion:completion];
}

- (int)sendTextMessage:(NSString *)content
                   ext:(NSString *)ext
        conversationId:(NSString *)conversationId
            receiverId:(NSString *)receiverId
            completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送文本消息: content=%@, conversationId=%@, receiverId=%@", content, conversationId, receiverId);
    
    // SDK 期望的是 TextMessage 的 Protobuf 数据，而不是整个 ImMessage
    TextMessage *textMsg = [[TextMessage alloc] init];
    textMsg.content = content;
    if (ext) {
        textMsg.ext = ext;
    }
    
    // 序列化 TextMessage
    NSData *protoData = [textMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ TextMessage 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 TextMessage 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 打印 HEX 调试
    NSMutableString *hexStr = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoData.bytes;
    for (NSUInteger i = 0; i < protoData.length; i++) {
        [hexStr appendFormat:@"%02x ", bytes[i]];
    }
    NSLog(@"📦 HEX: %@", hexStr);
    
    // 调用 SDK 发送
    // 参数说明：message 是 TextMessage 的 Protobuf 数据，msgType=0 表示文本消息
    uint64_t reqId = 0;
    int result = send_single_message(
        SendMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)IMMessageTypeText,  // msgType = 0 (TEXT)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_single_message: result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

@end

