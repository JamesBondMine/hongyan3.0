//
//  IMSDKGroupManager.mm
//  Runner
//
//  IM SDK 群组管理类实现
//

#import "IMSDKGroupManager.h"
#import "GroupPb.pbobjc.h"
#import "SystemPb.pbobjc.h"
#import <UIKit/UIKit.h>
#include "network_lib.h"
#include "callback_types.h"

@interface IMSDKGroupManager ()

/// 回调存储（用于异步回调）
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, IMSDKGroupCompletion> *groupCallbacks;

@end

// ==================== C++ 回调函数 ====================

/// 创建群组回调
static void CreateGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 创建群组回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析为 Group Protobuf
                NSError *parseError = nil;
                Group *group = [Group parseFromData:responseData error:&parseError];
                
                if (group && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                    jsonDict[@"group_id"] = group.groupId ?: @"";
                    jsonDict[@"group_name"] = group.groupName ?: @"";
                    jsonDict[@"group_avatar"] = group.groupAvatar ?: @"";
                    jsonDict[@"avatar_bg"] = group.avatarBg ?: @"";
                    jsonDict[@"group_description"] = group.groupDescription ?: @"";
//                    jsonDict[@"group_type"] = @(group.groupType);
                    jsonDict[@"max_member_count"] = @(group.maxMemberCount);
                    jsonDict[@"creator_user_id"] = group.creatorUserId ?: @"";
//                    jsonDict[@"status"] = @(group.status);
                    jsonDict[@"is_member"] = @(group.isMember);
                    jsonDict[@"created_at"] = @(group.createdAt);
                    jsonDict[@"updated_at"] = @(group.updatedAt);
                    
                    if (group.hasPolicy) {
                        NSMutableDictionary *policyDict = [NSMutableDictionary dictionary];
                        policyDict[@"need_verify"] = @(group.policy.needVerify);
                        policyDict[@"allow_invite"] = @(group.policy.allowInvite);
                        policyDict[@"allow_add_friend"] = @(group.policy.allowAddFriend);
                        policyDict[@"show_member_list"] = @(group.policy.showMemberList);
                        policyDict[@"allow_private_chat"] = @(group.policy.allowPrivateChat);
                        policyDict[@"enable_audio_video_call"] = @(group.policy.enableAudioVideoCall);
                        policyDict[@"show_history_message"] = @(group.policy.showHistoryMessage);
                        policyDict[@"show_qr_code"] = @(group.policy.showQrCode);
                        policyDict[@"message_notification"] = @(group.policy.messageNotification);
                        policyDict[@"allow_search_member"] = @(group.policy.allowSearchMember);
                        policyDict[@"speak_interval_sec"] = @(group.policy.speakIntervalSec);
                        if (group.policy.disturbRolesArray_Count > 0) {
                            NSMutableArray *disturbRoles = [NSMutableArray arrayWithCapacity:group.policy.disturbRolesArray_Count];
                            for (NSUInteger i = 0; i < group.policy.disturbRolesArray_Count; i++) {
                                [disturbRoles addObject:group.policy.disturbRolesArray[i]];
                            }
                            policyDict[@"disturb_roles"] = disturbRoles;
                        }
                        policyDict[@"notify_member_threshold"] = @(group.policy.notifyMemberThreshold);
                        jsonDict[@"policy"] = policyDict;
                    }
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 创建群组响应解析成功: %@", dataStr);
                } else {
                    // 尝试直接作为 JSON 解析
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                }
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 加入群组回调
static void JoinGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 加入群组回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 获取群组成员列表回调
static void GetGroupMembersCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 获取群组成员列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0 && responseData && responseData.length > 0) {
                NSError *parseError = nil;
                members *result = [members parseFromData:responseData error:&parseError];
                if (result && !parseError) {
                    NSMutableArray *memberArr = [NSMutableArray array];
                    for (GroupMember *m in result.membersArray) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        dict[@"group_id"] = m.groupId ?: @"";
                        dict[@"user_id"] = m.userId ?: @"";
//                        dict[@"member_alias"] = m.memberAlias ?: @"";
//                        dict[@"join_type"] = @(m.joinType);   会造成闪退
//                        dict[@"join_time"] = @(m.joinTime);
//                        dict[@"inviter_user_id"] = m.inviterUserId ?: @"";
//                        dict[@"status"] = @(m.status);
//                        dict[@"disturb_until"] = @(m.disturbUntil);
                        dict[@"is_admin"] = @(m.isAdmin);
//                        dict[@"last_read_time"] = @(m.lastReadTime);
                        if (m.rolesArray_Count > 0) {
                            NSMutableArray *roles = [NSMutableArray arrayWithCapacity:m.rolesArray_Count];
                            for (NSUInteger i = 0; i < m.rolesArray_Count; i++) {
                                id roleVal = m.rolesArray[i];
                                if (roleVal) {
                                    [roles addObject:roleVal];
                                }
                            }
                            dict[@"roles"] = roles;
                        }
                        [memberArr addObject:dict];
                    }
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"members"] = memberArr;
                    if (result.hasPage) {
                        NSMutableDictionary *page = [NSMutableDictionary dictionary];
                        page[@"page"] = @(result.page.page);
                        page[@"size"] = @(result.page.size);
                        page[@"total_count"] = @(result.page.totalCount);
                        page[@"total_pages"] = @(result.page.totalPages);
                        page[@"has_previous"] = @(result.page.hasPrevious);
                        page[@"has_next"] = @(result.page.hasNext);
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
                dataStr = @"{\"members\":[]}";
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}
/// 获取群组列表回调
static void ListGroupsCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 获取群组列表回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (errorCode == 0 && responseData && responseData.length > 0) {
                NSError *parseError = nil;
                // 解析为 GList
                GList *result = [GList parseFromData:responseData error:&parseError];
                if (!result || parseError) {
                    parseError = nil;
                }
                NSMutableArray *groups = [NSMutableArray array];
                if (result) {
                    for (Group *group in result.groupsArray) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        dict[@"group_id"] = group.groupId ?: @"";
                        dict[@"group_name"] = group.groupName ?: @"";
                        dict[@"group_avatar"] = group.groupAvatar ?: @"";
                        dict[@"avatar_bg"] = group.avatarBg ?: @"";
                        dict[@"group_description"] = group.groupDescription ?: @"";
//                        dict[@"group_type"] = @(group.groupType);
                        dict[@"max_member_count"] = @(group.maxMemberCount);
                        dict[@"creator_user_id"] = group.creatorUserId ?: @"";
//                        dict[@"status"] = @(group.status);
                        dict[@"is_member"] = @(group.isMember);
                        dict[@"created_at"] = @(group.createdAt);
                        dict[@"updated_at"] = @(group.updatedAt);
                        [groups addObject:dict];
                    }
                    NSMutableDictionary *json = [NSMutableDictionary dictionary];
                    json[@"groups"] = groups;
                    if (result.hasPage) {
                        NSMutableDictionary *page = [NSMutableDictionary dictionary];
                        page[@"page"] = @(result.page.page);
                        page[@"size"] = @(result.page.size);
                        page[@"total_count"] = @(result.page.totalCount);
                        page[@"total_pages"] = @(result.page.totalPages);
                        page[@"has_previous"] = @(result.page.hasPrevious);
                        page[@"has_next"] = @(result.page.hasNext);
                        json[@"page"] = page;
                    }
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                } else if (responseData.length > 0) {
                    // 尝试直接作为字符串
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            } else if (errorCode == 0) {
                dataStr = @"{\"groups\":[]}";
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}
/// 获取群组信息回调
static void GetGroupInfoCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 获取群组信息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            
            if (errorCode == 0 && responseData && responseData.length > 0) {
                // 尝试解析为 Group Protobuf
                NSError *parseError = nil;
                Group *group = [Group parseFromData:responseData error:&parseError];
                
                if (group && !parseError) {
                    // 转换为 JSON
                    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                    jsonDict[@"group_id"] = group.groupId ?: @"";
                    jsonDict[@"group_name"] = group.groupName ?: @"";
                    jsonDict[@"group_avatar"] = group.groupAvatar ?: @"";
                    jsonDict[@"avatar_bg"] = group.avatarBg ?: @"";
                    jsonDict[@"group_announcement"] = group.groupAnnouncement ?: @"";
                    jsonDict[@"group_description"] = group.groupDescription ?: @"";
//                    jsonDict[@"group_type"] = @(group.groupType);
                    jsonDict[@"max_member_count"] = @(group.maxMemberCount);
                    jsonDict[@"creator_user_id"] = group.creatorUserId ?: @"";
//                    jsonDict[@"status"] = @(group.status);
                    jsonDict[@"is_member"] = @(group.isMember);
                    jsonDict[@"created_at"] = @(group.createdAt);
                    jsonDict[@"updated_at"] = @(group.updatedAt);
                    
                    if (group.hasPolicy) {
                        NSMutableDictionary *policyDict = [NSMutableDictionary dictionary];
                        policyDict[@"need_verify"] = @(group.policy.needVerify);
                        policyDict[@"allow_invite"] = @(group.policy.allowInvite);
                        policyDict[@"allow_add_friend"] = @(group.policy.allowAddFriend);
                        policyDict[@"show_member_list"] = @(group.policy.showMemberList);
                        policyDict[@"allow_private_chat"] = @(group.policy.allowPrivateChat);
                        policyDict[@"enable_audio_video_call"] = @(group.policy.enableAudioVideoCall);
                        policyDict[@"show_history_message"] = @(group.policy.showHistoryMessage);
                        policyDict[@"show_qr_code"] = @(group.policy.showQrCode);
                        policyDict[@"message_notification"] = @(group.policy.messageNotification);
                        policyDict[@"allow_search_member"] = @(group.policy.allowSearchMember);
                        policyDict[@"speak_interval_sec"] = @(group.policy.speakIntervalSec);
                        if (group.policy.disturbRolesArray_Count > 0) {
                            NSMutableArray *disturbRoles = [NSMutableArray arrayWithCapacity:group.policy.disturbRolesArray_Count];
                            for (NSUInteger i = 0; i < group.policy.disturbRolesArray_Count; i++) {
                                [disturbRoles addObject:group.policy.disturbRolesArray[i]];
                            }
                            policyDict[@"disturb_roles"] = disturbRoles;
                        }
                        policyDict[@"notify_member_threshold"] = @(group.policy.notifyMemberThreshold);
                        jsonDict[@"policy"] = policyDict;
                    }
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (jsonData) {
                        dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    NSLog(@"✅ 获取群组信息响应解析成功");
                } else {
                    // 尝试直接作为 JSON 解析
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"⚠️ Protobuf解析失败，尝试JSON: %@", dataStr);
                }
            }
            
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 更新群组信息回调
static void UpdateGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 更新群组信息回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSString *dataStr = nil;
    if (data && dataLen > 0) {
        NSData *resp = [NSData dataWithBytes:data length:dataLen];
        dataStr = [[NSString alloc] initWithData:resp encoding:NSUTF8StringEncoding];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        IMSDKGroupCompletion completion = manager.groupCallbacks[@(reqId)];
        if (completion) {
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:@(reqId)];
        }
    });
}

/// 设置群内昵称回调
static void SetAliasCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📁 设置群内昵称回调: errorCode=%d, dataLen=%d, reqId=%llu", errorCode, dataLen, reqId);
    NSString *dataStr = nil;
    if (data && dataLen > 0) {
        NSData *resp = [NSData dataWithBytes:data length:dataLen];
        dataStr = [[NSString alloc] initWithData:resp encoding:NSUTF8StringEncoding];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        IMSDKGroupCompletion completion = manager.groupCallbacks[@(reqId)];
        if (completion) {
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:@(reqId)];
        }
    });
}
/// 添加群组成员回调
static void AddGroupMemberCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 添加群组成员回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 移除群组成员回调
static void RemoveGroupMemberCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 移除群组成员回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 解散群组回调
static void DissolveGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 解散群组回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 退出群组回调
static void LeaveGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 退出群组回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 设置群组免打扰回调
static void DisturbGroupCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 设置群组免打扰回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            if (responseData && responseData.length > 0) {
                dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

/// 查询群组免打扰状态回调
static void GetGroupDisturbStatusCallback(int errorCode, const char* data, int dataLen, uint64_t reqId) {
    NSLog(@"📬 查询群组免打扰状态回调: errorCode=%d, reqId=%llu", errorCode, reqId);
    NSData *responseData = nil;
    if (data && dataLen > 0) {
        responseData = [NSData dataWithBytes:data length:dataLen];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMSDKGroupManager *manager = [IMSDKGroupManager sharedManager];
        NSNumber *key = @(reqId);
        IMSDKGroupCompletion completion = manager.groupCallbacks[key];
        
        if (completion) {
            NSString *dataStr = nil;
            NSError *parseError = nil;
            DisturbStatus *group = [DisturbStatus parseFromData:responseData error:&parseError];
            if (group && !parseError) {
                NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                if (jsonData) {
                    dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }
            } else {
                if (responseData && responseData.length > 0) {
                    dataStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                }
            }            completion(errorCode, reqId, dataStr);
            [manager.groupCallbacks removeObjectForKey:key];
        }
    });
}

// ==================== 实现类 ====================

@implementation IMSDKGroupManager

+ (instancetype)sharedManager {
    static IMSDKGroupManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IMSDKGroupManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _groupCallbacks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 群组创建和管理

- (int)createGroupWithName:(NSString *)groupName
                groupAvatar:(NSString * _Nullable)groupAvatar
           groupDescription:(NSString * _Nullable)groupDescription
                   groupType:(int)groupType
              maxMemberCount:(int32_t)maxMemberCount
             initialMembers:(NSArray<NSString *> * _Nullable)initialMembers
                  completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 创建群组: groupName=%@", groupName);
    
    if (!groupName || groupName.length == 0) {
        NSLog(@"❌ 群组名称不能为空");
        return -1;
    }
    
    // 创建 CreateGroup Protobuf 对象
    CreateGroup *createGroup = [[CreateGroup alloc] init];
    createGroup.groupName = groupName;
//    createGroup.groupType = GroupType_Normal;
    
    if (maxMemberCount > 0) {
        createGroup.maxMemberCount = maxMemberCount;
    }
    
    if (initialMembers && initialMembers.count > 0) {
        [createGroup.initialMembersArray addObjectsFromArray:initialMembers];
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [createGroup data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    NSLog(@"📦 Protobuf 数据长度: %lu 字节", (unsigned long)serializedData.length);
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = create_group(CreateGroupCallback, data, dataLen, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 创建群组请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 创建群组请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return create_group(CreateGroupCallback, data, dataLen, reqId);
}

- (int)joinGroupWithId:(NSString *)groupId
        requestMessage:(NSString * _Nullable)requestMessage
             completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 加入群组: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 创建 Apply Protobuf 对象
    Apply *apply = [[Apply alloc] init];
    apply.groupId = groupId;
    
    if (requestMessage && requestMessage.length > 0) {
        apply.requestMessage = requestMessage;
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [apply data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];

    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = join_group(JoinGroupCallback, data, dataLen,targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 加入群组请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 加入群组请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return join_group(JoinGroupCallback, data, dataLen,targetId, reqId);
}

- (int)getGroupInfoWithId:(NSString *)groupId
               completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取群组信息: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 创建 getGroup Protobuf 对象
    getGroup *getGroupReq = [[getGroup alloc] init];
    getGroupReq.groupId = groupId;
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [getGroupReq data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    const char *targetId = [groupId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = get_group_info(GetGroupInfoCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 获取群组信息请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 获取群组信息请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return get_group_info(GetGroupInfoCallback, data, dataLen, targetId, reqId);
}


- (int)getGroupPerviewWithId:(NSString *)groupId
               completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取群组信息: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 创建 getGroup Protobuf 对象
    getGroup *getGroupReq = [[getGroup alloc] init];
    getGroupReq.groupId = groupId;
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [getGroupReq data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    const char *targetId = [groupId UTF8String];
    uint64_t reqId = 0;
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = get_group_info(GetGroupInfoCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 获取群组信息请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 获取群组信息请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return perview_group(GetGroupInfoCallback, targetId, reqId);
}


- (int)updateGroupWithId:(NSString *)groupId
               groupName:(NSString * _Nullable)groupName
              groupAvatar:(NSString * _Nullable)groupAvatar
        groupAnnouncement:(NSString * _Nullable)groupAnnouncement
          groupDescription:(NSString * _Nullable)groupDescription
                  version:(int32_t)version
               completion:(IMSDKGroupCompletion)completion {
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    UpdateGroup *req = [UpdateGroup message];
    req.groupId = groupId;
    if (groupName && groupName.length > 0) req.groupName = groupName;
    if (groupAvatar && groupAvatar.length > 0) req.groupAvatar = groupAvatar;
    if (groupAnnouncement && groupAnnouncement.length > 0) req.groupAnnouncement = groupAnnouncement;
    if (groupDescription && groupDescription.length > 0) req.groupDescription = groupDescription;
    req.version = version > 0 ? version : 1;
    
    
    NSLog(@"\n🍎 更新群组信息: 群ID=%@、群名称=%@、群头像=%@、群描述=%@、", req.groupId, req.groupName, req.groupAvatar, req.groupDescription);
    
    NSData *protoData = [req data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ 序列化 UpdateGroup 失败");
        return -2;
    }
    
    uint64_t reqId = 0;
    if (completion) {
        static uint64_t tempId = 21000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        const char *targetId = [groupId UTF8String];
        int code = update_group(
            UpdateGroupCallback,
            (const char *)protoData.bytes,
            (int)protoData.length,
                                targetId,
            reqId
        );
        
        if (code == 0) {
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        return code;
    }
    const char *targetId = [groupId UTF8String];
    return update_group(
        UpdateGroupCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
                        targetId,
        reqId
    );
}

- (int)dissolveGroupWithId:(NSString *)groupId
                    reason:(NSString * _Nullable)reason
                completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 解散群组: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 创建 DissolveGroup Protobuf 对象
    DissolveGroup *dissolveGroup = [[DissolveGroup alloc] init];
    dissolveGroup.groupId = groupId;
    
    if (reason && reason.length > 0) {
        dissolveGroup.reason = reason;
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [dissolveGroup data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = dissolve_group(DissolveGroupCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 解散群组请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 解散群组请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return dissolve_group(DissolveGroupCallback, data, dataLen, targetId, reqId);
}

- (int)leaveGroupWithId:(NSString *)groupId
                 reason:(NSString * _Nullable)reason
             completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 退出群组: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 退出群组可能需要一个简单的 Protobuf 消息，或者传递空数据
    // 根据其他接口的模式，创建一个包含 groupId 的简单消息
    // 如果没有专门的 LeaveGroup Protobuf，可以使用 RemoveMember，但只包含当前用户
    // 或者创建一个简单的 JSON 数据
    // 先尝试传递一个包含 groupId 的简单 Protobuf 结构
    // 如果服务端需要特定格式，可能需要调整
    
    // 创建一个简单的字典并转换为 JSON，然后作为数据传递
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];
    requestDict[@"group_id"] = groupId;
    if (reason && reason.length > 0) {
        requestDict[@"reason"] = reason;
    }
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (!jsonData || jsonError) {
        NSLog(@"❌ JSON 序列化失败: %@", jsonError);
        return -1;
    }
    
    const char *data = (const char *)jsonData.bytes;
    int dataLen = (int)jsonData.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = leave_group(LeaveGroupCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 退出群组请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 退出群组请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return leave_group(LeaveGroupCallback, data, dataLen, targetId, reqId);
}

#pragma mark - 群组成员管理

- (int)addGroupMembersWithGroupId:(NSString *)groupId
                          userIds:(NSArray<NSString *> *)userIds
                            reason:(NSString * _Nullable)reason
                        completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 添加群组成员: groupId=%@, userIds=%@", groupId, userIds);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    if (!userIds || userIds.count == 0) {
        NSLog(@"❌ 用户ID列表不能为空");
        return -1;
    }
    
    // 创建 AddMember Protobuf 对象
    AddMember *addMember = [[AddMember alloc] init];
    addMember.groupId = groupId;
    [addMember.userIdsArray addObjectsFromArray:userIds];
    
    if (reason && reason.length > 0) {
        addMember.reason = reason;
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [addMember data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = add_group_member(AddGroupMemberCallback, data, dataLen, targetId,reqId);
        
        if (result == 0) {
            NSLog(@"✅ 添加群组成员请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 添加群组成员请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return add_group_member(AddGroupMemberCallback, data, dataLen, targetId,reqId);
}

- (int)removeGroupMembersWithGroupId:(NSString *)groupId
                             userIds:(NSArray<NSString *> *)userIds
                               reason:(NSString * _Nullable)reason
                           completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 移除群组成员: groupId=%@, userIds=%@", groupId, userIds);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    if (!userIds || userIds.count == 0) {
        NSLog(@"❌ 用户ID列表不能为空");
        return -1;
    }
    
    // 创建 RemoveMember Protobuf 对象
    RemoveMember *removeMember = [[RemoveMember alloc] init];
    removeMember.groupId = groupId;
    [removeMember.userIdsArray addObjectsFromArray:userIds];
    
    if (reason && reason.length > 0) {
        removeMember.reason = reason;
    }
    
    // 序列化为 Protobuf 二进制数据
    NSData *serializedData = [removeMember data];
    if (!serializedData || serializedData.length == 0) {
        NSLog(@"❌ Protobuf 序列化失败");
        return -1;
    }
    
    const char *data = (const char *)serializedData.bytes;
    int dataLen = (int)serializedData.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = remove_group_member(RemoveGroupMemberCallback, data, dataLen,targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 移除群组成员请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 移除群组成员请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return remove_group_member(RemoveGroupMemberCallback, data, dataLen,targetId, reqId);
}

- (int)getGroupMembersWithGroupId:(NSString *)groupId
                            status:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取群组成员列表: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // 目前 group_pb 未定义专门的查询对象，这里仅携带分页信息，userId 从会话中获取
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 50;
    
    membersQuery *req = [membersQuery message];
    req.page = pg;
    req.groupId = groupId;
    
    // groupId/status 目前由服务端从会话上下文和路由中解析，如需扩展可在 proto 中增加查询对象
    
    NSData *protoData = [req data];
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    int code = get_group_members(
        GetGroupMembersCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
                                 targetId,
        reqId
    );
    
    if (code == 0 && completion) {
        self.groupCallbacks[@(reqId)] = completion;
    }
    return code;
}



- (int)setGroupMemberAliasWithGroupId:(NSString *)groupId
                          memberAlias:(NSString *)memberAlias
                           completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 设置群内昵称: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    if (!memberAlias || memberAlias.length == 0) {
        NSLog(@"❌ 群昵称不能为空");
        return -1;
    }
    
    SetAlias *req = [SetAlias message];
    req.groupId = groupId;
    req.memberAlias = memberAlias;
    
    NSData *protoData = [req data];
    if (!protoData || protoData.length == 0) {
        NSLog(@"❌ 序列化 SetAlias 失败");
        return -2;
    }
    const char *targetId = [groupId UTF8String];
    uint64_t reqId = 0;
    if (completion) {
        static uint64_t tempId = 22000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int code = set_group_alias(
            SetAliasCallback,
            (const char *)protoData.bytes,
            (int)protoData.length,
                                   targetId,
            reqId
        );
        
        if (code == 0) {
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        return code;
    }
    
    return set_group_alias(
        SetAliasCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
                           targetId,
        reqId
    );
}

#pragma mark - 群组查询

- (int)getGroupListWithType:(int)groupType
                     status:(int)status
                    keyword:(NSString * _Nullable)keyword
                      page:(int)page
                  pageSize:(int)pageSize
                completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取群组列表: type=%d, status=%d, page=%d, size=%d, keyword=%@", groupType, status, page, pageSize, keyword ?: @"");
    Page *pg = [Page message];
    pg.page = page > 0 ? page : 1;
    pg.size = pageSize > 0 ? pageSize : 20;
    
    
    listQuery *req = [listQuery message];
    req.page = pg;
    if (groupType >= 0) {
        req.groupType = (GroupType)groupType;
    }
    if (status >= 0) {
        req.status = (GroupStatus)status;
    }
    if (keyword && keyword.length > 0) {
        req.keyword = keyword;
    }
    // 目前 group_pb 未提供专用查询对象，服务端按 userId 查询，额外过滤暂未支持；keyword/type/status 如有需要可扩展字段

    NSData *protoData = [req data];
    uint64_t reqId = 0;
    int code = list_groups(
        ListGroupsCallback,
        (const char *)protoData.bytes,
        (int)protoData.length,
                        
        reqId
    );
    
    if (code == 0 && completion) {
        self.groupCallbacks[@(reqId)] = completion;
    }
    return code;
}

#pragma mark - 群组申请和审批

- (int)getJoinRequestsWithGroupId:(NSString *)groupId
                            status:(int)status
                              page:(int)page
                          pageSize:(int)pageSize
                        completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取加入申请列表: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 get_join_requests 接口，暂时返回错误
    NSLog(@"⚠️ 获取加入申请列表接口暂未实现");
    if (completion) {
        completion(-1, 0, @"获取加入申请列表接口暂未实现");
    }
    return -1;
}

- (int)approveJoinRequestWithGroupId:(NSString *)groupId
                          applicantId:(NSString *)applicantId
                        reviewMessage:(NSString * _Nullable)reviewMessage
                           completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 审批加入申请: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 approve_join_request 接口，暂时返回错误
    NSLog(@"⚠️ 审批加入申请接口暂未实现");
    if (completion) {
        completion(-1, 0, @"审批加入申请接口暂未实现");
    }
    return -1;
}

- (int)rejectJoinRequestWithGroupId:(NSString *)groupId
                         applicantId:(NSString *)applicantId
                       reviewMessage:(NSString * _Nullable)reviewMessage
                          completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 拒绝加入申请: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 reject_join_request 接口，暂时返回错误
    NSLog(@"⚠️ 拒绝加入申请接口暂未实现");
    if (completion) {
        completion(-1, 0, @"拒绝加入申请接口暂未实现");
    }
    return -1;
}

#pragma mark - 群组策略和权限

- (int)getGroupPolicyWithGroupId:(NSString *)groupId
                       completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 获取群组策略: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 get_group_policy 接口，暂时返回错误
    NSLog(@"⚠️ 获取群组策略接口暂未实现");
    if (completion) {
        completion(-1, 0, @"获取群组策略接口暂未实现");
    }
    return -1;
}

- (int)setGroupPolicyWithGroupId:(NSString *)groupId
                           policy:(NSDictionary * _Nullable)policy
                       completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 设置群组策略: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 set_group_policy 接口，暂时返回错误
    NSLog(@"⚠️ 设置群组策略接口暂未实现");
    if (completion) {
        completion(-1, 0, @"设置群组策略接口暂未实现");
    }
    return -1;
}

- (int)setGroupMuteWithGroupId:(NSString *)groupId
                          mute:(BOOL)mute
                    completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 设置全员禁言: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 set_group_mute 接口，暂时返回错误
    NSLog(@"⚠️ 设置全员禁言接口暂未实现");
    if (completion) {
        completion(-1, 0, @"设置全员禁言接口暂未实现");
    }
    return -1;
}

- (int)muteGroupMemberWithGroupId:(NSString *)groupId
                            userId:(NSString *)userId
                         muteUntil:(int64_t)muteUntil
                             reason:(NSString * _Nullable)reason
                         completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 禁言成员: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 mute_group_member 接口，暂时返回错误
    NSLog(@"⚠️ 禁言成员接口暂未实现");
    if (completion) {
        completion(-1, 0, @"禁言成员接口暂未实现");
    }
    return -1;
}

- (int)getMuteStatusWithGroupId:(NSString *)groupId
                          userId:(NSString * _Nullable)userId
                      completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 查询禁言状态: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 get_mute_status 接口，暂时返回错误
    NSLog(@"⚠️ 查询禁言状态接口暂未实现");
    if (completion) {
        completion(-1, 0, @"查询禁言状态接口暂未实现");
    }
    return -1;
}

#pragma mark - 群主转让

- (int)transferGroupOwnerWithGroupId:(NSString *)groupId
                          newOwnerId:(NSString *)newOwnerId
                         keepAsAdmin:(BOOL)keepAsAdmin
                               reason:(NSString * _Nullable)reason
                           completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 转让群主: groupId=%@", groupId);
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    // TODO: network_lib.h 中没有 transfer_group_owner 接口，暂时返回错误
    NSLog(@"⚠️ 转让群主接口暂未实现");
    if (completion) {
        completion(-1, 0, @"转让群主接口暂未实现");
    }
    return -1;
}

#pragma mark - 群组免打扰

- (int)setGroupDisturbWithGroupId:(NSString *)groupId
                            disturb:(BOOL)disturb
                        completion:(IMSDKGroupCompletion)completion {
    NSLog(@"📁 设置群组免打扰: groupId=%@, disturb=%@", groupId, disturb ? @"YES" : @"NO");
    
    if (!groupId || groupId.length == 0) {
        NSLog(@"❌ 群组ID不能为空");
        return -1;
    }
    
    BParam * bp = [[BParam alloc] init];
    bp.param = groupId;
    
    
    NSData * dataNs = [bp data];
    
    const char *data = (const char *)dataNs.bytes;
    
    int dataLen = (int)dataNs.length;
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = disturb_group(DisturbGroupCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 设置群组免打扰请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 设置群组免打扰请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return disturb_group(DisturbGroupCallback, data, dataLen, targetId, reqId);
}

- (int)getGroupDisturbStatusWithGroupId:(NSString *)groupId
userId:(NSString *)userId
                             completion:(IMSDKGroupCompletion)completion {
    

    disturbStatusQuery * bp = [[disturbStatusQuery alloc] init];
    bp.groupId = groupId;
    bp.userId = userId;
    
    NSLog(@"🍎 查询群组免打扰状态: groupId=%@。 userId=%@", bp.groupId,bp.userId);
    
    NSData * dataNs = [bp data];
    const char *data = (const char *)dataNs.bytes;
    int dataLen = (int)dataNs.length;
    
    uint64_t reqId = 0;
    const char *targetId = [groupId UTF8String];
    
    if (completion) {
        static uint64_t tempId = 20000;
        NSNumber *tempKey = @(tempId++);
        self.groupCallbacks[tempKey] = completion;
        
        int result = get_group_disturb_status(GetGroupDisturbStatusCallback, data, dataLen, targetId, reqId);
        
        if (result == 0) {
            NSLog(@"✅ 查询群组免打扰状态请求发送成功: reqId=%llu", reqId);
            if (reqId != 0) {
                self.groupCallbacks[@(reqId)] = completion;
                [self.groupCallbacks removeObjectForKey:tempKey];
            }
        } else {
            NSLog(@"❌ 查询群组免打扰状态请求失败: %d", result);
            [self.groupCallbacks removeObjectForKey:tempKey];
        }
        
        return result;
    }
    
    return get_group_disturb_status(GetGroupDisturbStatusCallback, data, dataLen, targetId, reqId);
}

@end

