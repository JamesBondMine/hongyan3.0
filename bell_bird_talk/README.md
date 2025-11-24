# 铃鸟聊天 (Bell Bird Talk)

一个展示 Flutter 与 iOS 原生互通的聊天项目示例。

## ✨ 核心功能

### 1️⃣ 数据互通
- ✅ Flutter ↔️ iOS 双向数据传递
- ✅ 保存/读取原生 UserDefaults
- ✅ 传递复杂数据结构（Map、List）

### 2️⃣ 调用 iOS SDK
- ✅ 获取设备信息
- ✅ 访问通讯录（需权限）
- ✅ 发送本地通知
- ✅ 打开相机/相册
- ✅ 打开系统设置

### 3️⃣ 原生 UI 嵌入
- ✅ Platform Views（在 Flutter 中嵌入原生视图）
- ✅ 原生按钮和控件
- ✅ 可集成地图、视频播放器等原生 SDK

### 4️⃣ 事件流通信
- ✅ iOS 持续推送事件到 Flutter
- ✅ 实时消息通知
- ✅ 状态变化监听

## 🏗️ 技术架构

```
Flutter (Dart)
    ↕️  Platform Channels
iOS Native (Swift)
    ↕️
iOS SDK / 原生功能
```

**通信方式**：
- `MethodChannel` - 方法调用（一次性请求/响应）
- `EventChannel` - 事件流（持续推送）
- `BasicMessageChannel` - 消息传递（双向通信）
- `Platform Views` - UI 嵌入

## 📁 项目结构

```
lib/
├── main.dart                    # 应用入口
├── services/
│   └── native_bridge.dart       # Flutter 端通信桥接
├── pages/
│   └── native_demo_page.dart    # 功能演示页面
└── widgets/
    └── native_ui_widget.dart    # Platform View 组件

ios/Runner/
├── AppDelegate.swift            # 注册 Platform Channels
├── NativeBridgeHandler.swift    # iOS 端通信处理
└── NativeUIView.swift           # Platform View 实现
```

## 🚀 快速开始

### 1. 安装依赖

```bash
flutter pub get
cd ios && pod install && cd ..
```

### 2. 运行项目

```bash
flutter run
```

### 3. 查看演示

打开应用后，点击 **"查看原生功能演示"** 按钮，测试以下功能：

- 📱 获取设备信息
- 💾 保存/读取原生数据
- 📞 获取通讯录
- 🔔 发送本地通知
- 🎨 显示原生弹窗
- 🖼️ 嵌入原生 UI

## 📖 详细文档

查看 [**NATIVE_BRIDGE_GUIDE.md**](./NATIVE_BRIDGE_GUIDE.md) 了解：

- 完整的实现原理
- 代码示例
- 最佳实践
- 常见问题解答

## 💡 使用场景

### 何时需要原生互通？

1. **调用系统功能**：通讯录、相机、通知、定位等
2. **集成第三方 SDK**：地图、支付、推送、统计等
3. **性能优化**：使用原生组件提升性能
4. **复用原生代码**：已有 iOS 代码库
5. **访问底层 API**：Flutter 尚未支持的功能

### 实际应用示例

| 功能 | 实现方式 |
|------|---------|
| 地图导航 | Platform View（嵌入高德/百度地图） |
| 视频播放 | Platform View（AVPlayer） |
| 支付功能 | MethodChannel（调用支付宝/微信 SDK） |
| 推送消息 | EventChannel（监听推送） |
| 数据加密 | MethodChannel（调用原生加密库） |

## 🔧 开发指南

### 添加新的原生功能

#### 1. Flutter 端

```dart
// lib/services/native_bridge.dart
Future<String?> yourNewMethod() async {
  return await _bridge.invokeMethod<String>('yourMethod', {
    'param1': 'value1',
  });
}
```

#### 2. iOS 端

```swift
// ios/Runner/NativeBridgeHandler.swift
case "yourMethod":
    guard let args = call.arguments as? [String: Any],
          let param1 = args["param1"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        return
    }
    
    // 实现你的逻辑
    result("返回结果")
```

### 添加 Platform View

#### 1. 创建原生视图

```swift
// ios/Runner/YourCustomView.swift
class YourCustomViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(...) -> FlutterPlatformView {
        return YourCustomView(...)
    }
}
```

#### 2. 注册视图

```swift
// AppDelegate.swift
let factory = YourCustomViewFactory(...)
registrar.register(factory, withId: "your-custom-view")
```

#### 3. Flutter 使用

```dart
UiKitView(
  viewType: 'your-custom-view',
  creationParams: {'key': 'value'},
  creationParamsCodec: const StandardMessageCodec(),
)
```

## ⚠️ 注意事项

1. **权限管理**：访问通讯录、相机等需要在 `Info.plist` 中声明权限
2. **线程安全**：iOS 端 UI 操作必须在主线程执行
3. **错误处理**：使用 `try-catch` 捕获 `PlatformException`
4. **数据类型**：注意 Dart 和 Swift 之间的类型映射
5. **Channel 命名**：使用唯一的反向域名

## 🛠️ 技术栈

- **Flutter**: 3.10+
- **Dart**: 3.10+
- **iOS**: 12.0+
- **Swift**: 5.0+

## 📝 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

- 项目：Bell Bird Talk
- 更新：2025-11-24

---

**开始使用** → 查看 [完整文档](./NATIVE_BRIDGE_GUIDE.md)
