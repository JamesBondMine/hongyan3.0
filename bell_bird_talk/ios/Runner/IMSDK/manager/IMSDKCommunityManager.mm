//
//  IMSDKCommunityManager.mm
//  Runner
//
//  IM SDK 社群管理类实现
//

#import "IMSDKCommunityManager.h"
#import "CmtyPb.pbobjc.h"
#import "CmtyCategoryPb.pbobjc.h"
#import "CmtyChannelPb.pbobjc.h"
#import "CmtyMemberPb.pbobjc.h"
#import "CmtySecurityPb.pbobjc.h"
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

/// 离开社群回调
static void LeaveCommunityCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 离开社群回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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

/// 获取社群信息回调
static void GetCommunityInfoCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 获取社群信息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                // 成功时解析 Cmty 对象
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    Cmty *result = [Cmty parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        dict[@"id"] = result.communityId ?: @"";
                        dict[@"name"] = result.communityName ?: @"";
                        dict[@"avatar"] = result.communityAvatar ?: @"";
                        dict[@"description"] = result.description_p ?: @"";
                        dict[@"owner_id"] = result.ownerId ?: @"";
                        dict[@"member_count"] = @(result.memberCount);
                        dict[@"status"] = @(result.status);
                        dict[@"need_verify"] = @(result.needVerify);
                        dict[@"allow_private_chat"] = @(result.allowPrivateChat);
                        dict[@"allow_add_friend"] = @(result.allowAddFriend);
                        dict[@"created_at"] = @(result.createdAt);
                        dict[@"updated_at"] = @(result.updatedAt);
                        dict[@"extra_info"] = result.extraInfo ?: @"";
                        dict[@"is_member"] = @(result.isMember);
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                        NSLog(@"✅ 获取社群信息响应解析成功: %@", dataStr);
                    } else {
                        // 尝试直接作为 JSON 解析
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                    }
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 获取分组列表回调
static void GetCommunityGroupsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {

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
                    NSError *parseError = nil;
                    CmtyCategoryList *result = [CmtyCategoryList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        NSMutableArray *categories = [NSMutableArray array];
                        if (result.categoriesArray) {
                            for (CmtyCategory *category in result.categoriesArray) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                dict[@"category_id"] = category.categoryId ?: @"";
                                dict[@"community_id"] = category.communityId ?: @"";
                                dict[@"category_name"] = category.categoryName ?: @"";
                                dict[@"description"] = category.description ?: @"";
                                dict[@"created_at"] = @(category.createdAt);
                                dict[@"updated_at"] = @(category.updatedAt);
                                [categories addObject:dict];
                            }
                        }
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:categories options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                    } else {
                        // 尝试直接作为 JSON 解析
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                    }
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 获取频道列表回调
static void GetChannelsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
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
                // 成功时解析 CmtyChannelList 对象
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    CmtyChannelList *result = [CmtyChannelList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        NSMutableArray *channels = [NSMutableArray array];
                        if (result.channelsArray) {
                            for (CmtyChannel *channel in result.channelsArray) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                dict[@"channel_id"] = channel.channelId ?: @"";
                                dict[@"community_id"] = channel.communityId ?: @"";
                                dict[@"category_id"] = channel.categoryId ?: @"";
                                dict[@"channel_name"] = channel.channelName ?: @"";
                                dict[@"channel_type"] = @(channel.channelType);
                                dict[@"description"] = channel.description_p ?: @"";
                                dict[@"member_count"] = @(channel.memberCount);
                                dict[@"max_members"] = @(channel.maxMembers);
                                dict[@"pause_invite"] = @(channel.pauseInvite);
                                dict[@"mute_all"] = @(channel.muteAll);
                                dict[@"notification_type"] = @(channel.notificationType);
                                dict[@"created_at"] = @(channel.createdAt);
                                dict[@"updated_at"] = @(channel.updatedAt);
                                [channels addObject:dict];
                            }
                        }
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:channels options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                    } else {
                        // 尝试直接作为 JSON 解析
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                    }
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 创建频道回调
static void CreateChannelCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 创建频道回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 创建频道响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 更新频道回调
static void UpdateChannelCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 更新频道回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 更新频道响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 删除频道回调
static void DeleteChannelCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 删除频道回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 删除频道响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 进入频道回调
static void EnterChannelCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 进入频道回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 进入频道响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 创建频道分组回调
static void CreateChannelGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 创建频道分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 创建频道分组响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 更新频道分组回调
static void UpdateChannelGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 更新频道分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 更新频道分组响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 删除频道分组回调
static void DeleteChannelGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 删除频道分组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    NSLog(@"✅ 删除频道分组响应: %@", dataStr);
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 获取社群成员列表回调
static void GetCommunityMembersCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"👥 获取社群成员列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                // 成功时解析 CmtyMemberList 对象
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    CmtyMemberList *result = [CmtyMemberList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        NSMutableArray *members = [NSMutableArray array];
                        if (result.membersArray) {
                            for (CmtyMember *member in result.membersArray) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                dict[@"user_id"] = member.userId ?: @"";
                                dict[@"nickname"] = member.nickname ?: @"";
                                dict[@"username"] = member.username ?: @"";
                                dict[@"avatar"] = member.avatar ?: @"";
                                dict[@"role"] = @(member.role);
                                dict[@"joined_at"] = @(member.joinedAt);
                                dict[@"join_way"] = member.joinWay ?: @"";
                                dict[@"invite_count"] = @(member.inviteCount);
                                [members addObject:dict];
                            }
                        }
                        
                        NSMutableDictionary *json = [NSMutableDictionary dictionary];
                        json[@"members"] = members;
                        json[@"total"] = @(result.total);
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                        NSLog(@"✅ 获取社群成员列表响应解析成功: 成员数=%lu, 总数=%d", (unsigned long)members.count, result.total);
                    } else {
                        // 尝试直接作为 JSON 解析
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                    }
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 获取社群封禁成员列表回调
static void GetCommunityBannedMembersCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🚫 获取社群封禁成员列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                // 成功时解析 CmtyMemberList 对象（封禁成员列表使用相同的数据结构）
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    CmtyMemberList *result = [CmtyMemberList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        NSMutableArray *bannedMembers = [NSMutableArray array];
                        if (result.membersArray) {
                            for (CmtyMember *member in result.membersArray) {
                                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                dict[@"user_id"] = member.userId ?: @"";
                                dict[@"nickname"] = member.nickname ?: @"";
                                dict[@"username"] = member.username ?: @"";
                                dict[@"avatar"] = member.avatar ?: @"";
                                dict[@"role"] = @(member.role);
                                dict[@"joined_at"] = @(member.joinedAt);
                                dict[@"join_way"] = member.joinWay ?: @"";
                                dict[@"invite_count"] = @(member.inviteCount);
                                // 封禁成员可能有额外的封禁信息
                                dict[@"banned_at"] = @(member.joinedAt); // 这里可能需要根据实际数据结构调整
                                [bannedMembers addObject:dict];
                            }
                        }
                        
                        NSMutableDictionary *json = [NSMutableDictionary dictionary];
                        json[@"members"] = bannedMembers;
                        json[@"total"] = @(result.total);
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                        NSLog(@"✅ 获取社群封禁成员列表响应解析成功: 封禁成员数=%lu, 总数=%d", (unsigned long)bannedMembers.count, result.total);
                    } else {
                        // 尝试直接作为 JSON 解析
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                    }
                }
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 禁言社群成员回调
static void MuteCommunityMemberCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🔇 禁言社群成员回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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

/// 踢出社群成员回调
static void KickCommunityMemberCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"👢 踢出社群成员回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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

#pragma mark - 社群查询

- (int)getCommunityInfoWithCmtyId:(NSString *)cmtyId
                        completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 获取社群信息: cmtyId=%@", cmtyId);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    // 获取社群信息不需要额外参数，data 传空
    Cmty *joinReq = [Cmty message];
    NSData *protoData = [joinReq data];
    
    uint64_t reqId = 0;
    int code = get_community_info(
        GetCommunityInfoCallback,
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

#pragma mark - 社群操作

- (int)joinCommunityWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 加入社群: cmtyId=%@", cmtyId);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyJoin *joinReq = [CmtyJoin message];
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


// 离开社群。
- (int)leaveCommunityWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 加入社群: cmtyId=%@", cmtyId);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyJoin *joinReq = [CmtyJoin message];
    NSData *protoData = [joinReq data];
    
    uint64_t reqId = 0;
    int code = leave_community(
                               LeaveCommunityCallback,
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

#pragma mark - 分组和频道

- (int)getCommunityGroupsWithCmtyId:(NSString *)cmtyId
                          completion:(IMSDKCommunityCompletion)completion {
    CmtyCategoryList *cl = [CmtyCategoryList message];
    
    // 创建空的查询参数（如果需要的话）
    NSData *protoData = [cl data];
    
    uint64_t reqId = 0;
    int code = list_community_groups(
        GetCommunityGroupsCallback,
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

- (int)getChannelsWithCmtyId:(NSString *)cmtyId
                  completion:(IMSDKCommunityCompletion)completion {
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    CmtyChannelsQuery *cl = [CmtyChannelsQuery message];
    
    // 创建空的查询参数（如果需要的话）
    NSData *protoData = [cl data];
    
    uint64_t reqId = 0;
    int code = get_channels(
        GetChannelsCallback,
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

- (int)createChannelWithCmtyId:(NSString *)cmtyId
                      categoryId:(NSString *)categoryId
                      channelName:(NSString *)channelName
                      channelType:(int)channelType
                      description:(NSString *)description
                      maxMembers:(int32_t)maxMembers
                      completion:(IMSDKCommunityCompletion)completion {
  
    
    CmtyCreateChannel *createReq = [CmtyCreateChannel message];
    createReq.communityId = cmtyId;
    if (categoryId != nil && categoryId != @"") {
        createReq.categoryId = categoryId;
    }
    createReq.channelName = channelName;
    createReq.channelType = (CmtyChannelType)channelType;
    if (description && description.length > 0) {
        createReq.description_p = description;
    }
    if (maxMembers > 0) {
        createReq.maxMembers = maxMembers;
    }
    
    NSLog(@"📁 创建频道: cmtyId=%@, categoryId=%@, channelName=%@, channelType=%d", createReq.communityId, createReq.categoryId, createReq.channelName, createReq.channelType);
    
    NSData *protoData = [createReq data];
    
    uint64_t reqId = 0;
    int code = create_channel(
        CreateChannelCallback,
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

- (int)updateChannelWithChannelId:(NSString *)channelId
                      channelName:(NSString *)channelName
                      pauseInvite:(BOOL)pauseInvite
                      muteAll:(BOOL)muteAll
                      notificationType:(int32_t)notificationType
                      completion:(IMSDKCommunityCompletion)completion {
    
    if (!channelId || channelId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyUpdateChannel *updateReq = [CmtyUpdateChannel message];
    updateReq.channelId = channelId;
    if (channelName && channelName.length > 0) {
        updateReq.channelName = channelName;
    }
    updateReq.pauseInvite = pauseInvite;
    updateReq.muteAll = muteAll;
    if (notificationType >= 0) {
        SetCmtyUpdateChannel_NotificationType_RawValue(updateReq, notificationType);
    }
    
    NSLog(@"📁 更新频道: channelId=%@, channelName=%@, pauseInvite=%d, muteAll=%d", channelId, channelName, pauseInvite, muteAll);
    
    NSData *protoData = [updateReq data];
    
    uint64_t reqId = 0;
    int code = update_channel(
        UpdateChannelCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        [channelId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

- (int)deleteChannelWithChannelId:(NSString *)channelId
                      completion:(IMSDKCommunityCompletion)completion {
    
    if (!channelId || channelId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyDeleteChannel *deleteReq = [CmtyDeleteChannel message];
    deleteReq.channelId = channelId;
    
    NSLog(@"📁 删除频道: channelId=%@", channelId);
    
    NSData *protoData = [deleteReq data];
    
    uint64_t reqId = 0;
    int code = delete_channel(
        DeleteChannelCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        [channelId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

- (int)enterChannelWithChannelId:(NSString *)channelId
                      completion:(IMSDKCommunityCompletion)completion {
    
    if (!channelId || channelId.length == 0) {
        return -1; // 参数错误
    }
    
    // 进入频道可能不需要额外的参数，只需要 channelId
    // 创建一个空的 message 或者使用 CmtyDeleteChannel（因为它们结构相同，只需要 channelId）
    CmtyDeleteChannel *enterReq = [CmtyDeleteChannel message];
    enterReq.channelId = channelId;
    
    NSLog(@"📁 进入频道: channelId=%@", channelId);
    
    NSData *protoData = [enterReq data];
    
    uint64_t reqId = 0;
    int code = enter_channel(
        EnterChannelCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
        [channelId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

#pragma mark - 频道分组管理

- (int)createChannelGroupWithCmtyId:(NSString *)cmtyId
                        categoryName:(NSString *)categoryName
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 创建频道分组: cmtyId=%@, categoryName=%@", cmtyId, categoryName);
    
    if (!cmtyId || cmtyId.length == 0 || !categoryName || categoryName.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyCreateCategory *createReq = [CmtyCreateCategory message];
    createReq.communityId = cmtyId;
    createReq.categoryName = categoryName;
    
    NSData *protoData = [createReq data];
    
    uint64_t reqId = 0;
    int code = create_channel_group(
        CreateChannelGroupCallback,
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

- (int)updateChannelGroupWithCmtyId:(NSString *)cmtyId
                          categoryId:(NSString *)categoryId
                        categoryName:(NSString *)categoryName
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 更新频道分组: cmtyId=%@, categoryId=%@, categoryName=%@", cmtyId, categoryId, categoryName);
    
    if (!cmtyId || cmtyId.length == 0 || !categoryId || categoryId.length == 0 || !categoryName || categoryName.length == 0) {
        return -1; // 参数错误
    }
    CmtyUpdateCategory *updateReq = [CmtyUpdateCategory message];
    updateReq.categoryId = categoryId;
    updateReq.categoryName = categoryName;
    
    NSData *protoData = [updateReq data];
    
    uint64_t reqId = 0;
    int code = update_channel_group(
        UpdateChannelGroupCallback,
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

- (int)deleteChannelGroupWithCmtyId:(NSString *)cmtyId
                          categoryId:(NSString *)categoryId
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📁 删除频道分组: cmtyId=%@, categoryId=%@", cmtyId, categoryId);
    
    if (!cmtyId || cmtyId.length == 0 || !categoryId || categoryId.length == 0) {
        return -1; // 参数错误
    }
    
    CmtyDeleteCategory *deleteReq = [CmtyDeleteCategory message];
    deleteReq.categoryId = categoryId;
    
    NSData *protoData = [deleteReq data];
    
    uint64_t reqId = 0;
    int code = delete_channel_group(
        DeleteChannelGroupCallback,
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

#pragma mark - 成员管理

- (int)getCommunityMembersWithCmtyId:(NSString *)cmtyId
                                  page:(int)page
                              pageSize:(int)pageSize
                            completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"👥 获取社群成员列表: cmtyId=%@, page=%d, pageSize=%d", cmtyId, page, pageSize);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    // 创建查询参数 CmtyMembersQuery
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    
    CmtyMembersQuery *query = [CmtyMembersQuery message];
    query.page = pg;
    
    NSData *protoData = [query data];
    
    uint64_t reqId = 0;
    int code = get_community_members(
        GetCommunityMembersCallback,
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

- (int)getCommunityBannedMembersWithCmtyId:(NSString *)cmtyId
                                      page:(int)page
                                  pageSize:(int)pageSize
                                completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"🚫 获取社群封禁成员列表: cmtyId=%@, page=%d, pageSize=%d", cmtyId, page, pageSize);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    // 创建查询参数 CmtyMembersQuery
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    
    CmtyMembersQuery *query = [CmtyMembersQuery message];
    query.page = pg;
    
    NSData *protoData = [query data];
    
    uint64_t reqId = 0;
    int code = get_community_banned_members(
        GetCommunityBannedMembersCallback,
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

#pragma mark - 成员管理（续）

- (int)muteCommunityMemberWithCmtyId:(NSString *)cmtyId
                               userId:(NSString *)userId
                                 mute:(BOOL)mute
                            muteUntil:(int64_t)muteUntil
                           completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"🔇 禁言社群成员: cmtyId=%@, userId=%@, mute=%d, muteUntil=%lld", cmtyId, userId, mute, muteUntil);
    
    if (!cmtyId || cmtyId.length == 0 || !userId || userId.length == 0) {
        return -1; // 参数错误
    }
    
    // 创建禁言参数 CmtyMuteMember
    CmtyMuteMember *muteReq = [CmtyMuteMember message];
    muteReq.userId = userId;
    muteReq.mute = mute;
    if (muteUntil > 0) {
        muteReq.muteUntil = muteUntil;
    }
    
    NSData *protoData = [muteReq data];
    
    uint64_t reqId = 0;
    int code = mute_community_member(
        MuteCommunityMemberCallback,
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

- (int)kickCommunityMemberWithCmtyId:(NSString *)cmtyId
                               userId:(NSString *)userId
                           completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"👢 踢出社群成员: cmtyId=%@, userId=%@", cmtyId, userId);
    
    if (!cmtyId || cmtyId.length == 0 || !userId || userId.length == 0) {
        return -1; // 参数错误
    }
    
    // 创建踢出参数 Param (param=user_id)
    Param *kickReq = [Param message];
    kickReq.param = userId;
    
    NSData *protoData = [kickReq data];
    
    uint64_t reqId = 0;
    int code = kick_community_member(
        KickCommunityMemberCallback,
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

