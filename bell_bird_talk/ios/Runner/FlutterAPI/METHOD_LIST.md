# 完整方法列表

## 📋 所有需要迁移的方法

### ✅ 已完成 - DeviceAPIHandler (15个)
- [x] getDeviceInfo
- [x] saveData
- [x] loadData
- [x] getContacts
- [x] openCamera
- [x] sendNotification
- [x] openNativePage
- [x] showAlert
- [x] processMessage
- [x] syncChatData
- [x] generateCppData
- [x] processCppString
- [x] calculateCppStatistics
- [x] simulateCppDataTransfer
- [x] mergeAudioFiles

### ✅ 已完成 - IMSDKAPIHandler (7个)
- [x] imInitialize
- [x] imStart
- [x] imStartNetCheck
- [x] imSetIPTable
- [x] imGetIPStatus
- [x] imAddTarget
- [x] imStop

### ✅ 已完成 - CommunityAPIHandler (18个)
- [x] imGetCommunityList
- [x] imJoinCommunity
- [x] imLeaveCommunity
- [x] imGetCommunityInfo
- [x] imGetCommunityGroups
- [x] imGetChannels
- [x] imCreateChannel
- [x] imUpdateChannel
- [x] imDeleteChannel
- [x] imEnterChannel
- [x] imCreateChannelGroup
- [x] imUpdateChannelGroup
- [x] imDeleteChannelGroup
- [x] imGetCommunityMembers
- [x] imGetCommunityBannedMembers
- [x] imMuteCommunityMember
- [x] imKickCommunityMember
- [x] imSendChannelMessage (需要移到 MessageAPIHandler)

### ⏳ 待完成 - AuthAPIHandler (13个)
- [ ] imRegister
- [ ] imGetCaptcha
- [ ] imLogin
- [ ] imSearchUser
- [ ] imUpdateUserInfo
- [ ] imLogout
- [ ] imDeactivateAccount
- [ ] imGetDeactivateStatus
- [ ] imCancelDeactivateAccount
- [ ] imChangePassword
- [ ] imResetPassword
- [ ] imGetUsersInfo
- [ ] imBatchGetUserPublicInfo

### ⏳ 待完成 - ContactAPIHandler (16个)
- [ ] imAddContact
- [ ] imDeleteContact
- [ ] imBlockContact
- [ ] imUnblockContact
- [ ] imGetBlackStatus
- [ ] imGetContactList
- [ ] imSearchContact
- [ ] imGetFriendRequests
- [ ] imAcceptFriendRequest
- [ ] imRejectFriendRequest
- [ ] imGetContactGroups
- [ ] imCreateContactGroup
- [ ] imUpdateContactGroup
- [ ] imDeleteContactGroup
- [ ] imSetContactRemark
- [ ] imMoveContactToGroup

### ⏳ 待完成 - ConversationAPIHandler (11个)
- [ ] imGetConversationList
- [ ] imGetConversation
- [ ] imGetUnreadConversations
- [ ] imUpdateConversation
- [ ] imCreateConversation
- [ ] imDeleteConversation
- [ ] imMarkConversationRead
- [ ] imClearConversationMessages
- [ ] imGetNotificationUnreadCount
- [ ] imPullNotifications
- [ ] imMarkNotificationRead

### ⏳ 待完成 - MessageAPIHandler (15个)
- [ ] imDeleteMessage
- [ ] imSendTextMessage
- [ ] imSendImageMessage
- [ ] imSendVideoMessage
- [ ] imSendVoiceMessage
- [ ] imSendChannelMessage (从 CommunityAPIHandler 移过来)
- [ ] imSendGroupTextMessage
- [ ] imSendGroupImageMessage
- [ ] imSendGroupVoiceMessage
- [ ] imSendGroupVideoMessage
- [ ] imSendGroupAtMessage
- [ ] imPullMessages
- [ ] imPullGroupMessages
- [ ] imRegisterMessageCallbacks
- [ ] imUnregisterMessageCallbacks

### ⏳ 待完成 - GroupAPIHandler (13个)
- [ ] imCreateGroup
- [ ] imGetGroupList
- [ ] imGetGroupMembers
- [ ] imGetGroupInfo
- [ ] imGetGroupPreview
- [ ] imUpdateGroup
- [ ] imSetGroupAlias
- [ ] imDissolveGroup
- [ ] imLeaveGroup
- [ ] imSetGroupDisturb
- [ ] imGetGroupDisturbStatus
- [ ] imAddGroupMembers
- [ ] imRemoveGroupMembers

### ⏳ 待完成 - StorageAPIHandler (5个)
- [ ] imPrepareUpload
- [ ] imUploadWithTencentSTS
- [ ] initAliyunOSS / uploadToAliyun
- [ ] initTencentCOS / uploadToTencent
- [ ] initAWSS3 / uploadToAWS / downloadFile

## 📊 统计

| Handler | 已完成 | 待完成 | 总计 | 完成度 |
|---------|--------|--------|------|--------|
| DeviceAPIHandler | 15 | 0 | 15 | 100% |
| IMSDKAPIHandler | 7 | 0 | 7 | 100% |
| CommunityAPIHandler | 18 | 0 | 18 | 100% |
| AuthAPIHandler | 0 | 13 | 13 | 0% |
| ContactAPIHandler | 0 | 16 | 16 | 0% |
| ConversationAPIHandler | 0 | 11 | 11 | 0% |
| MessageAPIHandler | 0 | 15 | 15 | 0% |
| GroupAPIHandler | 0 | 13 | 13 | 0% |
| StorageAPIHandler | 0 | 5 | 5 | 0% |
| **总计** | **40** | **73** | **113** | **35%** |

## 🎯 优先级

### 高优先级（核心功能）
1. **AuthAPIHandler** - 认证是基础
2. **MessageAPIHandler** - 消息是核心功能
3. **ConversationAPIHandler** - 会话管理

### 中优先级（常用功能）
4. **ContactAPIHandler** - 联系人管理
5. **GroupAPIHandler** - 群组功能

### 低优先级（辅助功能）
6. **StorageAPIHandler** - 文件上传

## 📝 注意事项

1. **imSendChannelMessage** 应该从 CommunityAPIHandler 移到 MessageAPIHandler
2. 所有方法都需要从旧的 AppDelegate_old.swift 中复制实现
3. 需要保持方法签名和逻辑完全一致
4. 每个 Handler 完成后需要测试
