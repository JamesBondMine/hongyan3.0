//
//  IMSDKContactManager.mm
//  Runner
//
//  IM SDK 联系人管理类实现
//

#import "IMSDKContactManager.h"
#import "ContactPb.pbobjc.h"
#import <UIKit/UIKit.h>
#include "network_lib.h"
#include "callback_types.h"

@interface IMSDKContactManager ()

/// 回调存储（用于异步回调）
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, IMSDKContactCompletion> *contactCallbacks;

@end

// ==================== C++ 回调函数 ====================

/// 添加联系人回调
static void AddContactCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 添加联系人回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析为 ContactAddResult Protobuf
                NSError *parseError = nil;
                ContactAddResult *result = [ContactAddResult parseFromData:responseData error:&parseError];
                
                if (result && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                    jsonDict[@"success"] = @(result.success);
                    jsonDict[@"error_code"] = @(result.errorCode);
                    jsonDict[@"error_message"] = result.errorMessage ?: @"";
                    jsonDict[@"contact_user_id"] = result.contactUserId ?: @"";
                    jsonDict[@"add_time"] = @(result.addTime);
                    jsonDict[@"requires_approval"] = @(result.requiresApproval);
                    jsonDict[@"request_id"] = @(result.requestId);
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 添加联系人响应解析成功: %@", dataStr);
                } else {
                    // 尝试直接作为 JSON 解析
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                }
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

/// 删除联系人回调
static void DeleteContactCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🗑️ 删除联系人回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

/// 拉黑/取消拉黑回调
static void BlockContactCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🚫 拉黑联系人回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

/// 联系人列表/搜索回调
static void ContactListCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📋 联系人列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    // ⚠️ 重要：在异步分发之前拷贝数据！
    // data 指针在回调返回后可能被 SDK 释放，必须立即拷贝
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
        NSLog(@"📦 已拷贝数据: %lu 字节", (unsigned long)responseData.length);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析为 ContactList Protobuf
                NSError *parseError = nil;
                ContactList *result = [ContactList parseFromData:responseData error:&parseError];
                
                if (result && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                    jsonDict[@"total_count"] = @(result.totalCount);
                    jsonDict[@"page"] = @(result.page);
                    jsonDict[@"page_size"] = @(result.pageSize);
                    
                    NSMutableArray *contactsArray = [NSMutableArray array];
                    for (Contact *contact in result.contactsArray) {
                        NSMutableDictionary *contactDict = [NSMutableDictionary dictionary];
                        contactDict[@"contact_user_id"] = contact.contactUserId ?: @"";
                        contactDict[@"account_id"] = contact.accountId ?: @"";
                        contactDict[@"nickname"] = contact.nickname ?: @"";
                        contactDict[@"avatar"] = contact.avatar ?: @"";
                        contactDict[@"remark"] = contact.remark ?: @"";
                        contactDict[@"relationship"] = @(contact.relationship);
                        contactDict[@"online_status"] = @(contact.onlineStatus);
                        [contactsArray addObject:contactDict];
                    }
                    jsonDict[@"contacts"] = contactsArray;
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 联系人列表解析成功: %lu 个联系人", (unsigned long)result.contactsArray_Count);
                } else {
                    NSLog(@"⚠️ Protobuf 解析失败: %@", parseError);
                    // 返回空数据
                    dataStr = @"{\"contacts\":[],\"total_count\":0,\"page\":1,\"page_size\":20}";
                }
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

// ==================== 实现类 ====================

@implementation IMSDKContactManager

+ (instancetype)sharedManager {
    static IMSDKContactManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKContactManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _contactCallbacks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 好友申请

- (int)addContactWithUserId:(NSString *)targetUserId
                    channel:(int)channel
                    message:(NSString * _Nullable)message
                 completion:(IMSDKContactCompletion)completion {
    
    return [self addContactWithParams:@{
        @"target_user_id": targetUserId,
        @"target_value": targetUserId,
        @"channel": @(channel),
        @"message": message ?: @""
    } completion:completion];
}

- (int)addContactWithParams:(NSDictionary *)params
                 completion:(IMSDKContactCompletion)completion {
    NSLog(@"👥 添加联系人: %@", params);
    
    NSString *targetUserId = params[@"target_user_id"];
    NSString *targetValue = params[@"target_value"] ?: targetUserId;
        if (!targetUserId || targetUserId.length == 0) {
        NSLog(@"❌ 目标用户ID不能为空");
        return -1;
    }
    
    // 创建 Contact Protobuf 对象
    Contact *contact = [[Contact alloc] init];
    contact.targetValue = targetUserId;

    // 设置添加渠道（默认用户ID）
//    int channel = [params[@"channel"] intValue];
//    contact.addChannel = (AddChannel)channel;
//    
    // 设置验证消息（可选）
    NSString *message = params[@"message"];
    if (message && message.length > 0) {
        contact.message = message;
        contact.remark = message;
    }
    
    // 设置分组ID（可选）
    NSNumber *groupIdObj = params[@"group_id"];
    if (groupIdObj != nil) {
        int64_t groupId = [groupIdObj longLongValue];
        if (groupId > 0) {
            contact.groupId = groupId;
            NSLog(@"📁 设置分组ID: %lld", groupId);
        }
    }
    
//
    // 设置目标手机号（可选）
    NSString *targetPhone = params[@"target_phone"];
    if (targetPhone && targetPhone.length > 0) {
//        contact.targetPhone = targetPhone;
        // 设置目标值（必填）
//        contact.targetValue = targetPhone;
    }
    
//    // 设置目标邮箱（可选）
//    NSString *targetEmail = params[@"target_email"];
//    if (targetEmail && targetEmail.length > 0) {
//        contact.targetEmail = targetEmail;
//        // 设置目标值（必填）
//        contact.targetValue = targetEmail;
//    }
//    
    // 设置目标账户ID（可选）
    NSString *targetAccountId = params[@"target_account_id"];
    if (targetAccountId && targetAccountId.length > 0) {
//        contact.targetAccountId = targetAccountId;
//        contact.targetValue = targetAccountId;
    } else {
//        contact.targetAccountId = targetUserId;
//        contact.targetValue = targetAccountId;
    }
    
    NSLog(@"\n添加好友信息\n==============================\n targetValue: %@ \n addChannel:%d \n targetPhone:%@ \n message:%@ \n targetAccountId:%@ \n targetEmail:%@ \n groupId:%lld \n",contact.targetValue,contact.addChannel,contact.targetPhone,contact.message,contact.targetAccountId,contact.targetEmail,contact.groupId);
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [contact data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // ✅ 使用格式3: 纯 Protobuf 二进制（不带 varint32 头部）
    // 与注册、登录、搜索用户等接口保持一致
    
    NSLog(@"📦 Protobuf 数据长度: %lu 字节", (unsigned long)serializedData.length);
    
    // 打印十六进制数据（用于验证格式）
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)serializedData.bytes;
    NSUInteger printLen = MIN(serializedData.length, 64); // 打印前64字节
    for (NSUInteger i = 0; i < printLen; i++) {
        [hexString appendFormat:@"%02x ", bytes[i]];
        if ((i + 1) % 16 == 0) [hexString appendString:@"\n                        "];
    }
    NSLog(@"🔍 Protobuf 数据 (HEX):\n                        %@", hexString);
    
    // 直接使用纯 Protobuf 二进制数据，不添加 varint32 头部
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    const char *targetId = [targetUserId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 6000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        NSLog(@"🚀 调用 add_contact...");
        NSLog(@"📍 data 指针: %p", data);
        NSLog(@"📍 dataLen: %d", dataLen);
        NSLog(@"📍 targetId: %s", targetId);
        
        int result = add_contact(AddContactCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 添加联系人请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 添加联系人请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return add_contact(AddContactCallback, data, dataLen, targetId, reqId);
}

#pragma mark - 好友管理

- (int)deleteContactWithUserId:(NSString *)contact_user_id
                    completion:(IMSDKContactCompletion)completion {
    NSLog(@"🗑️ 删除联系人: %@", contact_user_id);
    
    if (!contact_user_id || contact_user_id.length == 0) {
        NSLog(@"❌ 用户ID不能为空");
        return -1;
    }
    
    // 创建 ContactQuery 对象
    Contact *query = [[Contact alloc] init];
    query.contactUserId = contact_user_id;
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    const char *targetId = [contact_user_id UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 7000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = delete_contact(DeleteContactCallback, data, dataLen, targetId, reqId);
        
        if (result == 0 && reqId != 0) {
            self.contactCallbacks[@(reqId)] = completion;
            [self.contactCallbacks removeObjectForKey:tempKey];
        } else if (result != 0) {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return delete_contact(DeleteContactCallback, data, dataLen, targetId, reqId);
}

- (int)blockContactWithUserId:(NSString *)userId
                   completion:(IMSDKContactCompletion)completion {
    NSLog(@"🚫 拉黑用户: %@", userId);
    
    if (!userId || userId.length == 0) {
        NSLog(@"❌ 用户ID不能为空");
        return -1;
    }
    
    // 创建 Block 对象
    Block *blockObj = [[Block alloc] init];
    blockObj.targetUserId = userId;
    
    
    NSData *protoBody = [blockObj data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    const char *targetId = [userId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 8000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = block_contact(BlockContactCallback, data, dataLen, targetId, reqId);
        
        if (result == 0 && reqId != 0) {
            self.contactCallbacks[@(reqId)] = completion;
            [self.contactCallbacks removeObjectForKey:tempKey];
        } else if (result != 0) {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return block_contact(BlockContactCallback, data, dataLen, targetId, reqId);
}

- (int)unblockContactWithUserId:(NSString *)userId
                     completion:(IMSDKContactCompletion)completion {
    NSLog(@"✅ 取消拉黑用户: %@", userId);
    
    if (!userId || userId.length == 0) {
        NSLog(@"❌ 用户ID不能为空");
        return -1;
    }
    
    // 创建 Block 对象
    Block *blockObj = [[Block alloc] init];
    blockObj.targetUserId = userId;
    
    NSData *protoBody = [blockObj data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    const char *targetId = [userId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 9000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = unblock_contact(BlockContactCallback, data, dataLen, targetId, reqId);
        
        if (result == 0 && reqId != 0) {
            self.contactCallbacks[@(reqId)] = completion;
            [self.contactCallbacks removeObjectForKey:tempKey];
        } else if (result != 0) {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return unblock_contact(BlockContactCallback, data, dataLen, targetId, reqId);
}

#pragma mark - 好友查询

- (int)getContactListWithPage:(int)page
                     pageSize:(int)pageSize
                 relationship:(int)relationship
                       groupId:(int64_t)groupId
                   completion:(IMSDKContactCompletion)completion {
    NSLog(@"📋 获取联系人列表: page=%d, pageSize=%d, relationship=%d, groupId=%lld", page, pageSize, relationship, groupId);
    
    // 创建 ContactQuery 对象
    ContactQuery *query = [[ContactQuery alloc] init];
    query.page = page;
    query.pageSize = pageSize;
    
    // 设置分组ID（如果大于0）
    if (groupId > 0) {
        query.groupId = groupId;
    }
    
    // relationship: 0=好友, 1=关注, 2=黑名单, 3=待确认, -1=全部（不设置）
    if (relationship >= 0) {
        query.relationship = (Relationship)relationship;
    }
    // 如果 relationship < 0，则不设置，表示获取全部
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印序列化数据（调试用）
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoBody.bytes;
    for (NSUInteger i = 0; i < MIN(protoBody.length, 32); i++) {
        [hexString appendFormat:@"%02x ", bytes[i]];
    }
    NSLog(@"📤 ContactQuery 数据 (HEX): %@", hexString);
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 10000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        // 使用 get_contact_list 获取联系人列表
        int result = get_contact_list(ContactListCallback, data, dataLen, reqId);
        
        NSLog(@"📡 get_contact_list 返回: result=%d, reqId=%llu", result, reqId);
        
        if (result == 0 && reqId != 0) {
            self.contactCallbacks[@(reqId)] = completion;
            [self.contactCallbacks removeObjectForKey:tempKey];
        } else if (result != 0) {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return get_contact_list(ContactListCallback, data, dataLen, reqId);
}

- (int)searchContactWithKeyword:(NSString *)keyword
                     completion:(IMSDKContactCompletion)completion {
    NSLog(@"🔍 搜索联系人: %@", keyword);
    
    if (!keyword || keyword.length == 0) {
        NSLog(@"❌ 搜索关键词不能为空");
        return -1;
    }
    
    // 创建 ContactQuery 对象
    ContactQuery *query = [[ContactQuery alloc] init];
    query.keyword = keyword;
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 11000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = search_contact(ContactListCallback, data, dataLen, "", reqId);
        
        if (result == 0 && reqId != 0) {
            self.contactCallbacks[@(reqId)] = completion;
            [self.contactCallbacks removeObjectForKey:tempKey];
        } else if (result != 0) {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return search_contact(ContactListCallback, data, dataLen, "", reqId);
}

// ==================== 好友申请 ====================

// 好友申请列表回调
static void FriendRequestCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔔 好友申请回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
        
        // 尝试解析为 RequestList
        NSError *error = nil;
        RequestList *requestList = [RequestList parseFromData:responseData error:&error];
        if (!error && requestList) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[@"total_count"] = @(requestList.totalCount);
            result[@"page"] = @(requestList.page);
            result[@"page_size"] = @(requestList.pageSize);
            
            NSMutableArray *requestsArray = [NSMutableArray array];
            for (Request *request in requestList.requestsArray) {
                NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];
                requestDict[@"request_id"] = @(request.requestId);
                requestDict[@"requester_id"] = request.requesterId ?: @"";
                requestDict[@"requester_name"] = request.requesterName ?: @"";
                requestDict[@"requester_avatar"] = request.requesterAvatar ?: @"";
                requestDict[@"message"] = request.message ?: @"";
                requestDict[@"channel"] = @(request.channel);
                requestDict[@"status"] = @(request.status);
                requestDict[@"request_time"] = @(request.requestTime);
                requestDict[@"expire_time"] = @(request.expireTime);
                [requestsArray addObject:requestDict];
            }
            result[@"requests"] = requestsArray;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"✅ 解析好友申请列表成功: %lu 条", (unsigned long)requestsArray.count);
        } else {
            // 尝试直接作为字符串
            jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (!jsonString) {
                jsonString = @"{}";
            }
        }
    }
    
    IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
    IMSDKContactCompletion completion = manager.contactCallbacks[@(reqId)];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager.contactCallbacks removeObjectForKey:@(reqId)];
    }
}

- (int)getFriendRequestsWithStatus:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKContactCompletion)completion {
    NSLog(@"📋 获取好友申请列表: status=%d, page=%d, pageSize=%d", status, page, pageSize);
    
    // 构建查询请求
    RequestQuery *query = [[RequestQuery alloc] init];
    if (status >= 0) {
        query.status = (RequestStatus)status;
    }
    query.page = page;
    query.pageSize = pageSize;
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印 hex 数据
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoBody.bytes;
    for (NSUInteger i = 0; i < protoBody.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    NSLog(@"📤 好友申请查询数据(hex): %@", hexString);
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 12000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = get_friend_requests(FriendRequestCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 获取好友申请请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 获取好友申请请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return get_friend_requests(FriendRequestCallback, data, dataLen, reqId);
}

- (int)acceptFriendRequestWithId:(int64_t)requestId
                      completion:(IMSDKContactCompletion)completion {
    NSLog(@"✅ 同意好友申请: requestId=%lld", requestId);
    
    // 构建请求
    Request *request = [[Request alloc] init];
    request.requestId = requestId;
    
    NSData *protoBody = [request data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 13000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = accept_friend_request(AddContactCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 同意申请请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 同意申请请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return accept_friend_request(AddContactCallback, data, dataLen, reqId);
}

- (int)rejectFriendRequestWithId:(int64_t)requestId
                          reason:(NSString * _Nullable)reason
                      completion:(IMSDKContactCompletion)completion {
    NSLog(@"❌ 拒绝好友申请: requestId=%lld, reason=%@", requestId, reason);
    
    // 构建请求
    Request *request = [[Request alloc] init];
    request.requestId = requestId;
    if (reason && reason.length > 0) {
        request.reason = reason;
    }
    
    NSData *protoBody = [request data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 14000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = reject_friend_request(AddContactCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 拒绝申请请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 拒绝申请请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return reject_friend_request(AddContactCallback, data, dataLen, reqId);
}

// ==================== 联系人分组 ====================

// 分组列表回调
static void ContactGroupsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 联系人分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
        
        // 尝试解析为 GroupList
        NSError *error = nil;
        GroupList *groupList = [GroupList parseFromData:responseData error:&error];
        if (!error && groupList) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[@"total_count"] = @(groupList.totalCount);
            
            NSMutableArray *groupsArray = [NSMutableArray array];
            for (ContactGroup *group in groupList.groupsArray) {
                NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
                groupDict[@"group_id"] = @(group.groupId);
                groupDict[@"group_name"] = group.groupName ?: @"";
                groupDict[@"group_color"] = group.groupColor ?: @"";
                groupDict[@"group_order"] = @(group.groupOrder);
                groupDict[@"group_icon"] = group.groupIcon ?: @"";
                groupDict[@"group_description"] = group.groupDescription ?: @"";
                groupDict[@"contact_count"] = @(group.contactCount);
                groupDict[@"create_time"] = @(group.createTime);
                groupDict[@"update_time"] = @(group.updateTime);
                [groupsArray addObject:groupDict];
            }
            result[@"groups"] = groupsArray;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"✅ 解析联系人分组成功: %lu 个分组", (unsigned long)groupsArray.count);
        } else {
            // 尝试直接作为字符串
            jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (!jsonString) {
                jsonString = @"{}";
            }
        }
    }
    
    IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
    IMSDKContactCompletion completion = manager.contactCallbacks[@(reqId)];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager.contactCallbacks removeObjectForKey:@(reqId)];
    }
}

- (int)getContactGroupsWithPage:(int)page
                       pageSize:(int)pageSize
                     completion:(IMSDKContactCompletion)completion {
    NSLog(@"📁 获取联系人分组列表: page=%d, pageSize=%d", page, pageSize);
    
    // 构建查询请求
    GroupQuery *query = [[GroupQuery alloc] init];
    query.page = page;
    query.pageSize = pageSize;
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    // 打印 hex 数据
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoBody.bytes;
    for (NSUInteger i = 0; i < protoBody.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    NSLog(@"📤 分组查询数据(hex): %@", hexString);
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 15000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = list_contact_groups(ContactGroupsCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 获取分组列表请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 获取分组列表请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return list_contact_groups(ContactGroupsCallback, data, dataLen, reqId);
}

// 创建分组回调
static void CreateContactGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 创建联系人分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
        
        // 尝试解析为 ContactGroup
        NSError *error = nil;
        ContactGroup *group = [ContactGroup parseFromData:responseData error:&error];
        if (!error && group) {
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            groupDict[@"group_id"] = @(group.groupId);
            groupDict[@"group_name"] = group.groupName ?: @"";
            groupDict[@"group_color"] = group.groupColor ?: @"";
            groupDict[@"group_order"] = @(group.groupOrder);
            groupDict[@"group_icon"] = group.groupIcon ?: @"";
            groupDict[@"group_description"] = group.groupDescription ?: @"";
            groupDict[@"contact_count"] = @(group.contactCount);
            groupDict[@"create_time"] = @(group.createTime);
            groupDict[@"update_time"] = @(group.updateTime);
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:groupDict options:0 error:nil];
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"✅ 解析创建分组响应成功: %@", jsonString);
        } else {
            // 尝试直接作为字符串
            jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (!jsonString) {
                jsonString = @"{}";
            }
        }
    }
    
    IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
    IMSDKContactCompletion completion = manager.contactCallbacks[@(reqId)];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager.contactCallbacks removeObjectForKey:@(reqId)];
    }
}

- (int)createContactGroupWithName:(NSString *)groupName
                        groupColor:(NSString * _Nullable)groupColor
                        groupOrder:(int32_t)groupOrder
                         groupIcon:(NSString * _Nullable)groupIcon
                   groupDescription:(NSString * _Nullable)groupDescription
                        completion:(IMSDKContactCompletion)completion {
    NSLog(@"📁 创建联系人分组: groupName=%@", groupName);
    
    if (!groupName || groupName.length == 0) {
        NSLog(@"❌ 分组名称不能为空");
        return -1;
    }
    
    // 创建 GroupCreate Protobuf 对象
    GroupCreate *groupCreate = [[GroupCreate alloc] init];
    groupCreate.groupName = groupName;
    if (groupColor && groupColor.length > 0) {
        groupCreate.groupColor = groupColor;
    }
    if (groupOrder > 0) {
        groupCreate.groupOrder = groupOrder;
    }
    if (groupIcon && groupIcon.length > 0) {
        groupCreate.groupIcon = groupIcon;
    }
    if (groupDescription && groupDescription.length > 0) {
        groupCreate.groupDescription = groupDescription;
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [groupCreate data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 创建分组 Protobuf 数据长度: %lu 字节", (unsigned long)serializedData.length);
    
    // 使用纯 Protobuf 二进制数据
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 16000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = create_contact_group(CreateContactGroupCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 创建分组请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 创建分组请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return create_contact_group(CreateContactGroupCallback, data, dataLen, reqId);
}

// 更新分组回调
static void UpdateContactGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 更新联系人分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSString *jsonString = nil;
    if (data && dataLen > 0) {
        NSData *responseData = [NSData dataWithBytes:data length:dataLen];
        NSError *error = nil;
        ContactGroup *group = [ContactGroup parseFromData:responseData error:&error];
        if (!error && group) {
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            groupDict[@"group_id"] = @(group.groupId);
            groupDict[@"group_name"] = group.groupName ?: @"";
            groupDict[@"group_color"] = group.groupColor ?: @"";
            groupDict[@"group_order"] = @(group.groupOrder);
            groupDict[@"group_icon"] = group.groupIcon ?: @"";
            groupDict[@"group_description"] = group.groupDescription ?: @"";
            groupDict[@"contact_count"] = @(group.contactCount);
            groupDict[@"create_time"] = @(group.createTime);
            groupDict[@"update_time"] = @(group.updateTime);
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:groupDict options:0 error:nil];
            if (jsonData) {
                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        }
    }
    IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
    IMSDKContactCompletion completion = manager.contactCallbacks[@(reqId)];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, jsonString);
        });
        [manager.contactCallbacks removeObjectForKey:@(reqId)];
    }
}

// 删除分组回调
static void DeleteContactGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 删除联系人分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSString *message = @"删除成功";
    if (errorCode != 0 && data && dataLen > 0) {
        NSData *resp = [NSData dataWithBytes:data length:dataLen];
        message = [[NSString alloc] initWithData:resp encoding:NSUTF8StringEncoding] ?: @"删除失败";
    }
    IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
    IMSDKContactCompletion completion = manager.contactCallbacks[@(reqId)];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(errorCode, reqId, message);
        });
        [manager.contactCallbacks removeObjectForKey:@(reqId)];
    }
}

- (int)updateContactGroupWithId:(int64_t)groupId
                      groupName:(NSString * _Nullable)groupName
                     groupColor:(NSString * _Nullable)groupColor
                     groupOrder:(int32_t)groupOrder
                      groupIcon:(NSString * _Nullable)groupIcon
                groupDescription:(NSString * _Nullable)groupDescription
                      completion:(IMSDKContactCompletion)completion {
    if (groupId <= 0) {
        NSLog(@"❌ 分组ID不能为空");
        return -1;
    }
    NSLog(@"📁 更新联系人分组: groupId=%lld, name=%@", groupId, groupName);
    
    GroupUpdate *update = [GroupUpdate message];
    update.groupId = groupId;
    if (groupName && groupName.length > 0) update.groupName = groupName;
    if (groupColor && groupColor.length > 0) update.groupColor = groupColor;
    if (groupOrder > 0) update.groupOrder = groupOrder;
    if (groupIcon && groupIcon.length > 0) update.groupIcon = groupIcon;
    if (groupDescription && groupDescription.length > 0) update.groupDescription = groupDescription;
    
    NSData *protoData = [update data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ 序列化 GroupUpdate 失败");
        return -2;
    }
    
    uint64_t reqId = 0;
    if (completion) {
        static uint64_t tempId = 17000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = update_contact_group(UpdateContactGroupCallback, (const char *)protoData.bytes, (int)protoData.length, reqId);
        if (result == 0) {
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        return result;
    }
    
    return update_contact_group(UpdateContactGroupCallback, (const char *)protoData.bytes, (int)protoData.length, reqId);
}

- (int)deleteContactGroupWithId:(int64_t)groupId
                      completion:(IMSDKContactCompletion)completion {
    if (groupId <= 0) {
        NSLog(@"❌ 分组ID不能为空");
        return -1;
    }
    NSLog(@"📁 删除联系人分组: groupId=%lld", groupId);
    
    GroupQuery *query = [GroupQuery message];
    query.groupId = groupId;
    NSData *protoData = [query data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ 序列化 GroupQuery 失败");
        return -2;
    }
    
    uint64_t reqId = 0;
    if (completion) {
        static uint64_t tempId = 18000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = delete_contact_group(DeleteContactGroupCallback, (const char *)protoData.bytes, (int)protoData.length, reqId);
        if (result == 0) {
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        return result;
    }
    
    return delete_contact_group(DeleteContactGroupCallback, (const char *)protoData.bytes, (int)protoData.length, reqId);
}

// ==================== 联系人备注 ====================

/// 设置备注回调
static void SetContactRemarkCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📨 设置备注回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *message = @"设置备注成功";
            if (errorCode != 0) {
                message = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"设置备注失败";
            }
            
            completion(errorCode, reqId, message);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

- (int)setRemarkForUserId:(NSString *)userId remark:(NSString *)remark completion:(IMSDKContactCompletion)completion {
    NSLog(@"📤 设置联系人备注: userId=%@, remark=%@", userId, remark);
    
    if (!userId || userId.length == 0) {
        NSLog(@"❌ 用户ID不能为空");
        return -1;
    }
    
    // 创建 ContactRemark 对象
    ContactRemark *contactRemark = [[ContactRemark alloc] init];
    contactRemark.contactUserId = userId;
    contactRemark.remark = remark ?: @"";
    
    // 序列化
    NSData *protoBody = [contactRemark data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ 序列化 ContactRemark 失败");
        return -2;
    }
    
    NSLog(@"📦 ContactRemark 序列化: %lu 字节", (unsigned long)protoBody.length);
    
    // 打印 hex 调试
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoBody.bytes;
    for (NSUInteger i = 0; i < protoBody.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    NSLog(@"📤 设置备注数据(hex): %@", hexString);
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 16000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        int result = set_contact_remark(SetContactRemarkCallback, data, dataLen, userId.UTF8String, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 设置备注请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.contactCallbacks[@(reqId)] = completion;
                [self.contactCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 设置备注请求失败: %d", result);
            [self.contactCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return set_contact_remark(SetContactRemarkCallback, data, dataLen, userId.UTF8String, reqId);
}

@end

