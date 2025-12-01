# IM SDK 崩溃修复方案

## 🔍 问题根因

**`EXC_BAD_ACCESS (code=1, address=0x0)`** - 空指针访问

### 造成崩溃的原因
1. **库版本冲突** - CocoaPods 的 OpenSSL/Protobuf/Abseil 与 SDK 自带的库冲突
2. **初始化顺序错误** - 没有在调用 `network_init()` 前设置必要的回调

## ✅ 已完成的修复

### 1. 移除 CocoaPods 冲突依赖

**修改文件**: `ios/Podfile`

**之前**:
```ruby
pod 'OpenSSL-Universal', '~> 1.1.1'
pod 'Protobuf', '~> 3.25'
pod 'abseil', '~> 1.20240116.0'
```

**现在**:
```ruby
# IM SDK 依赖库已在 ios_sdk_la 文件夹中提供
# 不需要通过 CocoaPods 引入，避免版本冲突
```

✅ SDK 的 `ios_sdk_la/` 文件夹已包含所有需要的库

### 2. 修正初始化顺序

**修改文件**: `ios/Runner/IMSDK/IMSDKManager.mm`

**新的初始化顺序**:
```objective-c
- (int)initSDKWithConfig:(NSString *)config {
    // 步骤1: 先设置全局回调（避免 SDK 访问空指针）
    network_set_event_callback(GlobalEventCallback);
    network_set_data_callback(GlobalDataCallback);
    
    // 步骤2: 设置客户端信息
    set_client_info("iOS", "16.0", "test-device-001", "Asia/Shanghai");
    
    // 步骤3: 初始化网络库
    int result = network_init();
    
    return result;
}
```

**关键点**: 
- ✅ 在 `network_init()` 之前先注册回调
- ✅ 避免 SDK 内部访问空回调指针导致崩溃

### 3. 恢复所有注释的代码

所有被注释的 SDK 调用都已恢复并使用正确的条件编译：
- `network_start()`
- `network_set_ip_table()`
- `network_add_target_to_group()`
- `network_stop()`
- 等等...

## 📝 测试步骤

### 在真机上测试

```bash
cd /Users/lj/hongyan3.0/bell_bird_talk
flutter run --device-id=00008101-00146C9C1E10001E
```

### 预期日志输出

**初始化成功**:
```
🚀 初始化 IM SDK
📝 步骤1: 设置全局回调...
✅ 回调设置完成
📝 步骤2: 设置客户端信息...
   客户端信息结果: 0
📝 步骤3: 调用 network_init()...
   network_init 结果: 0
✅ SDK 初始化成功
```

**如果仍然崩溃**:
- 记录崩溃前最后一条日志
- 查看具体是哪个步骤失败
- 检查是否有错误码

## 🔧 修改的文件列表

1. ✅ `ios/Podfile` - 移除冲突依赖
2. ✅ `ios/Runner/IMSDK/IMSDKManager.h` - 清理重复方法
3. ✅ `ios/Runner/IMSDK/IMSDKManager.mm` - 修正初始化逻辑
4. ✅ Pods 已重新安装

## 🎯 核心修复原理

### 问题
```
network_init() → 访问回调指针 → 空指针 → 崩溃
```

### 解决方案
```
1. network_set_event_callback(回调函数)  // 先注册
2. network_set_data_callback(回调函数)   // 避免空指针
3. set_client_info(...)                 // 设置信息
4. network_init()                       // 安全调用
```

## ⚠️ 如果还是崩溃

### 方案A: 联系 SDK 提供方
询问他们:
1. 完整的 iOS 初始化示例代码
2. 是否需要数据库路径或配置文件
3. 是否有其他前置依赖

### 方案B: 检查是否缺少其他设置
可能还需要：
- 注册其他监听器（好友、消息等）
- 设置数据库路径
- 创建特定目录
- 传入特定配置参数

### 方案C: 降级测试
如果 `network_init()` 还是崩溃，尝试：
1. 只调用 `init_sdk()` 不调用 `network_init()`
2. 查看 `init_sdk()` 的返回值和回调信息
3. 根据错误码查找文档

## 📊 理论分析

SDK 的 `network_init()` 内部可能有这样的代码：
```c
int network_init() {
    // SDK 内部可能这样使用回调
    if (g_event_callback != NULL) {  // 如果没有先设置，这里是 NULL
        g_event_callback(...);       // 解引用 NULL → 崩溃
    }
    
    // 或者
    g_event_callback(...);  // 直接使用 → 如果是 NULL 就崩溃
}
```

**我们的修复**: 在调用 `network_init()` 前，先通过 `network_set_event_callback()` 设置好回调函数，确保 SDK 内部不会访问空指针。

## 更新时间

2025-12-01 - 修复库冲突和初始化顺序问题

