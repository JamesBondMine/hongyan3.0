//
//  IMSDKCommunityManager.mm
//  Runner
//
//  IM SDK 社群管理类实现
//

#import "IMSDKCommunityManager.h"
#import "CmtyPb.pbobjc.h"
#import "SystemPb.pbobjc.h"
#import <UIKit/UIKit.h>
#include "network_lib.h"
#include "callback_types.h"

@interface IMSDKCommunityManager ()

/// 回调存储（用于异步回调）
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, IMSDKCommunityCompletion> *communityCallbacks;

@end

// ==================== C++ 回调函数 ====================

/// 获取社群列表回调
static void ListCommunitiesCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 获取社群列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKCommunityManager *manager = [IMSDKCommunityManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKCommunityCompletion completion = manager.communityCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            NSString *message = @"成功";
            if (errorCode != 0) {
                message = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"失败";
                completion(errorCode, reqId, message);
            }
            NSLog(@"%@",message);
            if (errorCode == 0 && responseData && responseData.length > 0) {
                NSError *parseError = nil;
                // 解析为 CmtyList
                CmtyList *result = [CmtyList parseFromData:responseData error:&parseError];
                if (!result || parseError) {
                    parseError = nil;
                }
                NSMutableArray *communities = [NSMutableArray array];
                if (result) {
                    for (Cmty *cmty in result.communitiesArray) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        dict[@"id"] = cmty.communityId ?: @"";
                        dict[@"name"] = cmty.communityName ?: @"";
                        dict[@"avatar"] = cmty.communityAvatar ?: @"";
                        dict[@"description"] = cmty.description_p ?: @"";
                        dict[@"owner_id"] = cmty.ownerId ?: @"";
                        dict[@"member_count"] = @(cmty.memberCount);
                        dict[@"status"] = @(cmty.status);
                        dict[@"need_verify"] = @(cmty.needVerify);
                        dict[@"allow_private_chat"] = @(cmty.allowPrivateChat);
                        dict[@"allow_add_friend"] = @(cmty.allowAddFriend);
                        dict[@"created_at"] = @(cmty.createdAt);
                        dict[@"updated_at"] = @(cmty.updatedAt);
                        dict[@"extra_info"] = cmty.extraInfo ?: @"";
                        dict[@"is_member"] = @(cmty.isMember);
                        [communities addObject:dict];
                    }
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"communities"] = communities;
                    if (result.hasPage) {
                        NSMutableDictionary *page = [NSMutableDictionary dictionary];
                        page[@"page"] = @(result.page.page);
                        page[@"size"] = @(result.page.size);
                        page[@"total_count"] = @(result.page.totalCount);
                        page[@"total_pages"] = @(result.page.totalPages);
                        json[@"page"] = page;
                    }
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 获取社群列表响应解析成功: %@", dataStr);
                } else {
                    // 尝试直接作为 JSON 解析
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                }
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 加入社群回调
static void JoinCommunityCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 加入社群回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKCommunityManager *manager = [IMSDKCommunityManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKCommunityCompletion completion = manager.communityCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            NSString *message = @"成功";
            if (errorCode != 0) {
                message = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"失败";
                completion(errorCode, reqId, message);
            } else {
                // 成功时返回响应数据
                if (responseData && responseData.length > 0) {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

// ==================== 实现 ====================

@implementation IMSDKCommunityManager

+ (instancetype)sharedManager {
    static IMSDKCommunityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKCommunityManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _communityCallbacks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 社群查询

- (int)getCommunityListWithPage:(int)page
                        pageSize:(int)pageSize
                      completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 获取社群列表: page=%d, pageSize=%d", page, pageSize);
    
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    
    CmtyListQuery *req = [CmtyListQuery message];
    req.page = pg;
    
    NSData *protoData = [req data];
    
    uint64_t reqId = 0;
    int code = list_communities(
        ListCommunitiesCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

#pragma mark - 社群操作

- (int)joinCommunityWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 加入社群: cmtyId=%@", cmtyId);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyJoin *joinReq = [CmtyJoin message];
    // 如果有传入的data，尝试解析为JSON并设置相关字段
//    if (data && data.length > 0) {
//        NSError *jsonError = nil;
//        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] 
//                                                                options:0 
//                                                                  error:&jsonError];
//        if (!jsonError && jsonDict) {
//            // 可以根据需要设置CmtyJoin的字段，比如joinReason等
//            // joinReq.joinReason = jsonDict[@"joinReason"];
//        }
//    }
    
    NSData *protoData = [joinReq data];
    
    uint64_t reqId = 0;
    int code = join_community(
        JoinCommunityCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        [cmtyId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

@end

