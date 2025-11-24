# Flutter ↔️ iOS 原生互通快速参考

## 🎯 三种通信方式速查

### 1️⃣ MethodChannel - 方法调用

**什么时候用？** 一次性请求-响应

```dart
// Flutter 端
await methodChannel.invokeMethod('methodName', {'key': 'value'});
```

```swift
// iOS 端
func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(responseData)
}
```

**典型场景**：
- ✅ 获取设备信息
- ✅ 打开相机选图
- ✅ 读写本地数据
- ✅ 调用原生 SDK

---

### 2️⃣ EventChannel - 事件流

**什么时候用？** iOS 持续推送数据到 Flutter

```dart
// Flutter 端
eventChannel.receiveBroadcastStream().listen((event) {
    print('收到: $event');
});
```

```swift
// iOS 端
eventSink?(["type": "update", "data": someData])
```

**典型场景**：
- ✅ GPS 位置更新
- ✅ 传感器数据
- ✅ 新消息推送
- ✅ 网络状态监听

---

### 3️⃣ Platform Views - UI 嵌入

**什么时候用？** 在 Flutter 中显示原生 UI

```dart
// Flutter 端
UiKitView(viewType: 'your-view-id')
```

```swift
// iOS 端
class CustomViewFactory: FlutterPlatformViewFactory {
    func create(...) -> FlutterPlatformView {
        return YourNativeView()
    }
}
```

**典型场景**：
- ✅ 地图（高德/百度）
- ✅ 视频播放器
- ✅ 广告 SDK
- ✅ WebView

---

## 📦 数据类型映射

| Dart | Swift | 示例 |
|------|-------|------|
| `null` | `nil` | - |
| `bool` | `Bool` | `true` / `false` |
| `int` | `Int` | `42` |
| `double` | `Double` | `3.14` |
| `String` | `String` | `"hello"` |
| `List` | `Array` | `[1, 2, 3]` |
| `Map` | `Dictionary` | `{"key": "value"}` |

---

## 🔥 常用代码片段

### Flutter 调用 iOS 获取数据

```dart
final result = await MethodChannel('com.your.app/method')
    .invokeMethod<Map>('getData', {'id': 123});
    
if (result != null) {
  print('数据: ${result['name']}');
}
```

### iOS 返回数据到 Flutter

```swift
case "getData":
    let data: [String: Any] = [
        "id": 123,
        "name": "张三",
        "age": 25
    ]
    result(data)
```

### 错误处理

```dart
// Flutter 端
try {
  final result = await channel.invokeMethod('method');
} on PlatformException catch (e) {
  print('错误: ${e.code} - ${e.message}');
}
```

```swift
// iOS 端
result(FlutterError(
    code: "NOT_FOUND",
    message: "数据不存在",
    details: nil
))
```

### 主线程操作

```swift
// iOS 端 - UI 操作必须在主线程
DispatchQueue.main.async {
    result(data)
}
```

---

## 🚨 常见错误

### ❌ Channel 名称不匹配

```dart
// Flutter: 'com.app/method'
// iOS:     'com.app/methods'  ← 注意 's'
// ❌ 调用失败
```

**解决**：确保两端名称完全一致

### ❌ 未注册 Platform View

```dart
UiKitView(viewType: 'my-view')  // ❌ 找不到视图
```

```swift
// 必须先注册
registrar.register(factory, withId: "my-view")  // ✅
```

### ❌ 类型转换错误

```dart
// ❌ 错误
Map<String, dynamic> data = await channel.invokeMethod('getData');

// ✅ 正确
final result = await channel.invokeMethod<Map>('getData');
Map<String, dynamic>? data = result?.cast<String, dynamic>();
```

---

## 📋 检查清单

开发新功能前，确认：

- [ ] Channel 名称两端一致
- [ ] 参数类型匹配
- [ ] iOS 端有错误处理
- [ ] Flutter 端有 try-catch
- [ ] iOS UI 操作在主线程
- [ ] 需要的权限已声明（Info.plist）
- [ ] Platform View 已注册

---

## 🔧 调试技巧

### 1. 打印日志

```dart
// Flutter
print('🔵 [Flutter] 调用: $methodName, 参数: $args');
```

```swift
// iOS
print("🔴 [iOS] 收到调用: \(call.method)")
print("📦 [iOS] 参数: \(call.arguments ?? "无")")
```

### 2. 检查 Channel 是否连接

```dart
try {
  await channel.invokeMethod('ping');
  print('✅ Channel 已连接');
} catch (e) {
  print('❌ Channel 未连接: $e');
}
```

### 3. 断点调试

- Flutter: 在 `invokeMethod` 前后打断点
- iOS: 在 `handleMethodCall` 中打断点

---

## 📂 项目文件速查

| 文件 | 作用 |
|------|------|
| `lib/services/native_bridge.dart` | Flutter 通信桥接 |
| `ios/Runner/AppDelegate.swift` | 注册 Channels |
| `ios/Runner/NativeBridgeHandler.swift` | iOS 通信处理 |
| `ios/Runner/NativeUIView.swift` | Platform View 实现 |
| `lib/pages/native_demo_page.dart` | 功能演示页面 |

---

## 🎓 学习路径

1. **基础** → 理解 MethodChannel（30分钟）
2. **进阶** → 掌握 EventChannel（20分钟）
3. **高级** → 使用 Platform Views（1小时）
4. **实战** → 集成真实 SDK（2-4小时）

---

## 💡 实战案例

### 案例 1：集成支付宝支付

```dart
// 1. Flutter 调用
final result = await channel.invokeMethod('alipay', {
  'orderId': '12345',
  'amount': 99.00,
});
```

```swift
// 2. iOS 调用支付宝 SDK
case "alipay":
    AlipaySDK.defaultService().payOrder(orderString) { result in
        result(["status": "success"])
    }
```

### 案例 2：嵌入高德地图

```dart
// Flutter 使用
UiKitView(
  viewType: 'amap-view',
  creationParams: {
    'latitude': 39.9,
    'longitude': 116.4,
  },
)
```

```swift
// iOS 创建地图
class AmapViewFactory: FlutterPlatformViewFactory {
    func create(...) -> FlutterPlatformView {
        let mapView = MAMapView()
        // 配置地图...
        return AmapView(mapView: mapView)
    }
}
```

---

## 🔗 相关资源

- [完整文档](./NATIVE_BRIDGE_GUIDE.md)
- [Flutter 官方文档](https://docs.flutter.dev/platform-integration/platform-channels)
- [演示视频](./docs/demo.mp4) *(如果有)*

---

**快速开始** → 运行 `flutter run` 查看演示

