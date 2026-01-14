//
//  IMSDKConversationManager.mm
//  Runner
//
//  IM SDK 会话管理类实现
//

#import "IMSDKConversationManager.h"
#import "network_lib.h"
#import "ConvPb.pbobjc.h"
#import "SystemPb.pbobjc.h"
#import "MessagePb.pbobjc.h"

// ==================== 类扩展（前置声明） ====================

@interface IMSDKConversationManager ()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, IMSDKConversationCompletion> *callbacks;

// 回调管理方法
- (void)setCallback:(IMSDKConversationCompletion)completion forReqId:(uint64_t)reqId;
- (IMSDKConversationCompletion)getCallbackForReqId:(uint64_t)reqId;
- (void)removeCallbackForReqId:(uint64_t)reqId;

@end

// ==================== 回调函数 ====================


// 会话已读回调
static void MarkReadCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🍎会话已读回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 立即打印原始数据 HEX（在任何异步操作之前）
    if (data && dataLen > 0) {
        NSMutableString *hexStr = [NSMutableString string];
        for (int i = 0; i < MIN(dataLen, 100); i++) {
            [hexStr appendFormat:@"%02x ", (unsigned char)data[i]];
        }
//        NSLog(@"📦 原始数据 (HEX, 立即打印): %@", hexStr);
    }
    
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        // 尝试解析为 Protobuf 数据
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
//        NSLog(@"📦 数据拷贝后长度: %lu", (unsigned long)responseData.length);
        
        // 尝试解析为 ConvList（会话列表响应）
        NSError *error = nil;
        MarkReadResult * read = [MarkReadResult parseFromData:responseData error:&error];
        if (!error && read) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
           
            
            NSMutableArray *convArray = [NSMutableArray array];
            
            result[@"conversations"] = convArray;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"📋 解析会话已读成功: %lu 条记录", (unsigned long)convArray.count);
        }
    }
    
    // 获取回调并执行
    IMSDKConversationManager *manager = [IMSDKConversationManager sharedManager];
    IMSDKConversationCompletion completion = [manager getCallbackForReqId:reqId];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager removeCallbackForReqId:reqId];
    }
}


// 会话操作回调
static void ConversationCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🍎会话回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 立即打印原始数据 HEX（在任何异步操作之前）
    if (data && dataLen > 0) {
        NSMutableString *hexStr = [NSMutableString string];
        for (int i = 0; i < MIN(dataLen, 100); i++) {
            [hexStr appendFormat:@"%02x ", (unsigned char)data[i]];
        }
    }
    
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        // 尝试解析为 Protobuf 数据
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
        // 尝试解析为 ConvList（会话列表响应）
        NSError *error = nil;
        ListWithUnread *convList = [ListWithUnread parseFromData:responseData error:&error];
        if (!error && convList) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[@"total_count"] = @(convList.totalUnread);
            result[@"page"] = @(convList.page);
            result[@"size"] = @(convList.size);
            
            NSMutableArray *convArray = [NSMutableArray array];
            for (ConvWithUnread *convWithUnread in convList.convsArray) {
                // ConvWithUnread 包含嵌套的 conv 对象
                Conv *conv = convWithUnread.conv;
                if (!conv) {
                    NSLog(@"⚠️ ConvWithUnread 中的 conv 为空，跳过");
                    continue;
                }
                
                NSLog(@"conv.convId: %@", conv.convId);
                NSMutableDictionary *convDict = [NSMutableDictionary dictionary];
                convDict[@"conv_id"] = conv.convId ?: @"";
                convDict[@"parent_id"] = conv.parentId ?: @"";
                convDict[@"conv_type"] = @(conv.convType);
                
                convDict[@"level"] = @(conv.level);
                convDict[@"display_name"] = conv.displayName ?: @"";
                convDict[@"description"] = conv.description_p ?: @"";
                convDict[@"avatar_url"] = conv.avatarURL ?: @"";
                convDict[@"avatar_bg"] = conv.avatarBg ?: @"";
                convDict[@"avatar_info"] = conv.avatarInfo ?: @"";
                convDict[@"target_id"] = conv.targetId ?: @"";
                convDict[@"status"] = @(conv.status);
                convDict[@"is_private"] = @(conv.isPrivate);
                convDict[@"disturb"] = @(conv.disturb);
                convDict[@"created_at"] = @(conv.createdAt);
                convDict[@"updated_at"] = @(conv.updatedAt);
                convDict[@"extra_info"] = conv.extraInfo ?: @"";
            
                
                // 添加标签信息
                if (conv.sysTagsArray_Count > 0) {
                    NSMutableArray *sysTags = [NSMutableArray arrayWithCapacity:conv.sysTagsArray_Count];
                    for (NSUInteger i = 0; i < conv.sysTagsArray_Count; i++) {
                        [sysTags addObject:conv.sysTagsArray[i]];
                    }
                    convDict[@"sys_tags"] = sysTags;
                }
                if (conv.userTagsArray_Count > 0) {
                    NSMutableArray *userTags = [NSMutableArray arrayWithCapacity:conv.userTagsArray_Count];
                    for (NSUInteger i = 0; i < conv.userTagsArray_Count; i++) {
                        [userTags addObject:conv.userTagsArray[i]];
                    }
                    convDict[@"user_tags"] = userTags;
                }
                
                // 添加免打扰状态
                convDict[@"disturb"] = @(conv.disturb);
                
                // 添加未读数信息（来自 ConvWithUnread）
                convDict[@"unread_count"] = @(convWithUnread.unreadCount);
                convDict[@"last_read_seq"] = @(convWithUnread.lastReadSeq);
                convDict[@"conv_max_seq"] = @(convWithUnread.convMaxSeq);
                
                [convArray addObject:convDict];
            }
            result[@"conversations"] = convArray;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"📋 解析会话列表成功: %lu 条记录", (unsigned long)convArray.count);
        } else {
            // 尝试解析为单个 Conv（单个会话响应）
            Conv *conv = [Conv parseFromData:responseData error:&error];
            if (!error && conv && conv.convId.length > 0) {
                NSMutableDictionary *convDict = [NSMutableDictionary dictionary];
                convDict[@"conv_id"] = conv.convId ?: @"";
                convDict[@"parent_id"] = conv.parentId ?: @"";
                convDict[@"conv_type"] = @(conv.convType);
                convDict[@"level"] = @(conv.level);
                convDict[@"display_name"] = conv.displayName ?: @"";
                convDict[@"description"] = conv.description_p ?: @"";
                convDict[@"avatar_url"] = conv.avatarURL ?: @"";
                convDict[@"avatar_info"] = conv.avatarInfo ?: @"";
                convDict[@"target_id"] = conv.targetId ?: @"";
                convDict[@"status"] = @(conv.status);
                convDict[@"is_private"] = @(conv.isPrivate);
                convDict[@"disturb"] = @(conv.disturb);
                convDict[@"created_at"] = @(conv.createdAt);
                convDict[@"updated_at"] = @(conv.updatedAt);
                convDict[@"extra_info"] = conv.extraInfo ?: @"";
                
                // 添加标签信息
                if (conv.sysTagsArray_Count > 0) {
                    NSMutableArray *sysTags = [NSMutableArray arrayWithCapacity:conv.sysTagsArray_Count];
                    for (NSUInteger i = 0; i < conv.sysTagsArray_Count; i++) {
                        [sysTags addObject:conv.sysTagsArray[i]];
                    }
                    convDict[@"sys_tags"] = sysTags;
                }
                if (conv.userTagsArray_Count > 0) {
                    NSMutableArray *userTags = [NSMutableArray arrayWithCapacity:conv.userTagsArray_Count];
                    for (NSUInteger i = 0; i < conv.userTagsArray_Count; i++) {
                        [userTags addObject:conv.userTagsArray[i]];
                    }
                    convDict[@"user_tags"] = userTags;
                }
                
                // 添加免打扰状态
                convDict[@"disturb"] = @(conv.disturb);
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:convDict options:0 error:nil];
                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                NSLog(@"📋 解析单个会话成功: %@", conv.convId);
            } else {
                // 尝试直接作为 UTF-8 字符串处理
                jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                if (!jsonString) {
                    // 如果不是有效的 UTF-8，转为 hex 字符串用于调试
                    NSMutableString *hexString = [NSMutableString string];
                    const unsigned char *bytes = (const unsigned char *)responseData.bytes;
                    for (NSUInteger i = 0; i < MIN(responseData.length, 100); i++) {
                        [hexString appendFormat:@"%02x", bytes[i]];
                    }
                    NSLog(@"📋 响应数据(hex): %@...", hexString);
                    jsonString = @"{}";
                }
            }
        }
    }
    
    // 获取回调并执行
    IMSDKConversationManager *manager = [IMSDKConversationManager sharedManager];
    IMSDKConversationCompletion completion = [manager getCallbackForReqId:reqId];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager removeCallbackForReqId:reqId];
    }
}

// ==================== IMSDKConversationManager ====================

@implementation IMSDKConversationManager

+ (instancetype)sharedManager {
    static IMSDKConversationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKConversationManager alloc] init];
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

- (void)setCallback:(IMSDKConversationCompletion)completion forReqId:(uint64_t)reqId {
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[@(reqId)] = completion;
        }
    }
}

- (IMSDKConversationCompletion)getCallbackForReqId:(uint64_t)reqId {
    @synchronized (self.callbacks) {
        return self.callbacks[@(reqId)];
    }
}

- (void)removeCallbackForReqId:(uint64_t)reqId {
    @synchronized (self.callbacks) {
        [self.callbacks removeObjectForKey:@(reqId)];
    }
}

// ==================== 会话列表 ====================

- (int)getConversationATUnreadListWithPage:(int)page
                          pageSize:(int)pageSize
                          convType:(IMConversationType)convType
                              atMe:(BOOL)atme
                                completion:(IMSDKConversationCompletion)completion{
    NSLog(@"📋 获取会话列表: page=%d, pageSize=%d, convType=%ld", page, pageSize, (long)convType);
    
    // 构建查询请求
    ConvListQuery *query = [[ConvListQuery alloc] init];
    if (atme) {
        query.withUnread = true;
    }
    // 设置会话类型（如果需要过滤）
    if (convType >= 0) {
        query.convType = (ConversationType)convType;
    }
    
    // 设置分页
    Page *pageObj = [[Page alloc] init];
    pageObj.page = page;
    pageObj.size = pageSize;
    query.page = pageObj;
    
    NSLog(@"\n***************\n🍎 会话列表查询数据: 会话列表 第%d页,长度%d  会话类型 %d 是否是AT我的 %d \n***************",page,pageSize, query.convType,query.withUnread);
//    print("📋 获取会话列表: page=\(page), pageSize=\(pageSize), convType=\(convType)")
    // 序列化
    NSData *serializedData = [query data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印 hex 数据用于调试
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    for (NSUInteger i = 0; i < serializedData.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 5000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    // 全部:get_conversation_list
    // @我的: list_unread_conversations
    int result = list_unread_conversations(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 获取会话列表请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 获取会话列表请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)getConversationListWithPage:(int)page
                          pageSize:(int)pageSize
                          convType:(IMConversationType)convType
                              atMe:(BOOL)atme
                        completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 获取会话列表: page=%d, pageSize=%d, convType=%ld", page, pageSize, (long)convType);
    
    // 构建查询请求
    ConvListQuery *query = [[ConvListQuery alloc] init];
    // 设置会话类型（如果需要过滤）
    if (convType >= 0) {
        query.convType = (ConversationType)convType;
    }
    
    // 设置分页
    Page *pageObj = [[Page alloc] init];
    pageObj.page = page;
    pageObj.size = pageSize;
    query.page = pageObj;
    
    NSLog(@"\n***************\n🍎 会话列表查询数据: 会话列表 第%d页,长度%d  会话类型 %d \n***************",page,pageSize, query.convType);
//    print("📋 获取会话列表: page=\(page), pageSize=\(pageSize), convType=\(convType)")
    // 序列化
    NSData *serializedData = [query data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印 hex 数据用于调试
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    for (NSUInteger i = 0; i < serializedData.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 5000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    // 全部:get_conversation_list
    // @我的: list_unread_conversations
    int result = get_conversation_list(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 获取会话列表请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 获取会话列表请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

// ==================== 会话操作 ====================

- (int)getConversationWithId:(NSString *)convId
                  completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 获取会话: convId=%@", convId);
    
    if (!convId || convId.length == 0) {
        NSLog(@"❌ convId 不能为空");
        return -1;
    }
    
    // 构建请求
    GetConv *request = [[GetConv alloc] init];
    request.convId = convId;
    
    // 序列化
    NSData *serializedData = [request data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 6000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = get_conversation(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 获取会话请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 获取会话请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)createConversationWithType:(IMConversationType)convType
                         targetId:(NSString *)targetId
                      displayName:(NSString *)displayName
                       completion:(IMSDKConversationCompletion)completion {
    return [self createConversationWithParams:@{
        @"conv_type": @(convType),
        @"target_id": targetId ?: @"",
        @"display_name": displayName ?: @""
    } completion:completion];
}

- (int)createConversationWithParams:(NSDictionary *)params
                         completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 创建会话: %@", params);
    
    // 构建会话对象
    Conv *conv = [[Conv alloc] init];
    
    // 设置会话类型
    NSNumber *convTypeNum = params[@"conv_type"];
    if (convTypeNum) {
        conv.convType = (ConversationType)[convTypeNum intValue];
    }
    
    // 设置目标ID
    NSString *targetId = params[@"target_id"];
    if (targetId) {
        conv.targetId = targetId;
    }
    
    // 设置显示名称
    NSString *displayName = params[@"display_name"];
    if (displayName) {
        conv.displayName = displayName;
    }
    
    // 设置头像URL（可选）
    NSString *avatarURL = params[@"avatar_url"];
    if (avatarURL) {
        conv.avatarURL = avatarURL;
    }
    
    // 设置描述（可选）
    NSString *description = params[@"description"];
    if (description) {
        conv.description_p = description;
    }
    
    // 设置头像背景色（可选）
    NSString *avatarBg = params[@"avatar_bg"];
    if (avatarBg) {
        conv.avatarBg = avatarBg;
    }
    
    // 设置系统标签（可选）
    NSArray *sysTags = params[@"sys_tags"];
    if (sysTags && [sysTags isKindOfClass:[NSArray class]]) {
        [conv.sysTagsArray addObjectsFromArray:sysTags];
    }
    
    // 设置用户标签（可选）
    NSArray *userTags = params[@"user_tags"];
    if (userTags && [userTags isKindOfClass:[NSArray class]]) {
        [conv.userTagsArray addObjectsFromArray:userTags];
    }
    
    // 设置免打扰状态（可选）
    NSNumber *disturbNum = params[@"disturb"];
    if (disturbNum) {
        conv.disturb = [disturbNum boolValue];
    }
    
    // 序列化
    NSData *serializedData = [conv data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印 hex 数据用于调试
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    for (NSUInteger i = 0; i < serializedData.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    NSLog(@"\n📤 创建会话\n targetId: %@", conv.targetId);
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 7000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = create_conversation(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 创建会话请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 创建会话请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)deleteConversationWithId:(NSString *)convId
                     completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 删除会话: convId=%@", convId);
    
    if (!convId || convId.length == 0) {
        NSLog(@"❌ convId 不能为空");
        return -1;
    }
    
    // 构建请求
    DeleteConv *request = [[DeleteConv alloc] init];
    request.convId = convId;
    
    // 序列化
    NSData *serializedData = [request data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 8000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = delete_conversation(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 删除会话请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 删除会话请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)clearConversationMessagesWithId:(NSString *)convId
                            completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 清空会话消息: convId=%@", convId);
    
    if (!convId || convId.length == 0) {
        NSLog(@"❌ convId 不能为空");
        return -1;
    }
    
    // 构建请求（复用 DeleteConv 结构）
    DeleteConv *request = [[DeleteConv alloc] init];
    request.convId = convId;
    
    // 序列化
    NSData *serializedData = [request data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 9000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = clear_conversation_messages(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 清空会话消息请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 清空会话消息请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)markConversationReadWithId:(NSString *)convId msgIds:(NSString *)msgIds
                       completion:(IMSDKConversationCompletion)completion {
    
    if (!convId || convId.length == 0) {
        NSLog(@"❌ convId 不能为空");
        return -1;
    }
     
    
    // 构建请求（复用 DeleteConv 结构，只需要 convId）
    MarkRead *request = [[MarkRead alloc] init];
    request.conversationId  = convId;

    if (msgIds && msgIds.length != 0) {
        request.messageIdsArray = [msgIds componentsSeparatedByString:@","];
    }

    NSLog(@" \n标记会话 %@ \n相关消息: \n %@", request.conversationId,request.messageIdsArray);
    
    // 序列化
    NSData *serializedData = [request data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 10000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = mark_conversation_read(MarkReadCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 标记会话已读请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 标记会话已读请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

- (int)updateConversationWithId:(NSString *)convId
                         params:(NSDictionary *)params
                     completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 更新会话: convId=%@, params=%@", convId, params);
    
    if (!convId || convId.length == 0) {
        NSLog(@"❌ convId 不能为空");
        return -1;
    }
    
    // 构建会话对象
    Conv *conv = [[Conv alloc] init];
    conv.convId = convId;
    
    // 设置显示名称（可选）
    NSString *displayName = params[@"display_name"];
    if (displayName) {
        conv.displayName = displayName;
    }
    
    // 设置头像URL（可选）
    NSString *avatarURL = params[@"avatar_url"];
    if (avatarURL) {
        conv.avatarURL = avatarURL;
    }
    
    // 设置描述（可选）
    NSString *description = params[@"description"];
    if (description) {
        conv.description_p = description;
    }
    
    // 设置头像背景色（可选）
    NSString *avatarBg = params[@"avatar_bg"];
    if (avatarBg) {
        conv.avatarBg = avatarBg;
    }
    
    // 设置系统标签（可选）
    NSArray *sysTags = params[@"sys_tags"];
    if (sysTags && [sysTags isKindOfClass:[NSArray class]]) {
        [conv.sysTagsArray addObjectsFromArray:sysTags];
    }
    
    // 设置用户标签（可选）
    NSArray *userTags = params[@"user_tags"];
    if (userTags && [userTags isKindOfClass:[NSArray class]]) {
        [conv.userTagsArray addObjectsFromArray:userTags];
    }
    
    // 设置免打扰状态（可选）
    NSNumber *disturbNum = params[@"disturb"];
    if (disturbNum) {
        conv.disturb = [disturbNum boolValue];
    }
    
    // 序列化
    NSData *serializedData = [conv data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 11000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = update_conversation(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 更新会话请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 更新会话请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

// ==================== 未读会话列表 ====================

- (int)getUnreadConversationsWithPage:(int)page
                             pageSize:(int)pageSize
                             convType:(IMConversationType)convType
                           completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 获取未读会话列表 page=%d pageSize=%d convType=%ld", page, pageSize, (long)convType);
    
    // 构建查询请求
    ConvListQuery *query = [[ConvListQuery alloc] init];
    
    // 设置会话类型（如果需要过滤）
    if (convType >= 0) {
        query.convType = (ConversationType)convType;
    }
    
    // 设置分页
    Page *pageObj = [[Page alloc] init];
    pageObj.page = page;
    pageObj.size = pageSize;
    query.page = pageObj;
    
    // 序列化
    NSData *serializedData = [query data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 13000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = list_unread_conversations(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 获取未读会话列表请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 获取未读会话列表请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

// ==================== 群组操作 ====================

- (int)createGroupWithName:(NSString *)groupName
                 memberIds:(NSArray<NSString *> *)memberIds
                 avatarUrl:(NSString * _Nullable)avatarUrl
                completion:(IMSDKConversationCompletion)completion {
    NSLog(@"📋 创建群聊: groupName=%@, memberIds=%@", groupName, memberIds);
    
    if (!groupName || groupName.length == 0) {
        NSLog(@"❌ 群名称不能为空");
        return -1;
    }
    
    if (!memberIds || memberIds.count == 0) {
        NSLog(@"❌ 群成员不能为空");
        return -1;
    }
    
    // 使用 JSON 格式构建请求体
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"group_name"] = groupName;
    params[@"member_ids"] = memberIds;
    
    if (avatarUrl && avatarUrl.length > 0) {
        params[@"avatar_url"] = avatarUrl;
    }
    
    // 序列化为 JSON
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    if (error || !jsonData) {
        NSLog(@"❌ JSON 序列化失败: %@", error);
        return -1;
    }
    
    const char *data = (const char *)jsonData.bytes;
    int dataLen = (int)jsonData.length;
    uint64_t reqId = 0;
    
    // 保存回调
    static uint64_t tempId = 12000;
    NSNumber *tempKey = @(tempId++);
    if (completion) {
        @synchronized (self.callbacks) {
            self.callbacks[tempKey] = completion;
        }
    }
    
    int result = create_group(ConversationCallback, data, dataLen, reqId);
    
    if (result == 0) {
        NSLog(@"✅ 创建群聊请求发送成功: reqId=%llu", reqId);
        if (reqId != 0 && completion) {
            [self setCallback:completion forReqId:reqId];
            @synchronized (self.callbacks) {
                [self.callbacks removeObjectForKey:tempKey];
            }
        }
    } else {
        NSLog(@"❌ 创建群聊请求失败: %d", result);
        @synchronized (self.callbacks) {
            [self.callbacks removeObjectForKey:tempKey];
        }
    }
    
    return result;
}

@end

