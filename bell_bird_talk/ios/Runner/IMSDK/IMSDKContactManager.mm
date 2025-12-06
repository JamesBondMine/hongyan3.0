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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && data && dataLen > 0) {
                // 尝试解析为 ContactAddResult Protobuf
                NSData *responseData = [NSData dataWithBytes:data length:dataLen];
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
                    dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (data && dataLen > 0) {
                dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

/// 拉黑/取消拉黑回调
static void BlockContactCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🚫 拉黑联系人回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (data && dataLen > 0) {
                dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.contactCallbacks removeObjectForKey:key];
        }
    });
}

/// 联系人列表/搜索回调
static void ContactListCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📋 联系人列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKContactManager *manager = [IMSDKContactManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKContactCompletion completion = manager.contactCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && data && dataLen > 0) {
                // 尝试解析为 ContactList Protobuf
                NSData *responseData = [NSData dataWithBytes:data length:dataLen];
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
                    dataStr = [[NSString alloc] initWithBytes:data length:dataLen encoding:NSUTF8StringEncoding];
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
    
    // 设置目标值（必填）
    contact.targetValue = targetValue;
    
    // 设置添加渠道（默认用户ID）
    int channel = [params[@"channel"] intValue];
    contact.addChannel = (AddChannel)channel;
    
    // 设置验证消息（可选）
    NSString *message = params[@"message"];
    if (message && message.length > 0) {
        contact.message = message;
    }
    
    // 设置目标手机号（可选）
    NSString *targetPhone = params[@"target_phone"];
    if (targetPhone && targetPhone.length > 0) {
        contact.targetPhone = targetPhone;
    }
    
    // 设置目标邮箱（可选）
    NSString *targetEmail = params[@"target_email"];
    if (targetEmail && targetEmail.length > 0) {
        contact.targetEmail = targetEmail;
    }
    
    // 设置目标账户ID（可选）
    NSString *targetAccountId = params[@"target_account_id"];
    if (targetAccountId && targetAccountId.length > 0) {
        contact.targetAccountId = targetAccountId;
    }
    
    // 序列化为 Protobuf 二进制数据（格式3：纯 Protobuf）
    NSData *protoBody = [contact data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 Contact Protobuf 数据长度: %lu 字节", (unsigned long)protoBody.length);
    
    // 打印十六进制数据（用于调试）
    NSMutableString *hexString = [NSMutableString string];
    const unsigned char *bytes = (const unsigned char *)protoBody.bytes;
    NSUInteger printLen = MIN(protoBody.length, 64);
    for (NSUInteger i = 0; i < printLen; i++) {
        [hexString appendFormat:@"%02x ", bytes[i]];
        if ((i + 1) % 16 == 0) [hexString appendString:@"\n                        "];
    }
    NSLog(@"🔍 Protobuf 数据 (HEX):\n                        %@", hexString);
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    const char *targetId = [targetUserId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 6000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        NSLog(@"🚀 调用 add_contact...");
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

- (int)deleteContactWithUserId:(NSString *)userId
                    completion:(IMSDKContactCompletion)completion {
    NSLog(@"🗑️ 删除联系人: %@", userId);
    
    if (!userId || userId.length == 0) {
        NSLog(@"❌ 用户ID不能为空");
        return -1;
    }
    
    // 创建 ContactQuery 对象
    ContactQuery *query = [[ContactQuery alloc] init];
    query.contactUserId = userId;
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    const char *targetId = [userId UTF8String];
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
                   completion:(IMSDKContactCompletion)completion {
    NSLog(@"📋 获取联系人列表: page=%d, pageSize=%d", page, pageSize);
    
    // 创建 ContactQuery 对象
    ContactQuery *query = [[ContactQuery alloc] init];
    query.page = page;
    query.pageSize = pageSize;
    
    NSData *protoBody = [query data];
    if (!protoBody || protoBody.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)protoBody.bytes;
    int dataLen = (int)protoBody.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 10000;
        NSNumber *tempKey = @(tempId++);
        self.contactCallbacks[tempKey] = completion;
        
        // 使用 search_contact 代替 list_contacts（SDK 未提供 list_contacts 方法）
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

@end

