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

// ==================== 私有方法前向声明 ====================

@interface IMSDKMessageManager ()
/// 处理收到的消息（内部方法）
- (void)handleReceivedMessageWithData:(const char *)data
                               length:(int)dataLen
                             convType:(IMMessageConvType)convType;

/// 处理系统消息
- (void)handleSystemMessageWithData:(const char *)data
                             length:(int)dataLen;

/// 处理命令消息
- (void)handleCommandMessageWithEventType:(int)eventType
                                     data:(const char *)data
                                   length:(int)dataLen;
@end

// ==================== 全局消息回调（被动接收） ====================

/// 单聊消息回调
static void SingleMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到单聊消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeSingle];
}

/// 群聊消息回调
static void GroupMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到群聊消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeGroup];
}

/// 社区消息回调
static void CommunityMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到社区消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeCommunity];
}

/// 系统消息回调
static void SystemMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到系统消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleSystemMessageWithData:data length:dataLen];
}

/// 命令消息回调
static void CommandMessageCallback(int eventType, const char* data, int dataLen) {
    NSLog(@"📨 收到命令消息: eventType=%d, dataLen=%d", eventType, dataLen);
    [[IMSDKMessageManager sharedManager] handleCommandMessageWithEventType:eventType data:data length:dataLen];
}

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

/// 拉取消息回调
static void PullMessagesCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📥 拉取消息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
        
        // 打印原始 HEX 调试
        NSMutableString *hexStr = [NSMutableString string];
        const unsigned char *bytes = (const unsigned char *)responseData.bytes;
        for (NSUInteger i = 0; i < MIN(responseData.length, 200); i++) {
            [hexStr appendFormat:@"%02x ", bytes[i]];
        }
        NSLog(@"📦 拉取消息原始数据 (HEX): %@", hexStr);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];
        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析为 PullList
                NSError *parseError = nil;
                PullList *pullList = [PullList parseFromData:responseData error:&parseError];
                
                if (pullList && !parseError) {
                    NSMutableDictionary *result = [NSMutableDictionary dictionary];
                    result[@"server_time"] = @(pullList.serverTime);
                    result[@"total_count"] = @(pullList.totalCount);
                    // hasMore 是一个字典类型，需要检查 count
                    result[@"has_more"] = @(pullList.hasMore_Count > 0);
                    
                    NSMutableArray *messagesArray = [NSMutableArray array];
                    for (ImMessage *msg in pullList.messagesArray) {
                        NSMutableDictionary *msgDict = [NSMutableDictionary dictionary];
                        
                        // 消息元数据
                        if (msg.hasMetadata) {
                            msgDict[@"msg_id"] = msg.metadata.msgId ?: @"";
                            msgDict[@"server_msg_id"] = msg.metadata.serverMsgId ?: @"";
                            msgDict[@"from"] = msg.metadata.from ?: @"";
                            msgDict[@"to"] = msg.metadata.to ?: @"";
                            msgDict[@"nick"] = msg.metadata.nick ?: @"";
                            msgDict[@"send_time"] = @(msg.metadata.sendTime);
                            msgDict[@"receive_time"] = @(msg.metadata.receiveTime);
                        }
                        
                        msgDict[@"conversation_id"] = msg.conversationId ?: @"";
                        msgDict[@"conversation_seq"] = @(msg.conversationSeq);
                        msgDict[@"server_seq"] = @(msg.serverSeq);
                        msgDict[@"m_type"] = @(msg.mType);
                        msgDict[@"conversation_type"] = @(msg.conversationType);
                        msgDict[@"store_time"] = @(msg.storeTime);
                        
                        // 根据消息类型解析内容
                        if (msg.mType == ImMessage_MessageType_Text && msg.textMessage) {
                            msgDict[@"content"] = msg.textMessage.content ?: @"";
                            msgDict[@"ext"] = msg.textMessage.ext ?: @"";
                        } else if (msg.mType == ImMessage_MessageType_Image && msg.imageMessage) {
                            msgDict[@"content"] = @"[图片]";
                            msgDict[@"image_url"] = msg.imageMessage.originalURL ?: @"";
                        } else {
                            msgDict[@"content"] = [NSString stringWithFormat:@"[消息类型:%d]", (int)msg.mType];
                        }
                        
                        [messagesArray addObject:msgDict];
                    }
                    result[@"messages"] = messagesArray;
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 拉取消息成功: %lu 条消息", (unsigned long)messagesArray.count);
                } else {
                    NSLog(@"⚠️ PullList 解析失败: %@", parseError);
                    // 尝试直接作为字符串
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    if (!dataStr) {
                        dataStr = @"{\"messages\":[]}";
                    }
                }
            } else if (errorCode == 0) {
                dataStr = @"{\"messages\":[],\"total_count\":0}";
                NSLog(@"✅ 拉取消息成功（无消息）");
            } else {
                // 错误情况
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"❌ 拉取消息失败: %@", dataStr);
            }
            
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}

// ==================== 实现类 ====================

@implementation IMSDKMessageManager {
    NSMutableDictionary<NSNumber *, IMSDKMessageCompletion> *_callbacks;
    BOOL _isCallbacksRegistered;
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
        _isCallbacksRegistered = NO;
    }
    return self;
}

// ==================== 消息监听注册 ====================

- (void)registerMessageCallbacks {
    if (_isCallbacksRegistered) {
        NSLog(@"⚠️ 消息回调已注册，跳过重复注册");
        return;
    }
    
    NSLog(@"📝 注册消息回调: 单聊、群聊、社区、系统、命令");
    
    // 注册单聊消息回调
    register_single_message_callback(SingleMessageCallback);
    
    // 注册群聊消息回调
    register_group_message_callback(GroupMessageCallback);
    
    // 注册社区消息回调
    register_community_message_callback(CommunityMessageCallback);
    
    // 注册系统消息回调
    registe_system_message_listener(SystemMessageCallback);
    
    // 注册命令消息回调
    registe_command_message_listener(CommandMessageCallback);
    
    _isCallbacksRegistered = YES;
    NSLog(@"✅ 消息回调注册完成");
}

- (void)unregisterMessageCallbacks {
    if (!_isCallbacksRegistered) {
        return;
    }
    
    NSLog(@"📝 取消注册消息回调");
    
    // 注销回调（传 NULL）
    register_single_message_callback(NULL);
    register_group_message_callback(NULL);
    register_community_message_callback(NULL);
    registe_system_message_listener(NULL);
    registe_command_message_listener(NULL);
    
    _isCallbacksRegistered = NO;
    NSLog(@"✅ 消息回调取消注册完成");
}

// ==================== 消息处理 ====================

- (void)handleReceivedMessageWithData:(const char *)data
                               length:(int)dataLen
                             convType:(IMMessageConvType)convType {
    // 在异步分发之前拷贝数据
    NSData *messageData = nil;
    if (data && dataLen > 0) {
        messageData = [NSData dataWithBytes:data length:dataLen];
    }
    
    if (!messageData || messageData.length == 0) {
        NSLog(@"⚠️ 收到空消息数据");
        return;
    }
    
    // 打印 HEX 调试
    NSMutableString *hexStr = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)messageData.bytes;
    for (NSUInteger i = 0; i < MIN(messageData.length, 100); i++) {
        [hexStr appendFormat:@"%02x ", bytes[i]];
    }
    NSLog(@"📦 消息数据 HEX (前100字节): %@", hexStr);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 解析消息
        NSError *parseError = nil;
        ImMessage *msg = [ImMessage parseFromData:messageData error:&parseError];
        
        if (!msg || parseError) {
            NSLog(@"❌ 消息解析失败: %@", parseError);
            return;
        }
        
        // 构建消息字典
        NSMutableDictionary *msgDict = [NSMutableDictionary dictionary];
        
        // 消息元数据
        if (msg.hasMetadata) {
            msgDict[@"msg_id"] = msg.metadata.msgId ?: @"";
            msgDict[@"server_msg_id"] = msg.metadata.serverMsgId ?: @"";
            msgDict[@"from"] = msg.metadata.from ?: @"";
            msgDict[@"to"] = msg.metadata.to ?: @"";
            msgDict[@"nick"] = msg.metadata.nick ?: @"";
            msgDict[@"send_time"] = @(msg.metadata.sendTime);
            msgDict[@"receive_time"] = @(msg.metadata.receiveTime);
        }
        
        msgDict[@"conversation_id"] = msg.conversationId ?: @"";
        msgDict[@"conversation_seq"] = @(msg.conversationSeq);
        msgDict[@"server_seq"] = @(msg.serverSeq);
        msgDict[@"m_type"] = @(msg.mType);
        msgDict[@"conversation_type"] = @(convType);
        msgDict[@"store_time"] = @(msg.storeTime);
        
        // 根据消息类型解析内容
        if (msg.mType == ImMessage_MessageType_Text && msg.textMessage) {
            msgDict[@"content"] = msg.textMessage.content ?: @"";
            msgDict[@"ext"] = msg.textMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Image && msg.imageMessage) {
            msgDict[@"content"] = @"[图片]";
            msgDict[@"image_url"] = msg.imageMessage.originalURL ?: @"";
            msgDict[@"thumbnail_url"] = msg.imageMessage.thumbnailURL ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Voice && msg.voiceMessage) {
            msgDict[@"content"] = @"[语音]";
            msgDict[@"voice_url"] = msg.voiceMessage.audioURL ?: @"";
            msgDict[@"duration"] = @(msg.voiceMessage.duration);
        } else if (msg.mType == ImMessage_MessageType_Video && msg.videoMessage) {
            msgDict[@"content"] = @"[视频]";
            msgDict[@"video_url"] = msg.videoMessage.videoURL ?: @"";
            msgDict[@"thumbnail_url"] = msg.videoMessage.coverURL ?: @"";
        } else if (msg.mType == ImMessage_MessageType_File && msg.fileMessage) {
            msgDict[@"content"] = @"[文件]";
            msgDict[@"file_url"] = msg.fileMessage.fileURL ?: @"";
            msgDict[@"file_name"] = msg.fileMessage.name ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Location && msg.locationMessage) {
            msgDict[@"content"] = @"[位置]";
            msgDict[@"latitude"] = @(msg.locationMessage.latitude);
            msgDict[@"longitude"] = @(msg.locationMessage.longitude);
            msgDict[@"address"] = msg.locationMessage.name ?: @"";
        } else {
            msgDict[@"content"] = [NSString stringWithFormat:@"[消息类型:%d]", (int)msg.mType];
        }
        
        NSString *convTypeStr = @"未知";
        switch (convType) {
            case IMMessageConvTypeSingle: convTypeStr = @"单聊"; break;
            case IMMessageConvTypeGroup: convTypeStr = @"群聊"; break;
            case IMMessageConvTypeCommunity: convTypeStr = @"社区"; break;
        }
        NSLog(@"✅ 收到%@消息: from=%@, content=%@", convTypeStr, msgDict[@"from"], msgDict[@"content"]);
        
        // 调用回调
        if (self.onMessageReceived) {
            self.onMessageReceived(convType, msgDict);
        }
    });
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
        (int)ImMessage_MessageType_Text,  // msgType = 0 (TEXT)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_single_message: result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

// ==================== 拉取历史消息 ====================

- (int)pullMessagesWithConversationId:(NSString *)conversationId
                             convType:(int)convType
                             targetId:(NSString *)targetId
                              lastSeq:(int64_t)lastSeq
                                limit:(int)limit
                           completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📥 拉取历史消息: conversationId=%@, convType=%d, targetId=%@, lastSeq=%lld, limit=%d",
          conversationId, convType, targetId, lastSeq, limit);
    
    // 构建 Pull 请求
    Pull *pullRequest = [[Pull alloc] init];
    pullRequest.limit = limit > 0 ? limit : 50;
    
    // 如果有会话ID，直接使用会话ID拉取
    if (conversationId && conversationId.length > 0) {
        pullRequest.conversationId = conversationId;
    }
    
    // 构建会话拉取条件
    ConvPull *convPull = [[ConvPull alloc] init];
    convPull.convType = (ConversationType)convType;
    convPull.targetId = targetId ?: @"";
    convPull.lastConvSeq = lastSeq;
    if (conversationId && conversationId.length > 0) {
        convPull.conversationId = conversationId;
    }
    
    [pullRequest.convPullsArray addObject:convPull];
    
    // 序列化
    NSData *protoData = [pullRequest data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ Pull 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 Pull 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 打印 HEX 调试
    NSMutableString *hexStr = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoData.bytes;
    for (NSUInteger i = 0; i < protoData.length; i++) {
        [hexStr appendFormat:@"%02x ", bytes[i]];
    }
    NSLog(@"📦 HEX: %@", hexStr);
    
    // 调用 SDK 拉取消息
    uint64_t reqId = 0;
    int result = pull_messages(
        PullMessagesCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        reqId
    );
    
    NSLog(@"📥 调用 pull_messages: result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

// ==================== 系统消息处理 ====================

- (void)handleSystemMessageWithData:(const char *)data length:(int)dataLen {
    // 拷贝数据
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
        
        if (responseData && responseData.length > 0) {
            // 尝试解析为 JSON 字符串
            NSString *dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (dataStr) {
                messageData[@"raw_data"] = dataStr;
            }
            
            // 尝试解析为 JSON 对象
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
            if (jsonObj && !jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
                [messageData addEntriesFromDictionary:(NSDictionary *)jsonObj];
            }
        }
        
        messageData[@"type"] = @"system";
        messageData[@"receive_time"] = @([[NSDate date] timeIntervalSince1970] * 1000);
        
        NSLog(@"📨 系统消息解析完成: %@", messageData);
        
        // 回调到 Flutter
        if (self.onSystemMessage) {
            self.onSystemMessage(messageData);
        }
    });
}

// ==================== 命令消息处理 ====================

- (void)handleCommandMessageWithEventType:(int)eventType data:(const char *)data length:(int)dataLen {
    // 拷贝数据
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
        
        if (responseData && responseData.length > 0) {
            // 尝试解析为 JSON 字符串
            NSString *dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (dataStr) {
                messageData[@"raw_data"] = dataStr;
            }
            
            // 尝试解析为 JSON 对象
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
            if (jsonObj && !jsonError && [jsonObj isKindOfClass:[NSDictionary class]]) {
                [messageData addEntriesFromDictionary:(NSDictionary *)jsonObj];
            }
        }
        
        messageData[@"type"] = @"command";
        messageData[@"event_type"] = @(eventType);
        messageData[@"receive_time"] = @([[NSDate date] timeIntervalSince1970] * 1000);
        
        NSLog(@"📨 命令消息解析完成: eventType=%d, data=%@", eventType, messageData);
        
        // 回调到 Flutter
        if (self.onCommandMessage) {
            self.onCommandMessage(eventType, messageData);
        }
    });
}

@end

