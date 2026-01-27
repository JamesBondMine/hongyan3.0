//
//  IMSDKCommunityManager.mm
//  Runner
//
//  IM SDK 社群管理类实现
//

#import "IMSDKCommunityManager.h"
#import "CmtyPb.pbobjc.h"
#import "CmtySettingsPb.pbobjc.h"
#import "CmtyCategoryPb.pbobjc.h"
#import "CmtyChannelPb.pbobjc.h"
#import "CmtyChannelGroupPb.pbobjc.h"
#import "CmtyMemberPb.pbobjc.h"
#import "CmtySecurityPb.pbobjc.h"

#import "CmtyPermissionPb.pbobjc.h"

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
//                        dict[@"need_verify"] = @(cmty.needVerify);
//                        dict[@"allow_private_chat"] = @(cmty.allowPrivateChat);
//                        dict[@"allow_add_friend"] = @(cmty.allowAddFriend);
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
//                        dict[@"need_verify"] = @(result.needVerify);
//                        dict[@"allow_private_chat"] = @(result.allowPrivateChat);
//                        dict[@"allow_add_friend"] = @(result.allowAddFriend);
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
                                dict[@"category_id"] = (channel.hasChannelGroup && channel.channelGroup.groupId) ? channel.channelGroup.groupId : @"";
                                dict[@"channel_name"] = channel.channelName ?: @"";
                                dict[@"channel_type"] = @(channel.channelType);
                                dict[@"description"] = channel.description_p ?: @"";
//                                dict[@"member_count"] = @(channel.memberCount);
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
//                                dict[@"role"] = @(member.role);
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
//                                dict[@"role"] = @(member.role);
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

/// 获取社群设置回调
static void GetCommunitySettingsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"⚙️ 获取社群设置回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                    CmtySettingsList *result = [CmtySettingsList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        // 构建 JSON 字典
                        NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                        jsonDict[@"cmty_id"] = result.cmtyId ?: @"";
                        // 转换设置数组
                        NSMutableArray *settingsArray = [NSMutableArray array];
                        for (CmtySetting *setting in result.settingsArray) {
                            NSMutableDictionary *settingDict = [NSMutableDictionary dictionary];
                            settingDict[@"setting_key"] = setting.settingKey ?: @"";
                            settingDict[@"setting_value"] = setting.settingValue ?: @"";
                            [settingsArray addObject:settingDict];
                        }
                        jsonDict[@"settings"] = settingsArray;
                        
                        // 序列化为 JSON 字符串
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                        NSLog(@"✅ 获取社群设置响应解析成功: %@", dataStr);
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

/// 获取角色列表和权限模板回调
static void GetRolesAndTemplateCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"🎭 获取角色列表和权限模板回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                message = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"获取角色权限失败";
                completion(errorCode, reqId, message);
            } else {
                // 成功时解析响应数据
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    CmtyMemberRolePermissions *result = [CmtyMemberRolePermissions parseFromData:responseData error:&parseError];
                    
                    if (result && !parseError) {
                        NSLog(@"✅ 角色权限解析成功，权限配置存在: %@", result.rolePermissions ? @"是" : @"否");
                        
                        // 只返回权限数组
                        NSMutableArray *permissionsArray = [NSMutableArray array];
                        
                        if (result.rolePermissions && result.rolePermissions.permissionsArray) {
                            for (PermissionItem *permission in result.rolePermissions.permissionsArray) {
                                NSMutableDictionary *permissionDict = [NSMutableDictionary dictionary];
                                
                                NSLog(@"🍊🍊🍊🍊🍊🍊🍊🍊权限配置: %@", permission.permissionKey);
                                
                                // 权限键
                                if (permission.permissionKey && permission.permissionKey.length > 0) {
                                    permissionDict[@"permission_key"] = permission.permissionKey;
                                }
                                
                                // 权限名称
                                if (permission.permissionName && permission.permissionName.length > 0) {
                                    permissionDict[@"permission_name"] = permission.permissionName;
                                }
                                
                                // 权限描述
                                if (permission.description_p && permission.description_p.length > 0) {
                                    permissionDict[@"description"] = permission.description_p;
                                }
                                
                                // 默认启用状态
                                permissionDict[@"default_enabled"] = @(permission.defaultEnabled);
                                
                                // 消息类型 - 特殊处理 send_message_types
                                if (permission.messageTypes && permission.messageTypes.length > 0) {
                                    NSString *messageTypes = permission.messageTypes;
                                    
                                    // 如果是 send_message_types 权限，需要转换格式
                                    if ([permission.permissionKey isEqualToString:@"send_message_types"]) {
                                        // 将 "cmty.permission.send_message_types.default_types" 转换为 "text,image"
                                        if ([messageTypes containsString:@"default_types"]) {
                                            messageTypes = @"text,image,audio,video,file";
                                        } else if ([messageTypes containsString:@"text_only"]) {
                                            messageTypes = @"text";
                                        } else if ([messageTypes containsString:@"media_only"]) {
                                            messageTypes = @"image,audio,video,file";
                                        } else {
                                            // 如果包含具体的类型标识，进行映射
                                            NSMutableArray *types = [NSMutableArray array];
                                            if ([messageTypes containsString:@"text"]) [types addObject:@"text"];
                                            if ([messageTypes containsString:@"image"]) [types addObject:@"image"];
                                            if ([messageTypes containsString:@"audio"]) [types addObject:@"audio"];
                                            if ([messageTypes containsString:@"video"]) [types addObject:@"video"];
                                            if ([messageTypes containsString:@"file"]) [types addObject:@"file"];
                                            if ([messageTypes containsString:@"emoji"]) [types addObject:@"emoji"];
                                            
                                            if (types.count > 0) {
                                                messageTypes = [types componentsJoinedByString:@","];
                                            }
                                        }
                                    }
                                    
                                    permissionDict[@"message_types"] = messageTypes;
                                }
                                
                                NSLog(@"🔑 权限项: %@ - %@ (默认: %@)", 
                                      permission.permissionKey ?: @"未知", 
                                      permission.permissionName ?: @"未命名",
                                      permission.defaultEnabled ? @"启用" : @"禁用");
                                
                                [permissionsArray addObject:permissionDict];
                            }
                        }
                        
                        // 序列化为 JSON 字符串
                        NSError *jsonError = nil;
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:permissionsArray 
                                                                           options:0 
                                                                             error:&jsonError];
                        if (jsonData && !jsonError) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                            NSLog(@"✅ 获取角色列表和权限模板响应解析成功，权限数量: %lu", (unsigned long)permissionsArray.count);
                        } else {
                            NSLog(@"❌ JSON序列化失败: %@", jsonError.localizedDescription);
                            dataStr = @"[]";
                        }
                    } else {
                        // Protobuf 解析失败，尝试直接作为 JSON 返回
                        dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSLog(@"⚠️ Protobuf解析失败，错误: %@，尝试返回原始JSON: %@", 
                              parseError ? parseError.localizedDescription : @"未知错误", dataStr);
                    }
                } else {
                    NSLog(@"⚠️ 响应数据为空");
                    dataStr = @"[]";
                }
                
                completion(errorCode, reqId, dataStr);
            }
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 查询加入申请列表回调
static void ListJoinRequestsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📋 查询加入申请列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
                // 成功时解析 CmtyJoinRecordList 对象
                if (responseData && responseData.length > 0) {
                    NSError *parseError = nil;
                    CmtyJoinRecordList *result = [CmtyJoinRecordList parseFromData:responseData error:&parseError];
                    if (result && !parseError) {
                        // 构建 JSON 字典
                        NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                        jsonDict[@"total"] = @(result.total);
                        
                        // 转换申请记录数组
                        NSMutableArray *recordsArray = [NSMutableArray array];
                        for (CmtyJoinRecord *record in result.recordsArray) {
                            NSMutableDictionary *recordDict = [NSMutableDictionary dictionary];
                            recordDict[@"request_id"] = @(record.requestId);
                            recordDict[@"cmty_id"] = record.cmtyId ?: @"";
                            recordDict[@"user_id"] = record.userId ?: @"";
                            recordDict[@"nickname"] = record.nickname ?: @"";
                            recordDict[@"username"] = record.username ?: @"";
                            recordDict[@"avatar"] = record.avatar ?: @"";
                            recordDict[@"request_message"] = record.requestMessage ?: @"";
                            recordDict[@"request_time"] = @(record.requestTime);
                            recordDict[@"expire_time"] = @(record.expireTime);
                            recordDict[@"status"] = @(record.status);
                            recordDict[@"review_user_id"] = record.reviewUserId ?: @"";
                            recordDict[@"review_time"] = @(record.reviewTime);
                            recordDict[@"review_message"] = record.reviewMessage ?: @"";
                            recordDict[@"invite_code"] = record.inviteCode ?: @"";
                            recordDict[@"invite_link"] = record.inviteLink ?: @"";
                            [recordsArray addObject:recordDict];
                        }
                        jsonDict[@"records"] = recordsArray;
                        
                        // 序列化为 JSON 字符串
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                        if (jsonData) {
                            dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        }
                        NSLog(@"✅ 查询加入申请列表响应解析成功: total=%d", result.total);
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

/// 批准加入申请回调
static void ApproveJoinRequestCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"✅ 批准加入申请回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
            } else {
                if (responseData && responseData.length > 0) {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            }
            completion(errorCode, reqId, dataStr ?: message);
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 拒绝加入申请回调
static void RejectJoinRequestCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"❌ 拒绝加入申请回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
            } else {
                if (responseData && responseData.length > 0) {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            }
            completion(errorCode, reqId, dataStr ?: message);
            [manager.communityCallbacks removeObjectForKey:key];
        }
    });
}

/// 更新社群设置回调
static void UpdateCommunitySettingsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"⚙️ 更新社群设置回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
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
        createReq.groupId = categoryId;
    }
    createReq.channelName = channelName;
    createReq.channelType = (CmtyChannelType)channelType;
    if (description && description.length > 0) {
        createReq.description_p = description;
    }
    if (maxMembers > 0) {
        createReq.maxMembers = maxMembers;
    }
    
    NSLog(@"📁 创建频道: cmtyId=%@, groupId=%@, channelName=%@, channelType=%d", createReq.communityId, createReq.groupId, createReq.channelName, createReq.channelType);
    
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

- (int)getCommunitySettingsWithCmtyId:(NSString *)cmtyId
                            completion:(IMSDKCommunityCompletion)completion {
 
    uint64_t reqId = 0;
    int code = get_community_settings(
        GetCommunitySettingsCallback,
        [cmtyId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

- (int)getRolesAndTemplateWithCmtyId:(NSString *)cmtyId
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"🎭 获取角色列表和权限模板: cmtyId=%@", cmtyId);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    uint64_t reqId = 0;
    int code = get_member_role_permissions(
        GetRolesAndTemplateCallback,
        [cmtyId UTF8String],
        reqId
    );
    
    if (code == 0 && completion) {
        self.communityCallbacks[@(reqId)] = completion;
    }
    return code;
}

- (int)updateCommunitySettingsWithCmtyId:(NSString *)cmtyId
                                 settings:(NSDictionary *)settings
                               completion:(IMSDKCommunityCompletion)completion {
    
    // 创建更新参数 CmtyUpdateSettings
    CmtyUpdateSettings *updateReq = [CmtyUpdateSettings message];
    
    // 将字典转换为 CmtySetting 数组
    for (NSString *key in settings) {
        id value = settings[key];
        CmtySetting *setting = [CmtySetting message];
        setting.settingKey = key;
        
        // 根据值的类型设置 settingValue
        if ([value isKindOfClass:[NSString class]]) {
            setting.settingValue = (NSString *)value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            setting.settingValue = [value boolValue] ? @"true" : @"false";
        } else if ([value isKindOfClass:[NSArray class]]) {
            // 数组类型，转换为 JSON 字符串
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
            if (jsonData && !error) {
                setting.settingValue = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            } else {
                setting.settingValue = @"[]";
            }
        } else {
            setting.settingValue = [value description];
        }
        
        [updateReq.settingsArray addObject:setting];
    }
    
    NSLog(@"⚙️ 更新社群设置1: cmtyId=%@, 数据: %@", cmtyId, updateReq.settingsArray);
    
    NSData *protoData = [updateReq data];
    
    uint64_t reqId = 0;
    int code = update_community_settings(
        UpdateCommunitySettingsCallback,
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

- (int)listJoinRequestsWithCmtyId:(NSString *)cmtyId
                            status:(int32_t)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"📋 查询加入申请列表: cmtyId=%@, status=%d, page=%d, pageSize=%d", cmtyId, status, page, pageSize);
    
    if (!cmtyId || cmtyId.length == 0) {
        return -1; // 参数错误
    }
    
    // 创建查询参数 CmtyJoinsQuery
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    
    CmtyJoinsQuery *query = [CmtyJoinsQuery message];
    query.page = pg;
    if (status > 0) {
        // 使用 Protobuf 生成的函数设置枚举的原始值
        SetCmtyJoinsQuery_Status_RawValue(query, status);
    }
    
    NSData *protoData = [query data];
    
    uint64_t reqId = 0;
    int code = list_join_requests(
        ListJoinRequestsCallback,
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

- (int)approveJoinRequestWithCmtyId:(NSString *)cmtyId
                           requestId:(int64_t)requestId
                      reviewMessage:(NSString *)reviewMessage
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"✅ 批准加入申请: cmtyId=%@, requestId=%lld, reviewMessage=%@", cmtyId, requestId, reviewMessage);
    
    if (!cmtyId || cmtyId.length == 0 || requestId <= 0) {
        return -1; // 参数错误
    }
    
    // 创建审核参数 CmtyReviewJoin
    CmtyReviewJoin *review = [CmtyReviewJoin message];
    review.requestId = requestId;
    if (reviewMessage && reviewMessage.length > 0) {
        review.reviewMessage = reviewMessage;
    }
    
    NSData *protoData = [review data];
    
    uint64_t reqId = 0;
    int code = approve_join_request(
        ApproveJoinRequestCallback,
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

- (int)rejectJoinRequestWithCmtyId:(NSString *)cmtyId
                           requestId:(int64_t)requestId
                      reviewMessage:(NSString *)reviewMessage
                          completion:(IMSDKCommunityCompletion)completion {
    NSLog(@"❌ 拒绝加入申请: cmtyId=%@, requestId=%lld, reviewMessage=%@", cmtyId, requestId, reviewMessage);
    
    if (!cmtyId || cmtyId.length == 0 || requestId <= 0) {
        return -1; // 参数错误
    }
    
    // 创建审核参数 CmtyReviewJoin
    CmtyReviewJoin *review = [CmtyReviewJoin message];
    review.requestId = requestId;
    if (reviewMessage && reviewMessage.length > 0) {
        review.reviewMessage = reviewMessage;
    }
    
    NSData *protoData = [review data];
    
    uint64_t reqId = 0;
    int code = reject_join_request(
        RejectJoinRequestCallback,
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

