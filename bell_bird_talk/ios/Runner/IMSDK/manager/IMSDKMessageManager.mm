
#import "IMSDKMessageManager.h"
#import "network_lib.h"
#import "MessagePb.pbobjc.h"
#import "ConvPb.pbobjc.h"
#import "ChatPb.pbobjc.h"
#import "SystemPb.pbobjc.h"


@interface IMSDKMessageManager ()
- (void)handleReceivedMessageWithData:(const char *)data
                               length:(int)dataLen
                             convType:(IMMessageConvType)convType;

- (void)handleSystemMessageWithData:(const char *)data
                             length:(int)dataLen;

- (void)handleCommandMessageWithEventType:(int)eventType
                                     data:(const char *)data
                                   length:(int)dataLen;
@end


static void SingleMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到单聊消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeSingle];
}

static void GroupMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到群聊消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeGroup];
}

static void CommunityMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到社区消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleReceivedMessageWithData:data
                                                                length:dataLen
                                                              convType:IMMessageConvTypeCommunity];
}

static void SystemMessageCallback(const char* data, int dataLen) {
    NSLog(@"📨 收到系统消息: dataLen=%d", dataLen);
    [[IMSDKMessageManager sharedManager] handleSystemMessageWithData:data length:dataLen];
}

static void CommandMessageCallback(int eventType, const char* data, int dataLen) {
    NSLog(@"📨 收到命令消息: eventType=%d, dataLen=%d", eventType, dataLen);
    [[IMSDKMessageManager sharedManager] handleCommandMessageWithEventType:eventType data:data length:dataLen];
}

static void NotificationUnreadCountCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 通知未读回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];
        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0 && responseData.length > 0) {
                NSError *parseError = nil;
                NotificationUnreadCountResult *result = [NotificationUnreadCountResult parseFromData:responseData error:&parseError];
                if (result && !parseError) {
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"total_unread"] = @(result.totalUnread);
                    if (result.typeUnread.count > 0) {
                        json[@"type_unread"] = result.typeUnread;
                    }
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                } else {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            } else if (errorCode == 0) {
                dataStr = @"{\"total_unread\":0}";
            }
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}

static void PullNotificationCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 拉取通知回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];
        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0 && responseData.length > 0) {
                NSError *parseError = nil;
                NotificationPullList *list = [NotificationPullList parseFromData:responseData error:&parseError];
                if (list && !parseError) {
                    NSMutableArray *arr = [NSMutableArray array];
                    for (Notification *n in list.notificationsArray) {
                        NSMutableDictionary *item = [NSMutableDictionary dictionary];
                        item[@"id"] = @(n.id_p);
                        item[@"notification_type"] = n.notificationType ?: @"";
                        item[@"title"] = n.title ?: @"";
                        item[@"content"] = n.content ?: @"";
                        item[@"business_type"] = n.businessType ?: @"";
                        item[@"server_msg_id"] = n.serverMsgId ?: @"";
                        item[@"related_user_id"] = n.relatedUserId ?: @"";
                        item[@"related_request_id"] = @(n.relatedRequestId);
                        item[@"status"] = @(n.status);
                        item[@"create_time"] = @(n.createTime);
                        item[@"read_time"] = @(n.readTime);
                        item[@"expire_time"] = @(n.expireTime);
                        [arr addObject:item];
                    }
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"notifications"] = arr;
                    if (list.hasPage) {
                        NSMutableDictionary *page = [NSMutableDictionary dictionary];
                        page[@"page"] = @(list.page.page);
                        page[@"size"] = @(list.page.size);
                        page[@"total_count"] = @(list.page.totalCount);
                        page[@"total_pages"] = @(list.page.totalPages);
                        page[@"has_previous"] = @(list.page.hasPrevious);
                        page[@"has_next"] = @(list.page.hasNext);
                        json[@"page"] = page;
                    }
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                } else {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            } else if (errorCode == 0) {
                dataStr = @"{\"notifications\":[]}";
            }
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}

static void MarkNotificationReadCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 标记通知已读回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];
        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0 && responseData.length > 0) {
                NSError *parseError = nil;
                NotificationMarkReadResult *result = [NotificationMarkReadResult parseFromData:responseData error:&parseError];
                if (result && !parseError) {
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"success_count"] = @(result.successCount);
                    if (result.failedIdsArray_Count > 0) {
                        NSMutableArray *failed = [NSMutableArray array];
                        for (NSUInteger i = 0; i < result.failedIdsArray_Count; i++) {
                            [failed addObject:@([result.failedIdsArray valueAtIndex:i])];
                        }
                        json[@"failed_ids"] = failed;
                    }
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                } else {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            } else if (errorCode == 0) {
                dataStr = @"{\"success_count\":0}";
            }
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}


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
                SendAck *result = [SendAck parseFromData:responseData error:&parseError];
                
                if (result && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
             
                    // SendAck 字段
                    jsonDict[@"server_msg_id"] = result.serverMsgId ?: @"";
                    jsonDict[@"client_msg_id"] = result.clientMsgId ?: @"";
                    jsonDict[@"conversation_seq"] = @(result.conversationSeq);
                    jsonDict[@"server_seq"] = @(result.serverSeq);
                    jsonDict[@"ingress_time"] = @(result.ingressTime);
                    jsonDict[@"trace_id"] = result.traceId ?: @"";
                    jsonDict[@"persist_time"] = @(result.persistTime);
                    jsonDict[@"conv_id"] = result.convId ?: @"";
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 发送消息成功: serverMsgId=%@, clientMsgId=%@, convId=%@", 
                          result.serverMsgId, result.clientMsgId, result.convId);
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

static void DeleteMessageCallback(const char* operationID, int errorCode, const char* data, const char* extra) {
    NSLog(@"🗑️ 删除消息回调: operationID=%s, errorCode=%d, data=%s, extra=%s",
          operationID ? operationID : "nil", errorCode, data ? data : "nil", extra ? extra : "nil");

    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKMessageManager *manager = [IMSDKMessageManager sharedManager];

        // 注意：这里我们需要通过operationID来找到对应的completion回调
        // 但是我们的回调系统是基于reqId的，所以这里可能需要调整
        // 暂时使用一个固定的reqId
        uint64_t reqId = 0; // 或者从某个映射中获取

        IMSDKMessageCompletion completion = [manager getCallbackForReqId:reqId];
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0) {
                dataStr = @"{\"success\":true}";
                NSLog(@"✅ 删除消息成功");
            } else {
                dataStr = [NSString stringWithFormat:@"{\"error\":\"%@\"}", data ? [NSString stringWithUTF8String:data] : @"unknown"];
                NSLog(@"❌ 删除消息失败: %@", dataStr);
            }

            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}
static void PullMessagesCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🍎 拉取消息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                        } else if (msg.mType == ImMessage_MessageType_Voice && msg.voiceMessage) {
                            msgDict[@"content"] = @"[语音]";
                            msgDict[@"audio_url"] = msg.voiceMessage.audioURL ?: @"";
                            msgDict[@"duration"] = @(msg.voiceMessage.duration);
                        } else if (msg.mType == ImMessage_MessageType_Video && msg.videoMessage) {
                            msgDict[@"content"] = @"[视频]";
                            msgDict[@"duration"] = @(msg.videoMessage.duration);
                            msgDict[@"image_url"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"cover_url"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"video_url"] = msg.videoMessage.videoURL ?: @"";
                            msgDict[@"imageUrl"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"coverUrl"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"videoUrl"] = msg.videoMessage.videoURL ?: @"";
                        } else if (msg.mType == ImMessage_MessageType_AtMessage && msg.atMessage) {
                            msgDict[@"content"] = msg.atMessage.content;
                        } else if (msg.mType == ImMessage_MessageType_Notification && msg.tipMessage) {
                            msgDict[@"content"] = msg.tipMessage.content;
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
        } else if (msg.mType == ImMessage_MessageType_AtMessage && msg.atMessage) {
            msgDict[@"content"] = msg.atMessage.content ?: @"";
            NSMutableArray<AtInfo*> *infoList = msg.atMessage.atInfoArray;
            
            // 组装 @ 用户信息列表
            NSMutableArray<NSDictionary *> *atInfoList = [[NSMutableArray alloc] init];
            if (infoList && infoList.count > 0) {
                for (AtInfo *atInfo in infoList) {
                    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
                    info[@"user_id"] = atInfo.userId ?: @"";
                    info[@"nickname"] = atInfo.nickName ?: @"";
                    [atInfoList addObject:info];
                }
            }
            msgDict[@"atInfoList"] = atInfoList;
            
            msgDict[@"ext"] = msg.atMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Image && msg.imageMessage) {
            msgDict[@"content"] = @"[图片]";
            msgDict[@"image_url"] = msg.imageMessage.originalURL ?: @"";
            msgDict[@"thumbnail_url"] = msg.imageMessage.thumbnailURL ?: @"";
            msgDict[@"ext"] = msg.imageMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Voice && msg.voiceMessage) {
            msgDict[@"content"] = @"[语音]";
            msgDict[@"voice_url"] = msg.voiceMessage.audioURL ?: @"";
            msgDict[@"duration"] = @(msg.voiceMessage.duration);
            msgDict[@"ext"] = msg.voiceMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Video && msg.videoMessage) {
            msgDict[@"content"] = @"[视频]";
            msgDict[@"video_url"] = msg.videoMessage.videoURL ?: @"";
            msgDict[@"thumbnail_url"] = msg.videoMessage.coverURL ?: @"";
            msgDict[@"ext"] = msg.videoMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_File && msg.fileMessage) {
            msgDict[@"content"] = @"[文件]";
            msgDict[@"file_url"] = msg.fileMessage.fileURL ?: @"";
            msgDict[@"file_name"] = msg.fileMessage.name ?: @"";
            msgDict[@"ext"] = msg.fileMessage.ext ?: @"";
        } else if (msg.mType == ImMessage_MessageType_Location && msg.locationMessage) {
            msgDict[@"content"] = @"[位置]";
            msgDict[@"latitude"] = @(msg.locationMessage.latitude);
            msgDict[@"longitude"] = @(msg.locationMessage.longitude);
            msgDict[@"address"] = msg.locationMessage.name ?: @"";
            msgDict[@"ext"] = msg.locationMessage.ext ?: @"";
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
    int result = send_contact_message(
        SendMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Text,  // msgType = 0 (TEXT)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_contact_message: result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendImageMessage:(NSString *)imageUrl
            thumbnailUrl:(NSString * _Nullable)thumbnailUrl
                  width:(int32_t)width
                 height:(int32_t)height
         conversationId:(NSString *)conversationId
             receiverId:(NSString *)receiverId
             completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送图片消息: imageUrl=%@, thumbnailUrl=%@, width=%d, height=%d, conversationId=%@, receiverId=%@",
          imageUrl, thumbnailUrl, width, height, conversationId, receiverId);
    
    // 创建 ImageMessage
    ImageMessage *imageMsg = [[ImageMessage alloc] init];
    imageMsg.originalURL = imageUrl;
    if (thumbnailUrl && thumbnailUrl.length > 0) {
        imageMsg.thumbnailURL = thumbnailUrl;
    }
    if (width > 0) {
        imageMsg.width = width;
    }
    if (height > 0) {
        imageMsg.height = height;
    }
    
    // 序列化 ImageMessage
    NSData *protoData = [imageMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ ImageMessage 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 ImageMessage 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 调用 SDK 发送
    uint64_t reqId = 0;
    int result = send_contact_message(
        SendMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Image,  // msgType = 1 (IMAGE)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_contact_message (图片): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendVideoMessage:(NSString *)videoUrl
               coverURL:(NSString * _Nullable)coverURL
               duration:(int32_t)duration
                  width:(int32_t)width
                 height:(int32_t)height
                   size:(int64_t)size
         conversationId:(NSString *)conversationId
             receiverId:(NSString *)receiverId
             completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送视频消息: videoUrl=%@, coverURL=%@, duration=%d, width=%d, height=%d, size=%lld, conversationId=%@, receiverId=%@",
          videoUrl, coverURL, duration, width, height, size, conversationId, receiverId);
    
    // 创建 VideoMessage
    VideoMessage *videoMsg = [[VideoMessage alloc] init];
    videoMsg.videoURL = videoUrl;
    if (coverURL && coverURL.length > 0) {
        videoMsg.coverURL = coverURL;
    }
    if (duration > 0) {
        videoMsg.duration = duration;
    }
    if (width > 0) {
        videoMsg.coverWidth = width;
    }
    if (height > 0) {
        videoMsg.coverHeight = height;
    }
    if (size > 0) {
        videoMsg.size = size;
    }
    
    // 序列化 VideoMessage
    NSData *protoData = [videoMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ VideoMessage 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 VideoMessage 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 调用 SDK 发送
    uint64_t reqId = 0;
    int result = send_contact_message(
        SendMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Video,  // msgType = 2 (VIDEO)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_contact_message (视频): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendVoiceMessage:(NSString *)audioUrl
                duration:(int32_t)duration
          conversationId:(NSString *)conversationId
              receiverId:(NSString *)receiverId
              completion:(IMSDKMessageCompletion)completion {
    
    
    
    // 创建 VoiceMessage
    VoiceMessage *voiceMsg = [[VoiceMessage alloc] init];
    voiceMsg.audioURL = audioUrl;
    voiceMsg.name = @"voice";
    voiceMsg.size = 300;
    voiceMsg.ext =audioUrl;
    if (duration > 0) {
        voiceMsg.duration = duration;
    }
    NSLog(@"🍎 发送语音消息: audioUrl=%@, name=%@, ext=%@,  size=%d, duration=%d, conversationId=%@, receiverId=%@",
          voiceMsg.audioURL,voiceMsg.name, voiceMsg.ext, voiceMsg.size, voiceMsg.duration, conversationId, receiverId);
    // 序列化 VoiceMessage
    NSData *protoData = [voiceMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ VoiceMessage 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 VoiceMessage 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 调用 SDK 发送
    uint64_t reqId = 0;
    int result = send_contact_message(
        SendMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Voice,  // msgType = 3 (VOICE)
        receiverId.UTF8String,
        reqId
    );
    
    NSLog(@"📤 调用 send_contact_message (语音): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}


static void SendGroupMessageCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 发送群聊消息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                SendAck *result = [SendAck parseFromData:responseData error:&parseError];
                
                if (result && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
             
                    // SendAck 字段
                    jsonDict[@"server_msg_id"] = result.serverMsgId ?: @"";
                    jsonDict[@"client_msg_id"] = result.clientMsgId ?: @"";
                    jsonDict[@"conversation_seq"] = @(result.conversationSeq);
                    jsonDict[@"server_seq"] = @(result.serverSeq);
                    jsonDict[@"ingress_time"] = @(result.ingressTime);
                    jsonDict[@"trace_id"] = result.traceId ?: @"";
                    jsonDict[@"persist_time"] = @(result.persistTime);
                    jsonDict[@"conv_id"] = result.convId ?: @"";
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 发送消息成功: serverMsgId=%@, clientMsgId=%@, convId=%@",
                          result.serverMsgId, result.clientMsgId, result.convId);
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

- (int)sendGroupTextMessage:(NSString *)content
            conversationId:(NSString *)conversationId
                   groupId:(NSString *)groupId
                completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送群聊文本消息: content=%@, conversationId=%@, groupId=%@", content, conversationId, groupId);
    
    // 创建 TextMessage
    TextMessage *textMsg = [[TextMessage alloc] init];
    textMsg.content = content;
    
    
    // 序列化 TextMessage
    NSData *protoData = [textMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ TextMessage 序列化失败");
        return -1;
    }
    
    
    
    // 调用 SDK 发送群聊消息
    uint64_t reqId = 0;
    int result = send_group_message(
        SendGroupMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Text,  // msgType = 0 (TEXT)
        groupId.UTF8String,
        &reqId  // 输出参数，需要传指针
    );
    
    NSLog(@"📤 调用 send_group_message (群聊文本): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendGroupImageMessage:(NSString *)imageUrl
                thumbnailUrl:(NSString *)thumbnailUrl
                      width:(int32_t)width
                     height:(int32_t)height
             conversationId:(NSString *)conversationId
                    groupId:(NSString *)groupId
                 completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送群聊图片消息: imageUrl=%@, thumbnailUrl=%@, width=%d, height=%d, conversationId=%@, groupId=%@",
          imageUrl, thumbnailUrl, width, height, conversationId, groupId);
    
    // 创建 ImageMessage
    ImageMessage *imageMsg = [[ImageMessage alloc] init];
    imageMsg.originalURL = imageUrl;
    if (thumbnailUrl && thumbnailUrl.length > 0) {
        imageMsg.thumbnailURL = thumbnailUrl;
    }
    if (width > 0) {
        imageMsg.width = width;
    }
    if (height > 0) {
        imageMsg.height = height;
    }
    
    // 序列化 ImageMessage
    NSData *protoData = [imageMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ ImageMessage 序列化失败");
        return -1;
    }
    
    // 调用 SDK 发送群聊消息
    uint64_t reqId = 0;
    int result = send_group_message(
        SendGroupMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Image,  // msgType = 1 (IMAGE)
        groupId.UTF8String,
        &reqId  // 输出参数，需要传指针
    );
    
    NSLog(@"📤 调用 send_group_message (群聊图片): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendGroupVoiceMessage:(NSString *)audioUrl
                    duration:(int32_t)duration
              conversationId:(NSString *)conversationId
                     groupId:(NSString *)groupId
                  completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送群聊语音消息: audioUrl=%@, duration=%d, conversationId=%@, groupId=%@",
          audioUrl, duration, conversationId, groupId);
    
    // 创建 VoiceMessage
    VoiceMessage *voiceMsg = [[VoiceMessage alloc] init];
    voiceMsg.audioURL = audioUrl;
    voiceMsg.name = @"voice";
    voiceMsg.size = 300;
    voiceMsg.ext = audioUrl;
    if (duration > 0) {
        voiceMsg.duration = duration;
    }
    
    // 序列化 VoiceMessage
    NSData *protoData = [voiceMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ VoiceMessage 序列化失败");
        return -1;
    }
    
    // 调用 SDK 发送群聊消息
    uint64_t reqId = 0;
    int result = send_group_message(
        SendGroupMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Voice,  // msgType = 3 (VOICE)
        groupId.UTF8String,
        &reqId  // 输出参数，需要传指针
    );
    
    NSLog(@"📤 调用 send_group_message (群聊语音): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendGroupVideoMessage:(NSString *)videoUrl
                     coverURL:(NSString * _Nullable)coverURL
                     duration:(int32_t)duration
                        width:(int32_t)width
                       height:(int32_t)height
                         size:(int64_t)size
               conversationId:(NSString *)conversationId
                      groupId:(NSString *)groupId
                   completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送群聊视频消息: videoUrl=%@, coverURL=%@, duration=%d, width=%d, height=%d, size=%lld, conversationId=%@, groupId=%@",
          videoUrl, coverURL, duration, width, height, size, conversationId, groupId);
    
    // 创建 VideoMessage
    VideoMessage *videoMsg = [[VideoMessage alloc] init];
    videoMsg.videoURL = videoUrl;
    if (coverURL && coverURL.length > 0) {
        videoMsg.coverURL = coverURL;
    }
    if (duration > 0) {
        videoMsg.duration = duration;
    }
    if (width > 0) {
        videoMsg.coverWidth = width;
    }
    if (height > 0) {
        videoMsg.coverHeight = height;
    }
    if (size > 0) {
        videoMsg.size = size;
    }
    
    // 序列化 VideoMessage
    NSData *protoData = [videoMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ VideoMessage 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 VideoMessage 序列化成功: %lu 字节", (unsigned long)protoData.length);
    
    // 调用 SDK 发送群聊消息
    uint64_t reqId = 0;
    int result = send_group_message(
        SendGroupMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_Video,  // msgType = 2 (VIDEO)
        groupId.UTF8String,
        &reqId  // 输出参数，需要传指针
    );
    
    NSLog(@"📤 调用 send_group_message (群聊视频): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}

- (int)sendGroupAtMessage:(NSString *)content
          conversationId:(NSString *)conversationId
                 groupId:(NSString *)groupId
              atInfoList:(NSArray<NSDictionary *> *)atInfoList
                   isAll:(BOOL)isAll
              completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📤 发送群聊@消息: content=%@, conversationId=%@, groupId=%@, isAll=%@", 
          content, conversationId, groupId, isAll ? @"YES" : @"NO");
    
    // 创建 AtMessage
    AtMessage *atMsg = [[AtMessage alloc] init];
    atMsg.content = content;
    atMsg.isAll = isAll;
    
    // 添加@成员信息
    if (!isAll && atInfoList && atInfoList.count > 0) {
        for (NSDictionary *atInfo in atInfoList) {
            AtInfo *info = [[AtInfo alloc] init];
            info.userId = atInfo[@"user_id"] ?: @"";
            info.nickName = atInfo[@"nickname"] ?: @"";
            [atMsg.atInfoArray addObject:info];
        }
    }
    
    // 序列化 AtMessage
    NSData *protoData = [atMsg data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ AtMessage 序列化失败");
        return -1;
    }
    
    // 调用 SDK 发送群聊@消息
    uint64_t reqId = 0;
    int result = send_group_message(
        SendGroupMessageCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        conversationId.UTF8String,
        (int)ImMessage_MessageType_AtMessage,  // msgType = 10 (AT_MESSAGE)
        groupId.UTF8String,
        &reqId  // 输出参数，需要传指针
    );
    
    NSLog(@"📤 调用 send_group_message (群聊@消息): result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}


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

static void PullGroupMessagesCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📥 拉取群聊消息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                            if (msg.imageMessage.thumbnailURL.length > 0) {
                                msgDict[@"thumbnail_url"] = msg.imageMessage.thumbnailURL;
                            }
                            msgDict[@"width"] = @(msg.imageMessage.width);
                            msgDict[@"height"] = @(msg.imageMessage.height);
                            msgDict[@"ext"] = msg.imageMessage.ext ?: @"";
                        } else if (msg.mType == ImMessage_MessageType_Voice && msg.voiceMessage) {
                            msgDict[@"content"] = @"[语音]";
                            msgDict[@"audio_url"] = msg.voiceMessage.audioURL ?: @"";
                            msgDict[@"duration"] = @(msg.voiceMessage.duration);
                            msgDict[@"voice_duration"] = @(msg.voiceMessage.duration);
                            msgDict[@"ext"] = msg.voiceMessage.ext ?: @"";
                        } else if (msg.mType == ImMessage_MessageType_Video && msg.videoMessage) {
                            msgDict[@"content"] = @"[视频]";
                            msgDict[@"duration"] = @(msg.videoMessage.duration);
                            msgDict[@"video_duration"] = @(msg.videoMessage.duration);
                            msgDict[@"image_url"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"cover_url"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"video_url"] = msg.videoMessage.videoURL ?: @"";
                            msgDict[@"imageUrl"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"coverUrl"] = msg.videoMessage.coverURL ?: @"";
                            msgDict[@"videoUrl"] = msg.videoMessage.videoURL ?: @"";
                            msgDict[@"ext"] = msg.videoMessage.ext ?: @"";
                        } else if (msg.mType == ImMessage_MessageType_AtMessage && msg.atMessage) {
                            msgDict[@"content"] = msg.atMessage.content;
                            msgDict[@"type"] = @"at";
                            msgDict[@"ext"] = msg.atMessage.ext ?: @"";
                            msgDict[@"isAll"] = msg.atMessage.isAll ? @"1" :@"0";
                            
                            NSMutableArray<AtInfo*> * infos = msg.atMessage.atInfoArray;
                            
                            NSMutableArray<NSDictionary *> * atInfoList = [[NSMutableArray alloc] init];
                            if (!msg.atMessage.isAll && infos && infos.count > 0) {
                                for (AtInfo *atInfo in infos) {
                                    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
                                    [info setValue:atInfo.userId ?: @"" forKey:@"user_id"];
                                    [info setValue:atInfo.nickName ?: @"" forKey:@"nickname"];
                                    [atInfoList addObject:info];
                                }
                                msgDict[@"atInfoList"] = atInfoList;
                            }                        } else if (msg.mType == ImMessage_MessageType_Notification && msg.tipMessage) {
                            msgDict[@"content"] = msg.tipMessage.content;
//                            msgDict[@"ext"] = msg.tipMessage.ext ?: @"";
                        } else {
                            msgDict[@"content"] = [NSString stringWithFormat:@"[消息类型:%d]", (int)msg.mType];
                            msgDict[@"ext"] = msg.textMessage.ext ?: @"";
                        }
                        
                        [messagesArray addObject:msgDict];
                    }
                    result[@"messages"] = messagesArray;
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 拉取群聊消息成功: %lu 条消息", (unsigned long)messagesArray.count);
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
                NSLog(@"✅ 拉取群聊消息成功（无消息）");
            } else {
                // 错误情况
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"❌ 拉取群聊消息失败: %@", dataStr);
            }
            completion(errorCode, reqId, dataStr);
            [manager removeCallbackForReqId:reqId];
        }
    });
}

- (int)pullGroupMessagesWithConversationId:(NSString *)conversationId
                                   groupId:(NSString *)groupId
                                  lastSeq:(int64_t)lastSeq
                                    limit:(int)limit
                               completion:(IMSDKMessageCompletion)completion {
    
    NSLog(@"📥 拉取群聊历史消息: conversationId=%@, groupId=%@, lastSeq=%lld, limit=%d",
          conversationId, groupId, lastSeq, limit);
    
    // 构建 Pull 请求
    Pull *pullRequest = [[Pull alloc] init];
    pullRequest.limit = limit > 0 ? limit : 50;
    
    if (conversationId && conversationId.length > 0) {
        pullRequest.conversationId = conversationId;
    }
    
    // 构建群聊拉取条件
    ConvPull *convPull = [[ConvPull alloc] init];
//    convPull.convType = Conversation;  // 群聊类型
    convPull.targetId = groupId ?: @"";
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
    
    // 调用 SDK 拉取群聊消息
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    int result = pull_group_messages(
        PullGroupMessagesCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        targetId,
        reqId
    );
    
    NSLog(@"📥 调用 pull_group_messages: result=%d, reqId=%llu", result, reqId);
    
    if (result == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    
    return result;
}


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


- (int)getNotificationUnreadCountWithTypes:(NSArray<NSString *> * _Nullable)notificationTypes
                                completion:(IMSDKMessageCompletion)completion {
    NotificationUnreadCount *req = [NotificationUnreadCount message];
    
    if (notificationTypes.count > 0) {
        [req.notificationTypesArray addObjectsFromArray:notificationTypes];
    }
    
    NSData *protoData = [req data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        if (completion) {
            completion(-1, 0, @"{\"message\":\"Protobuf 序列化失败\"}");
        }
        return -1;
    }
    
    uint64_t reqId = 0;
    int code = get_notification_unread_count(
        NotificationUnreadCountCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        reqId
    );
    
    NSLog(@"🔔 调用 get_notification_unread_count: result=%d, reqId=%llu", code, reqId);
    
    if (code == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    return code;
}

- (int)pullNotificationsWithTypes:(NSArray<NSString *> * _Nullable)notificationTypes
                             page:(int32_t)page
                         pageSize:(int32_t)pageSize
                        completion:(IMSDKMessageCompletion)completion {
    NotificationPull *req = [NotificationPull message];
    if (notificationTypes.count > 0) {
        [req.notificationTypesArray addObjectsFromArray:notificationTypes];
    }
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    req.page = pg;
    
    NSData *protoData = [req data];
    uint64_t reqId = 0;
    int code = pull_notification(
        PullNotificationCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        reqId
    );
    
    if (code == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    return code;
}

- (int)markNotificationsRead:(NSArray<NSNumber *> *)notificationIds
                    readTime:(int64_t)readTime
                  completion:(IMSDKMessageCompletion)completion {
    if (notificationIds.count == 0) {
        if (completion) {
            completion(-1, 0, @"{\"message\":\"notificationIds 不能为空\"}");
        }
        return -1;
    }
    
    NotificationMarkRead *req = [NotificationMarkRead message];
    for (NSNumber *num in notificationIds) {
        [req.notificationIdsArray addValue:num.longLongValue];
    }
    int64_t ts = readTime > 0 ? readTime : (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    req.readTime = ts;
    
    NSData *protoData = [req data];
    uint64_t reqId = 0;
    int code = mark_notification_read(
        MarkNotificationReadCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        reqId
    );
    
    if (code == 0 && completion) {
        [self setCallback:completion forReqId:reqId];
    }
    return code;
}

- (int)deleteMessage:(NSString *)conversationId
          clientMsgId:(NSString *)clientMsgId
           completion:(IMSDKMessageCompletion)completion {

    NSLog(@"🗑️ 删除消息: conversationId=%@, clientMsgId=%@", conversationId, clientMsgId);

    if (!conversationId || conversationId.length == 0) {
        NSLog(@"❌ 会话ID不能为空");
        return -1;
    }

    if (!clientMsgId || clientMsgId.length == 0) {
        NSLog(@"❌ 客户端消息ID不能为空");
        return -1;
    }

    // 生成唯一的操作ID
    NSString *operationID = [[NSUUID UUID] UUIDString];
    uint64_t reqId = 0;

    // 调用 SDK 删除消息
    delete_message(
        DeleteMessageCallback,
        (char *)operationID.UTF8String,
        (char *)conversationId.UTF8String,
        (char *)clientMsgId.UTF8String
    );

    NSLog(@"🗑️ 调用 delete_message: operationID=%@, conversationId=%@, clientMsgId=%@",
          operationID, conversationId, clientMsgId);

    if (completion) {
        // 注意：这里我们使用 operationID 作为 key，因为回调函数是通过 operationID 标识的
        // 但是我们的 completion 回调系统是基于 reqId 的，所以这里可能需要调整
        // 暂时先设置一个虚拟的 reqId
        reqId = (uint64_t)[[NSDate date] timeIntervalSince1970] * 1000; // 使用时间戳作为 reqId
        [self setCallback:completion forReqId:reqId];
    }

    return 0; // delete_message 返回 void，所以我们返回 0 表示调用成功
}


@end
