# IM SDK 架构设计

## 🏗️ 架构概述

采用**单一职责原则**，将 IM SDK 功能按业务模块拆分成多个管理类，提高代码可维护性和可扩展性。

## 📦 模块划分

### 1. IMSDKManager（核心管理类）
**职责**：SDK 初始化、网络管理、底层配置

**主要功能**：
- SDK 初始化（`initSDKWithConfig:`）
- 网络服务管理（start/stop/cleanup）
- 网络状态检测
- 全局回调设置
- 连接管理

**文件**：
- `IMSDKManager.h`
- `IMSDKManager.mm`

### 2. IMSDKAuthManager（认证管理类）✅ 已实现
**职责**：用户认证相关功能

**主要功能**：
- 用户登录（User ID / Token）
- 用户注册
- 验证码获取
- 忘记密码（待实现）

**文件**：
- `IMSDKAuthManager.h`
- `IMSDKAuthManager.mm`

### 3. IMSDKMessageManager（消息管理类）📋 待实现
**职责**：消息收发、历史记录

**主要功能**：
- 发送单聊消息
- 发送群聊消息
- 获取历史消息
- 撤回消息
- 消息已读
- 消息搜索

### 4. IMSDKContactManager（联系人管理类）📋 待实现
**职责**：好友关系管理

**主要功能**：
- 添加好友
- 删除好友
- 获取好友列表
- 好友请求处理
- 黑名单管理

### 5. IMSDKGroupManager（群组管理类）📋 待实现
**职责**：群组相关操作

**主要功能**：
- 创建群组
- 加入/退出群组
- 群成员管理
- 群信息修改
- 群公告

### 6. IMSDKUserManager（用户信息管理类）📋 待实现
**职责**：用户信息查询和管理

**主要功能**：
- 获取用户信息
- 搜索用户
- 更新个人信息
- 用户状态

## 🎯 设计原则

### 1. 单一职责
每个管理类只负责一个业务领域，降低耦合度。

### 2. 统一回调
所有异步操作使用统一的回调格式：
```objective-c
typedef void (^IMSDKAuthCompletion)(int errorCode, uint64_t reqId, NSString *data);
```

### 3. 单例模式
每个管理类使用单例模式，方便全局访问：
```objective-c
[IMSDKAuthManager sharedManager]
[IMSDKMessageManager sharedManager]
```

### 4. 回调字典管理
使用字典管理异步回调，避免内存泄漏：
```objective-c
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Completion> *callbacks;
```

## 📝 使用示例

### 初始化 SDK（在应用启动时）
```swift
// 1. 初始化核心 SDK
let result = IMSDKManager.shared().initSDK(withConfig: nil)
if result == 0 {
    print("✅ SDK 初始化成功")
} else {
    print("❌ SDK 初始化失败: \(result)")
}
```

### 用户登录
```swift
// 2. 用户登录
IMSDKAuthManager.shared().login(withUserId: "user123", token: "token456") { errorCode, reqId, data in
    if errorCode == 0 {
        print("✅ 登录成功: \(data ?? "")")
        // 登录成功后，可以使用其他功能
    } else {
        print("❌ 登录失败: errorCode=\(errorCode)")
    }
}
```

### 发送消息（待实现）
```swift
// 3. 发送消息
IMSDKMessageManager.shared().sendMessage(
    content: "Hello!",
    toUserId: "user456",
    msgType: 1
) { errorCode, reqId, data in
    if errorCode == 0 {
        print("✅ 消息发送成功")
    }
}
```

### 添加好友（待实现）
```swift
// 4. 添加好友
IMSDKContactManager.shared().addFriend(
    userId: "user789",
    message: "你好，交个朋友吧"
) { errorCode, reqId, data in
    if errorCode == 0 {
        print("✅ 好友请求发送成功")
    }
}
```

## 🔄 依赖关系

```
Flutter 层
    ↓
AppDelegate (MethodChannel)
    ↓
┌────────────────────────────────────────┐
│         IM SDK Manager Layer           │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │      IMSDKManager (核心)         │ │
│  │  - SDK 初始化                    │ │
│  │  - 网络管理                      │ │
│  └──────────────────────────────────┘ │
│                                        │
│  ┌──────────────┐  ┌──────────────┐  │
│  │ AuthManager  │  │MessageManager│  │
│  │  - 登录      │  │  - 发送消息  │  │
│  │  - 注册      │  │  - 历史记录  │  │
│  └──────────────┘  └──────────────┘  │
│                                        │
│  ┌──────────────┐  ┌──────────────┐  │
│  │ContactManager│  │ GroupManager │  │
│  │  - 好友管理  │  │  - 群组管理  │  │
│  └──────────────┘  └──────────────┘  │
└────────────────────────────────────────┘
    ↓
C++ SDK (libnet_core.a)
```

## 📂 文件组织

```
ios/Runner/IMSDK/
├── network_lib.h              # C++ SDK 头文件
├── callback_types.h           # 回调类型定义
├── common_definitions.h       # 通用定义
├── libnet_core.a             # C++ SDK 静态库
├── ios_sdk_la/               # 依赖库目录
│   └── ...
├── IMSDKManager.h            # 核心管理类（头文件）
├── IMSDKManager.mm           # 核心管理类（实现）
├── IMSDKAuthManager.h        # 认证管理类（头文件）✅
├── IMSDKAuthManager.mm       # 认证管理类（实现）✅
├── IMSDKMessageManager.h     # 消息管理类（待创建）
├── IMSDKMessageManager.mm    # 消息管理类（待创建）
├── IMSDKContactManager.h     # 联系人管理类（待创建）
├── IMSDKContactManager.mm    # 联系人管理类（待创建）
├── IMSDKGroupManager.h       # 群组管理类（待创建）
└── IMSDKGroupManager.mm      # 群组管理类（待创建）
```

## ✅ 优势

1. **清晰的职责划分**：每个类只负责一个业务领域
2. **易于维护**：修改某个功能只需要改对应的管理类
3. **便于测试**：可以单独测试每个管理类
4. **易于扩展**：新增功能只需添加新的管理类
5. **团队协作友好**：不同开发者可以并行开发不同的管理类

## 🚀 下一步

1. ✅ 已完成：`IMSDKAuthManager`（认证管理）
2. 📋 待实现：`IMSDKMessageManager`（消息管理）
3. 📋 待实现：`IMSDKContactManager`（联系人管理）
4. 📋 待实现：`IMSDKGroupManager`（群组管理）
5. 📋 待实现：`IMSDKUserManager`（用户信息）

## 📝 注意事项

1. **初始化顺序**：必须先初始化 `IMSDKManager`，再使用其他管理类
2. **线程安全**：所有回调都在主线程执行
3. **内存管理**：使用 `NSMutableDictionary` 管理回调，自动释放
4. **错误处理**：统一的错误码机制，0 表示成功

---

**更新时间**：2025-12-01
**架构版本**：v1.0

