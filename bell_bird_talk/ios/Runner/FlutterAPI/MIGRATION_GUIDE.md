# AppDelegate 重构迁移指南

## 📋 概述

本指南说明如何将 AppDelegate.swift 中的臃肿代码迁移到新的模块化架构。

## 🎯 目标

- 将 4000+ 行的 AppDelegate.swift 拆分为多个小文件
- 提高代码可维护性和可读性
- 保持功能完全兼容

## ✅ 已完成的工作

### 1. 架构设计
- ✅ 创建 FlutterAPIHandler 主路由
- ✅ 设计 Handler 模块划分
- ✅ 定义调用流程

### 2. 已实现的 Handler
- ✅ **DeviceAPIHandler**: 设备相关功能（完整实现）
- ✅ **IMSDKAPIHandler**: IM SDK 基础功能（完整实现）
- ✅ **CommunityAPIHandler**: 社群管理功能（完整实现）

### 3. 待迁移的 Handler
- ⏳ **AuthAPIHandler**: 认证相关（占位文件已创建）
- ⏳ **ContactAPIHandler**: 联系人管理（占位文件已创建）
- ⏳ **ConversationAPIHandler**: 会话管理（占位文件已创建）
- ⏳ **MessageAPIHandler**: 消息管理（占位文件已创建）
- ⏳ **GroupAPIHandler**: 群组管理（占位文件已创建）
- ⏳ **StorageAPIHandler**: 云存储（部分实现）

## 🔄 迁移步骤

### 步骤 1: 备份原文件
```bash
cd ios/Runner
cp AppDelegate.swift AppDelegate_Backup.swift
```

### 步骤 2: 迁移剩余的 Handler

#### 2.1 迁移 AuthAPIHandler

从 AppDelegate.swift 中找到以下方法并迁移：

```swift
// 需要迁移的方法：
- imRegister
- imLogin
- imLogout
- imGetCaptcha
- imChangePassword
- imResetPassword
- imSearchUser
- imUpdateUserInfo
- imDeactivateAccount
- imGetDeactivateStatus
- imCancelDeactivateAccount
- imGetUsersInfo
- imBatchGetUserPublicInfo
```

**迁移模板**：
```swift
class AuthAPIHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "imRegister":
            imRegister(call: call, result: result)
        case "imLogin":
            imLogin(call: call, result: result)
        // ... 添加其他 case
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // 从 AppDelegate 复制方法实现
    private func imRegister(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 复制原实现
    }
}
```

#### 2.2 迁移 ContactAPIHandler

需要迁移的方法：
```swift
- imAddContact
- imDeleteContact
- imBlockContact
- imUnblockContact
- imGetBlackStatus
- imGetContactList
- imSearchContact
- imGetFriendRequests
- imAcceptFriendRequest
- imRejectFriendRequest
- imGetContactGroups
- imCreateContactGroup
- imUpdateContactGroup
- imDeleteContactGroup
- imSetContactRemark
- imMoveContactToGroup
```

#### 2.3 迁移 ConversationAPIHandler

需要迁移的方法：
```swift
- imGetConversationList
- imGetConversation
- imGetUnreadConversations
- imUpdateConversation
- imCreateConversation
- imDeleteConversation
- imMarkConversationRead
- imClearConversationMessages
- imGetNotificationUnreadCount
- imPullNotifications
- imMarkNotificationRead
```

#### 2.4 迁移 MessageAPIHandler

需要迁移的方法：
```swift
- imSendTextMessage
- imSendImageMessage
- imSendVideoMessage
- imSendVoiceMessage
- imSendChannelMessage
- imSendGroupTextMessage
- imSendGroupImageMessage
- imSendGroupVoiceMessage
- imSendGroupVideoMessage
- imSendGroupAtMessage
- imPullMessages
- imPullGroupMessages
- imDeleteMessage
- imRegisterMessageCallbacks
- imUnregisterMessageCallbacks
```

#### 2.5 迁移 GroupAPIHandler

需要迁移的方法：
```swift
- imCreateGroup
- imGetGroupList
- imGetGroupMembers
- imGetGroupInfo
- imGetGroupPreview
- imUpdateGroup
- imSetGroupAlias
- imDissolveGroup
- imLeaveGroup
- imSetGroupDisturb
- imGetGroupDisturbStatus
- imAddGroupMembers
- imRemoveGroupMembers
```

#### 2.6 完善 StorageAPIHandler

需要迁移的方法：
```swift
- imPrepareUpload
- imUploadWithTencentSTS
```

### 步骤 3: 更新 FlutterAPIHandler 路由

确保 `FlutterAPIHandler.swift` 中的路由规则覆盖所有方法。

### 步骤 4: 替换 AppDelegate

```bash
cd ios/Runner
# 确认新文件正确
cat AppDelegate_New.swift

# 备份旧文件
mv AppDelegate.swift AppDelegate_Old.swift

# 使用新文件
mv AppDelegate_New.swift AppDelegate.swift
```

### 步骤 5: 测试验证

#### 5.1 编译测试
```bash
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug
```

#### 5.2 功能测试
测试每个模块的关键功能：
- [ ] 设备信息获取
- [ ] IM SDK 初始化和启动
- [ ] 用户登录/登出
- [ ] 联系人操作
- [ ] 消息发送/接收
- [ ] 群组操作
- [ ] 社群操作
- [ ] 文件上传

#### 5.3 回归测试
运行完整的测试套件，确保没有功能退化。

### 步骤 6: 清理

```bash
# 确认一切正常后，删除备份文件
rm AppDelegate_Old.swift
rm AppDelegate_Backup.swift
```

## 📝 迁移检查清单

### 代码迁移
- [ ] AuthAPIHandler 完成
- [ ] ContactAPIHandler 完成
- [ ] ConversationAPIHandler 完成
- [ ] MessageAPIHandler 完成
- [ ] GroupAPIHandler 完成
- [ ] StorageAPIHandler 完成

### 路由配置
- [ ] FlutterAPIHandler 路由规则完整
- [ ] 所有方法都能正确路由到对应 Handler

### 测试验证
- [ ] 编译通过
- [ ] 所有功能测试通过
- [ ] 性能无明显下降
- [ ] 内存占用正常

### 文档更新
- [ ] README.md 更新
- [ ] 代码注释完整
- [ ] API 文档更新

## 🐛 常见问题

### Q1: 编译错误 - 找不到方法
**原因**: 方法还在旧的 AppDelegate 中，未迁移到 Handler

**解决**: 
1. 在旧 AppDelegate 中找到该方法
2. 复制到对应的 Handler
3. 在 Handler 的 `handle()` 方法中添加 case

### Q2: 运行时错误 - FlutterMethodNotImplemented
**原因**: 路由规则未配置或 Handler 未实现

**解决**:
1. 检查 FlutterAPIHandler 的路由规则
2. 确认对应 Handler 的 `handle()` 方法包含该 case
3. 确认方法实现正确

### Q3: 功能异常 - 回调未执行
**原因**: 异步回调处理不当

**解决**:
1. 确保回调在正确的线程执行
2. 检查 completion handler 是否正确传递
3. 添加日志跟踪回调流程

### Q4: 内存泄漏
**原因**: 循环引用或未释放资源

**解决**:
1. 使用 `[weak self]` 避免循环引用
2. 确保 completion handler 被正确移除
3. 使用 Instruments 检测内存问题

## 💡 最佳实践

### 1. 逐步迁移
不要一次性迁移所有代码，按模块逐步进行：
1. 迁移一个 Handler
2. 测试验证
3. 提交代码
4. 继续下一个

### 2. 保持兼容性
确保迁移过程中 Flutter 端无需修改

### 3. 充分测试
每个迁移的模块都要进行完整测试

### 4. 代码审查
迁移完成后进行代码审查，确保质量

### 5. 文档同步
及时更新相关文档

## 📊 进度跟踪

| Handler | 状态 | 方法数 | 完成度 | 负责人 | 备注 |
|---------|------|--------|--------|--------|------|
| DeviceAPIHandler | ✅ 完成 | 15 | 100% | - | - |
| IMSDKAPIHandler | ✅ 完成 | 7 | 100% | - | - |
| CommunityAPIHandler | ✅ 完成 | 18 | 100% | - | - |
| AuthAPIHandler | ⏳ 待迁移 | ~13 | 0% | - | - |
| ContactAPIHandler | ⏳ 待迁移 | ~16 | 0% | - | - |
| ConversationAPIHandler | ⏳ 待迁移 | ~11 | 0% | - | - |
| MessageAPIHandler | ⏳ 待迁移 | ~15 | 0% | - | - |
| GroupAPIHandler | ⏳ 待迁移 | ~13 | 0% | - | - |
| StorageAPIHandler | ⏳ 待迁移 | ~5 | 20% | - | - |

**总体进度**: 3/9 完成 (33%)

## 🎉 完成标志

当以下所有项都完成时，迁移工作即告完成：

- [ ] 所有 Handler 实现完成
- [ ] 所有测试通过
- [ ] 文档更新完成
- [ ] 代码审查通过
- [ ] 旧代码清理完成
- [ ] 性能验证通过

---

**开始日期**: 2025-01-14
**预计完成**: 根据团队安排
**当前状态**: 进行中 (33%)
