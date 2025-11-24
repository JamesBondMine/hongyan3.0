# 架构说明

## 📐 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   UI Layer   │  │ Demo Pages   │  │ Native Widgets   │  │
│  │              │  │              │  │                  │  │
│  │  main.dart   │  │ native_demo  │  │ native_ui_widget │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                   │             │
│         └─────────────────┼───────────────────┘             │
│                           │                                 │
│              ┌────────────▼────────────┐                    │
│              │  Native Bridge Service  │                    │
│              │                         │                    │
│              │  - MethodChannel        │                    │
│              │  - EventChannel         │                    │
│              │  - MessageChannel       │                    │
│              └────────────┬────────────┘                    │
└───────────────────────────┼─────────────────────────────────┘
                            │
                            │ Platform Channels
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    iOS Native Layer                          │
│                                                              │
│              ┌────────────────────────┐                      │
│              │    AppDelegate.swift   │                      │
│              │                        │                      │
│              │  - 初始化 Channels      │                      │
│              │  - 注册 Platform Views  │                      │
│              └───────────┬────────────┘                      │
│                          │                                   │
│         ┌────────────────┼────────────────┐                 │
│         │                │                │                 │
│  ┌──────▼──────────┐  ┌─▼────────────┐  ┌▼──────────────┐  │
│  │ NativeBridge    │  │ NativeUIView │  │ Platform Views│  │
│  │ Handler.swift   │  │ Factory      │  │ (地图/视频等)  │  │
│  │                 │  │              │  │              │  │
│  │ - Method处理    │  │ - 创建原生UI  │  │ - 第三方SDK   │  │
│  │ - Event推送     │  │ - 手势交互    │  │              │  │
│  │ - Message通信   │  │              │  │              │  │
│  └────────┬────────┘  └──────────────┘  └───────────────┘  │
│           │                                                 │
│  ┌────────▼─────────────────────────────────────────────┐  │
│  │              iOS System & SDKs                       │  │
│  │                                                      │  │
│  │  • UIKit          • Contacts      • AVFoundation    │  │
│  │  • UserDefaults   • MapKit        • UserNotifications│ │
│  │  • CoreLocation   • 第三方SDK      • 其他系统功能     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 数据流向

### 1️⃣ Flutter → iOS (MethodChannel)

```
┌─────────┐                                   ┌──────────┐
│ Flutter │  invokeMethod('getData', args)    │   iOS    │
│  Page   │ ──────────────────────────────>   │ Handler  │
│         │                                   │          │
│         │  <────────────────────────────    │          │
│         │       result(data)                │          │
└─────────┘                                   └──────────┘
```

**示例**：获取设备信息
```dart
// 1. Flutter 发起
final info = await service.getDeviceInfo();

// 2. iOS 响应
result(["deviceName": "iPhone", "version": "17.0"])
```

---

### 2️⃣ iOS → Flutter (EventChannel)

```
┌─────────┐                                   ┌──────────┐
│ Flutter │  listen()                         │   iOS    │
│  Page   │ ──────────────────────────────>   │ Handler  │
│         │                                   │          │
│         │  eventSink?(event1)               │          │
│         │  <────────────────────────────    │          │
│         │                                   │          │
│         │  eventSink?(event2)               │          │
│         │  <────────────────────────────    │          │
└─────────┘                                   └──────────┘
```

**示例**：位置更新
```swift
// iOS 持续推送
Timer.scheduledTimer(withTimeInterval: 1.0) { _ in
    eventSink?(["lat": 39.9, "lng": 116.4])
}

// Flutter 监听
eventStream.listen((location) {
    print('位置: $location');
})
```

---

### 3️⃣ Platform View 嵌入

```
┌──────────────────────────────────────┐
│         Flutter Widget Tree          │
│                                      │
│  Column(                             │
│    children: [                       │
│      Text("标题"),                   │
│      ┌────────────────────────────┐  │
│      │     UiKitView             │  │
│      │  ┌────────────────────┐   │  │
│      │  │  iOS Native View   │   │  │
│      │  │                    │   │  │
│      │  │  • UIButton        │   │  │
│      │  │  • UILabel         │   │  │
│      │  │  • MapView         │   │  │
│      │  └────────────────────┘   │  │
│      └────────────────────────────┘  │
│      Text("底部"),                   │
│    ]                                 │
│  )                                   │
└──────────────────────────────────────┘
```

---

## 📦 模块职责

### Flutter 端

| 模块 | 文件 | 职责 |
|------|------|------|
| **桥接层** | `services/native_bridge.dart` | 封装 Platform Channels，提供统一接口 |
| **业务层** | `services/native_bridge.dart` | 具体功能调用（设备信息、通讯录等） |
| **UI层** | `pages/native_demo_page.dart` | 展示和交互 |
| **组件层** | `widgets/native_ui_widget.dart` | Platform View 组件封装 |

### iOS 端

| 模块 | 文件 | 职责 |
|------|------|------|
| **注册层** | `AppDelegate.swift` | 初始化并注册所有 Channels 和 Views |
| **处理层** | `NativeBridgeHandler.swift` | 处理来自 Flutter 的调用请求 |
| **UI层** | `NativeUIView.swift` | 创建和管理原生 UI 组件 |
| **SDK层** | 系统框架 | 调用 iOS 系统功能和第三方 SDK |

---

## 🎯 核心组件详解

### 1. NativeBridge (Flutter)

```dart
class NativeBridge {
  // 单例模式
  static final NativeBridge _instance = NativeBridge._internal();
  factory NativeBridge() => _instance;
  
  // 三种 Channel
  static const MethodChannel _methodChannel = ...;
  static const EventChannel _eventChannel = ...;
  static const BasicMessageChannel _messageChannel = ...;
  
  // 对外接口
  Future<T?> invokeMethod<T>(...);
  Stream<dynamic> get eventStream;
  Future<dynamic> sendMessage(...);
}
```

**特点**：
- ✅ 单例模式，全局唯一
- ✅ 封装底层 Channel 细节
- ✅ 统一错误处理
- ✅ 类型安全

### 2. IOSNativeService (Flutter)

```dart
class IOSNativeService {
  final NativeBridge _bridge = NativeBridge();
  
  // 业务方法
  Future<Map?> getDeviceInfo() { ... }
  Future<List?> getContacts() { ... }
  Future<bool?> saveData(...) { ... }
}
```

**特点**：
- ✅ 业务逻辑封装
- ✅ 清晰的方法命名
- ✅ 参数验证
- ✅ 易于测试和维护

### 3. NativeBridgeHandler (iOS)

```swift
class NativeBridgeHandler: NSObject {
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  
  func setup(with controller: FlutterViewController) {
    // 初始化 Channels
  }
  
  private func handleMethodCall(...) {
    switch call.method {
    case "method1": ...
    case "method2": ...
    }
  }
}
```

**特点**：
- ✅ 集中管理所有 Channel
- ✅ Switch 分发调用
- ✅ 统一错误返回
- ✅ 支持异步操作

---

## 🔐 权限管理

### Info.plist 配置

```xml
<!-- 通讯录权限 -->
<key>NSContactsUsageDescription</key>
<string>需要访问通讯录以选择联系人</string>

<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍照</string>

<!-- 相册权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>

<!-- 位置权限 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要访问位置信息</string>
```

### 权限请求流程

```swift
// iOS 端
func getContacts(result: @escaping FlutterResult) {
    let store = CNContactStore()
    
    // 1. 请求权限
    store.requestAccess(for: .contacts) { granted, error in
        if granted {
            // 2. 权限通过，返回数据
            result(contactsData)
        } else {
            // 3. 权限拒绝，返回错误
            result(FlutterError(code: "PERMISSION_DENIED", ...))
        }
    }
}
```

```dart
// Flutter 端
try {
  final contacts = await service.getContacts();
} on PlatformException catch (e) {
  if (e.code == 'PERMISSION_DENIED') {
    // 提示用户去设置中开启权限
  }
}
```

---

## 🚀 性能优化

### 1. 减少跨平台调用

❌ **不好的做法**
```dart
for (var i = 0; i < 1000; i++) {
  await channel.invokeMethod('process', i);  // 调用1000次
}
```

✅ **好的做法**
```dart
await channel.invokeMethod('batchProcess', list);  // 调用1次
```

### 2. 异步处理

```swift
// iOS 端 - 耗时操作放到后台线程
case "heavyTask":
    DispatchQueue.global().async {
        let result = self.performHeavyTask()
        
        DispatchQueue.main.async {
            result(result)
        }
    }
```

### 3. 缓存数据

```dart
class IOSNativeService {
  Map<String, dynamic>? _cachedDeviceInfo;
  
  Future<Map?> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo;  // 返回缓存
    }
    
    _cachedDeviceInfo = await _bridge.invokeMethod('getDeviceInfo');
    return _cachedDeviceInfo;
  }
}
```

---

## 🧪 测试策略

### 1. Mock 测试 (Flutter)

```dart
class MockNativeBridge extends Mock implements NativeBridge {}

void main() {
  test('getDeviceInfo returns data', () async {
    final mockBridge = MockNativeBridge();
    when(mockBridge.invokeMethod<Map>('getDeviceInfo'))
        .thenAnswer((_) async => {'deviceName': 'Test'});
    
    // 测试...
  });
}
```

### 2. 单元测试 (iOS)

```swift
class NativeBridgeHandlerTests: XCTestCase {
    func testGetDeviceInfo() {
        let handler = NativeBridgeHandler()
        let expectation = XCTestExpectation()
        
        handler.getDeviceInfo { result in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

---

## 📊 调用链追踪

### 完整调用链示例：获取设备信息

```
1. 用户点击按钮
   ↓
2. native_demo_page.dart: _getDeviceInfo()
   ↓
3. native_bridge.dart: IOSNativeService.getDeviceInfo()
   ↓
4. native_bridge.dart: NativeBridge.invokeMethod('getDeviceInfo')
   ↓
5. Platform Channel (序列化数据)
   ↓
6. AppDelegate.swift: FlutterMethodChannel 接收
   ↓
7. NativeBridgeHandler.swift: handleMethodCall()
   ↓
8. NativeBridgeHandler.swift: getDeviceInfo()
   ↓
9. iOS UIDevice API
   ↓
10. 返回数据 result(deviceInfo)
   ↓
11. Platform Channel (反序列化数据)
   ↓
12. Flutter 接收结果
   ↓
13. 更新 UI 显示
```

---

## 🎨 设计模式

### 1. 单例模式
- `NativeBridge` - 确保全局唯一实例

### 2. 工厂模式
- `NativeUIViewFactory` - 创建原生视图

### 3. 代理模式
- `FlutterStreamHandler` - 处理事件流

### 4. 观察者模式
- `EventChannel` - 事件订阅/推送

---

## 📈 扩展性

### 添加新的原生功能

1. **Flutter 端** (`native_bridge.dart`)
   ```dart
   Future<T> yourNewMethod() async {
     return await _bridge.invokeMethod('newMethod', args);
   }
   ```

2. **iOS 端** (`NativeBridgeHandler.swift`)
   ```swift
   case "newMethod":
       // 实现逻辑
       result(data)
   ```

### 添加新的 Platform View

1. **创建 Factory** (`YourView.swift`)
2. **注册** (`AppDelegate.swift`)
3. **使用** (`your_widget.dart`)

---

## 🔗 相关文档

- [完整指南](./NATIVE_BRIDGE_GUIDE.md)
- [快速参考](./QUICK_REFERENCE.md)
- [项目 README](./README.md)

---

**最后更新**: 2025-11-24

