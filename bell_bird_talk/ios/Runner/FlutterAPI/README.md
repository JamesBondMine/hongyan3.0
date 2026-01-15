# Flutter API 模块化架构

## 📁 目录结构

```
FlutterAPI/
├── FlutterAPIHandler.swift          # 主路由处理器
├── Handlers/
│   ├── DeviceAPIHandler.swift       # ✅ 设备相关（已完成）
│   ├── IMSDKAPIHandler.swift        # ✅ IM SDK 基础（已完成）
│   ├── CommunityAPIHandler.swift    # ✅ 社群管理（已完成）
│   ├── AuthAPIHandler.swift         # ⏳ 认证相关（待迁移）
│   ├── ContactAPIHandler.swift      # ⏳ 联系人管理（待迁移）
│   ├── ConversationAPIHandler.swift # ⏳ 会话管理（待迁移）
│   ├── MessageAPIHandler.swift      # ⏳ 消息管理（待迁移）
│   ├── GroupAPIHandler.swift        # ⏳ 群组管理（待迁移）
│   └── StorageAPIHandler.swift      # ⏳ 云存储（待迁移）
└── README.md                         # 本文档
```

## 🎯 设计目标

### 问题
- AppDelegate.swift 文件过于臃肿（4000+ 行）
- handleMethodCall 方法包含所有 API 处理逻辑
- 难以维护和扩展
- 代码职责不清晰

### 解决方案
- **模块化**：按功能领域拆分为独立的 Handler
- **单一职责**：每个 Handler 只处理特定领域的 API
- **路由分发**：FlutterAPIHandler 负责将请求路由到对应的 Handler
- **易于扩展**：新增功能只需创建新的 Handler

## 📋 Handler 职责划分

### 1. DeviceAPIHandler ✅
**职责**：设备相关功能
- 设备信息获取
- 数据存储（UserDefaults）
- 通讯录访问
- 相机调用
- 本地通知
- 原生 UI 交互
- C++ 数据传输
- 音频处理

**方法示例**：
- `getDeviceInfo`
- `saveData` / `loadData`
- `getContacts`
- `showAlert`
- `generateCppData`

### 2. IMSDKAPIHandler ✅
**职责**：IM SDK 基础功能
- SDK 初始化
- 网络服务启动/停止
- IP 配置和状态
- 网络检查

**方法示例**：
- `imInitialize`
- `imStart` / `imStop`
- `imSetIPTable`
- `imGetIPStatus`

### 3. CommunityAPIHandler ✅
**职责**：社群管理
- 社群列表和信息
- 加入/离开社群
- 频道管理（创建、更新、删除）
- 频道分组管理
- 社群成员管理
- 封禁成员管理

**方法示例**：
- `imGetCommunityList`
- `imJoinCommunity` / `imLeaveCommunity`
- `imCreateChannel` / `imUpdateChannel`
- `imGetCommunityMembers`
- `imGetCommunityBannedMembers`

### 4. AuthAPIHandler ⏳
**职责**：认证和用户管理
- 用户注册
- 登录/登出
- 密码管理
- 用户信息更新
- 账号注销

**待迁移方法**：
- `imRegister`
- `imLogin` / `imLogout`
- `imChangePassword` / `imResetPassword`
- `imUpdateUserInfo`
- `imSearchUser`

### 5. ContactAPIHandler ⏳
**职责**：联系人管理
- 添加/删除联系人
- 黑名单管理
- 好友申请处理
- 联系人分组
- 备注设置

**待迁移方法**：
- `imAddContact` / `imDeleteContact`
- `imBlockContact` / `imUnblockContact`
- `imGetContactList`
- `imGetFriendRequests`
- `imAcceptFriendRequest` / `imRejectFriendRequest`

### 6. ConversationAPIHandler ⏳
**职责**：会话管理
- 会话列表
- 会话操作（更新、删除、清空）
- 未读消息管理
- 通知管理

**待迁移方法**：
- `imGetConversationList`
- `imUpdateConversation`
- `imDeleteConversation`
- `imMarkConversationRead`
- `imGetNotificationUnreadCount`

### 7. MessageAPIHandler ⏳
**职责**：消息管理
- 发送各类消息（文本、图片、语音、视频）
- 拉取消息
- 删除消息
- 消息回调注册

**待迁移方法**：
- `imSendTextMessage` / `imSendImageMessage`
- `imSendGroupTextMessage`
- `imPullMessages`
- `imRegisterMessageCallbacks`

### 8. GroupAPIHandler ⏳
**职责**：群组管理
- 创建群组
- 群组信息管理
- 群组成员管理
- 群组设置

**待迁移方法**：
- `imCreateGroup`
- `imGetGroupList` / `imGetGroupInfo`
- `imUpdateGroup`
- `imAddGroupMembers` / `imRemoveGroupMembers`
- `imDissolveGroup` / `imLeaveGroup`

### 9. StorageAPIHandler ⏳
**职责**：云存储和文件管理
- 文件上传准备
- 云存储初始化（阿里云、腾讯云、AWS）
- 文件上传/下载

**待迁移方法**：
- `imPrepareUpload`
- `imUploadWithTencentSTS`
- `initAliyunOSS` / `uploadToAliyun`
- `downloadFile`

## 🔄 调用流程

```
Flutter
  ↓
MethodChannel
  ↓
NativeBridgeHandler.handleMethodCall()
  ↓
FlutterAPIHandler.handleMethodCall()
  ↓
[路由判断]
  ↓
具体的 Handler (例如: CommunityAPIHandler)
  ↓
IMSDKManager / 其他服务
  ↓
回调 Flutter
```

## 📝 如何添加新功能

### 1. 确定功能所属模块
根据功能类型选择合适的 Handler，或创建新的 Handler

### 2. 在 Handler 中添加方法
```swift
class CommunityAPIHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "imNewMethod":
            newMethod(call: call, result: result)
        // ...
        }
    }
    
    private func newMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 实现逻辑
    }
}
```

### 3. 更新路由（如果是新 Handler）
在 `FlutterAPIHandler.swift` 中添加路由规则

### 4. 测试
确保新功能在 Flutter 端可以正常调用

## 🚀 迁移步骤

### 当前状态
- ✅ 架构设计完成
- ✅ DeviceAPIHandler 已完成
- ✅ IMSDKAPIHandler 已完成
- ✅ CommunityAPIHandler 已完成
- ⏳ 其他 Handler 待迁移

### 下一步
1. 从 AppDelegate.swift 中复制对应方法到各个 Handler
2. 在 Handler 中实现 `handle()` 方法的 switch-case
3. 测试每个迁移的功能
4. 删除 AppDelegate.swift 中的旧代码
5. 用 `AppDelegate_New.swift` 替换 `AppDelegate.swift`

## 💡 最佳实践

### 1. 保持 Handler 职责单一
每个 Handler 只处理一个功能领域

### 2. 统一错误处理
```swift
result(FlutterError(
    code: "ERROR_CODE",
    message: "错误描述",
    details: nil
))
```

### 3. 参数验证
```swift
guard let args = call.arguments as? [String: Any],
      let param = args["param"] as? String else {
    result(FlutterError(code: "INVALID_ARGS", message: "参数错误", details: nil))
    return
}
```

### 4. 日志记录
```swift
print("📁 [功能名称]: 参数信息")
```

### 5. 异步处理
确保回调在主线程执行（如果需要）

## 📊 优势

### 代码组织
- ✅ 清晰的模块划分
- ✅ 易于查找和维护
- ✅ 降低文件复杂度

### 可维护性
- ✅ 修改影响范围小
- ✅ 易于理解和调试
- ✅ 便于团队协作

### 可扩展性
- ✅ 新增功能不影响现有代码
- ✅ 易于添加新的 Handler
- ✅ 支持功能模块化开发

### 性能
- ✅ 路由效率高
- ✅ 按需加载
- ✅ 内存占用优化

## 🔧 维护指南

### 添加新方法
1. 在对应 Handler 的 `handle()` 方法中添加 case
2. 实现具体的处理方法
3. 更新本文档

### 修改现有方法
1. 找到对应的 Handler
2. 修改实现逻辑
3. 测试验证

### 删除废弃方法
1. 从 Handler 中移除 case
2. 删除实现方法
3. 更新文档

## 📚 参考资料

- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [iOS Swift 编程指南](https://docs.swift.org/swift-book/)
- [项目 IM SDK 文档](../IMSDK/)

---

**最后更新**: 2025-01-14
**维护者**: 开发团队
