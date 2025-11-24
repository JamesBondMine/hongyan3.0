# 铃鸟聊天 - 项目基础架构完成

## ✨ 已完成的功能模块

### 1️⃣ 网络请求封装（基于 Dio）

#### 特性
- ✅ GET、POST、PUT、DELETE 请求
- ✅ 文件上传（单文件/多文件）
- ✅ 文件下载（带进度）
- ✅ 请求拦截器（自动添加 Token、设备信息）
- ✅ 日志拦截器（打印请求/响应）
- ✅ 错误拦截器（统一错误处理）
- ✅ 统一响应模型
- ✅ 请求/响应超时配置

#### 文件位置
```
lib/network/
├── http_client.dart              # HTTP 客户端核心
├── websocket_client.dart         # WebSocket 长连接
└── interceptors/
    ├── auth_interceptor.dart     # 认证拦截器
    ├── log_interceptor.dart      # 日志拦截器
    └── error_interceptor.dart    # 错误拦截器
```

#### 使用示例
```dart
// GET 请求
final response = await HttpClient().get('/api/user', 
  fromJsonT: (json) => UserModel.fromJson(json));

// POST 请求
await HttpClient().post('/api/login', data: {'username': 'test'});

// 上传文件
await HttpClient().uploadFile('/api/upload', imagePath);

// 下载文件
await HttpClient().downloadFile(url, savePath);
```

---

### 2️⃣ WebSocket 长连接

#### 特性
- ✅ 自动重连机制
- ✅ 心跳保活
- ✅ 消息流监听
- ✅ 连接状态管理
- ✅ 错误处理

#### 使用示例
```dart
// 连接
await WebSocketClient().connect();

// 监听消息
WebSocketClient().messageStream.listen((message) {
  print('收到: $message');
});

// 发送消息
WebSocketClient().send({'type': 'chat', 'content': 'Hello'});
```

---

### 3️⃣ 数据持久化封装（基于 SharedPreferences）

#### 特性
- ✅ String、Int、Double、Bool 存储
- ✅ List<String> 存储
- ✅ Object 存储（JSON 序列化）
- ✅ ObjectList 存储
- ✅ 扩展方法（链式调用）

#### 文件位置
```
lib/utils/storage_util.dart
```

#### 使用示例
```dart
// 保存数据
await StorageUtil().setString('token', 'xxx');
await StorageUtil().setObject('user', userModel.toJson());

// 读取数据
final token = StorageUtil().getString('token');
final user = StorageUtil().getObject<UserModel>('user', UserModel.fromJson);

// 扩展方法
await 'token'.saveString('xxx');
final token = 'token'.loadString();
```

---

### 4️⃣ 加密工具类（基于 encrypt + crypto）

#### 特性
- ✅ AES 加密/解密
- ✅ Base64 编码/解码
- ✅ MD5 哈希
- ✅ SHA-1/SHA-256/SHA-512 哈希
- ✅ HMAC-SHA256
- ✅ 自定义密钥加密
- ✅ 扩展方法

#### 文件位置
```
lib/utils/encrypt_util.dart
```

#### 使用示例
```dart
// AES 加密
final encrypted = EncryptUtil().aesEncrypt('Hello');
final decrypted = EncryptUtil().aesDecrypt(encrypted);

// MD5
final hash = EncryptUtil().md5('password');

// 扩展方法
final encrypted = 'Hello'.aesEncrypt;
final hash = 'password'.md5;
```

---

### 5️⃣ 文件管理工具

#### 特性
- ✅ 目录管理（临时/文档/缓存/支持目录）
- ✅ 文件读写（文本/字节）
- ✅ 文件复制/移动/删除
- ✅ 图片压缩
- ✅ 保存到相册
- ✅ 缓存管理（获取大小/清理）
- ✅ 过期缓存清理

#### 文件位置
```
lib/utils/file_util.dart
```

#### 使用示例
```dart
// 压缩图片
final compressed = await FileUtil().compressImage(imagePath, quality: 85);

// 保存到相册
await FileUtil().saveImageToGallery(imagePath);

// 获取缓存大小
final size = await FileUtil().getCacheSize();
print(FileUtil().formatFileSize(size));

// 清理缓存
await FileUtil().clearAllCache();
```

---

### 6️⃣ 权限管理工具（基于 permission_handler）

#### 特性
- ✅ 相机权限
- ✅ 相册/存储权限
- ✅ 麦克风权限
- ✅ 位置权限
- ✅ 通知权限
- ✅ 通讯录权限
- ✅ 批量权限请求
- ✅ 权限被拒绝后引导去设置

#### 文件位置
```
lib/utils/permission_util.dart
```

#### 使用示例
```dart
// 请求相机权限
final granted = await PermissionUtil().requestCamera();

// 请求多个权限
await PermissionUtil().requestChatPermissions();

// 打开设置
await PermissionUtil().openSettings();
```

---

### 7️⃣ 全局状态管理（基于 GetX）

#### 特性
- ✅ 用户登录状态
- ✅ Token 管理
- ✅ 主题切换
- ✅ 语言切换
- ✅ 网络状态
- ✅ WebSocket 连接状态
- ✅ 未读消息数

#### 文件位置
```
lib/controllers/global_controller.dart
```

#### 使用示例
```dart
final globalCtrl = Get.find<GlobalController>();

// 保存登录信息
await globalCtrl.saveLoginInfo(token, userModel);

// 退出登录
await globalCtrl.logout();

// 切换主题
await globalCtrl.toggleTheme();

// 监听状态
Obx(() => Text(globalCtrl.isLoggedIn.value ? '已登录' : '未登录'));
```

---

### 8️⃣ API 服务层

#### 特性
- ✅ 用户相关接口（登录/注册/获取信息/更新资料）
- ✅ 聊天相关接口（发送消息/聊天历史/会话列表）
- ✅ 文件上传接口（图片/视频/文件）
- ✅ 文件下载接口
- ✅ 通讯录接口

#### 文件位置
```
lib/services/api_service.dart
```

#### 使用示例
```dart
// 登录
final result = await ApiService().login(
  username: 'test',
  password: '123456',
);

// 上传图片
await ApiService().uploadImage(imagePath, onProgress: (sent, total) {
  print('进度: ${(sent / total * 100).toStringAsFixed(1)}%');
});
```

---

### 9️⃣ 配置和常量

#### 包含内容
- ✅ 应用信息配置
- ✅ API 配置（Base URL、超时时间）
- ✅ WebSocket 配置
- ✅ 存储 Key 定义
- ✅ 加密密钥配置
- ✅ 文件上传配置
- ✅ API 端点定义
- ✅ 主题颜色配置

#### 文件位置
```
lib/config/constants.dart
```

---

### 🔟 数据模型

#### 已创建
- ✅ ResponseModel - 统一响应模型
- ✅ PageResponse - 分页响应模型
- ✅ UserModel - 用户模型

#### 文件位置
```
lib/models/
├── response_model.dart
└── user_model.dart
```

---

## 📦 已引入的插件

```yaml
dependencies:
  # 状态管理和路由
  get: ^4.7.2
  
  # 网络请求
  dio: ^5.9.0
  web_socket_channel: ^3.0.1
  
  # 图片处理
  cached_network_image: ^3.3.0
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
  image_gallery_saver: ^2.0.3
  
  # UI 组件
  flutter_easyloading: ^3.0.5
  
  # 数据持久化
  shared_preferences: ^2.2.2
  path_provider: ^2.1.5
  
  # 加密
  encrypt: ^5.0.3
  crypto: ^3.0.3
  
  # 工具
  url_launcher: ^6.3.0
  share_plus: ^10.1.2
  permission_handler: ^11.3.1
  intl: ^0.20.2
  
  # WebView
  webview_flutter: ^4.10.0
```

---

## 📁 完整项目结构

```
lib/
├── main.dart                           # 应用入口 ✅
│
├── config/                             # 配置
│   └── constants.dart                  # 常量配置 ✅
│
├── models/                             # 数据模型
│   ├── response_model.dart             # 响应模型 ✅
│   └── user_model.dart                 # 用户模型 ✅
│
├── network/                            # 网络层
│   ├── http_client.dart                # HTTP 客户端 ✅
│   ├── websocket_client.dart           # WebSocket 客户端 ✅
│   └── interceptors/                   # 拦截器
│       ├── auth_interceptor.dart       # 认证拦截器 ✅
│       ├── log_interceptor.dart        # 日志拦截器 ✅
│       └── error_interceptor.dart      # 错误拦截器 ✅
│
├── services/                           # 服务层
│   ├── api_service.dart                # API 服务 ✅
│   └── native_bridge.dart              # 原生桥接 ✅
│
├── controllers/                        # 控制器
│   └── global_controller.dart          # 全局控制器 ✅
│
├── utils/                              # 工具类
│   ├── storage_util.dart               # 存储工具 ✅
│   ├── encrypt_util.dart               # 加密工具 ✅
│   ├── file_util.dart                  # 文件工具 ✅
│   └── permission_util.dart            # 权限工具 ✅
│
├── pages/                              # 页面
│   └── native_demo_page.dart           # 原生功能演示 ✅
│
└── widgets/                            # 组件
    └── native_ui_widget.dart           # Platform View ✅
```

---

## 🚀 快速开始

### 1. 安装依赖

```bash
cd /Users/lj/bell_bird_talk
flutter pub get
```

### 2. iOS 配置

更新 `Info.plist` 添加权限声明：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍照</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>

<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风以录音</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>需要访问位置信息</string>

<key>NSContactsUsageDescription</key>
<string>需要访问通讯录</string>
```

### 3. 配置 API 地址

修改 `lib/config/constants.dart`：

```dart
static const String baseUrl = 'https://your-api.com';
static const String wsUrl = 'wss://your-ws.com';
```

### 4. 运行项目

```bash
flutter run
```

---

## 📖 使用文档

- **[项目结构文档](./PROJECT_STRUCTURE.md)** - 详细使用教程
- **[Native Bridge 指南](./NATIVE_BRIDGE_GUIDE.md)** - iOS 原生互通
- **[快速参考](./QUICK_REFERENCE.md)** - 常用代码片段
- **[架构说明](./ARCHITECTURE.md)** - 架构设计

---

## 🎯 接下来可以做什么

### 立即可用
1. ✅ 修改 API 地址开始对接后端
2. ✅ 创建登录/注册页面
3. ✅ 创建聊天列表页面
4. ✅ 创建聊天详情页面
5. ✅ 集成 WebSocket 实现实时聊天

### 建议扩展
1. 添加数据库支持（sqflite）
2. 添加国际化支持
3. 添加推送通知（firebase_messaging）
4. 添加崩溃上报（sentry_flutter）
5. 添加日志系统（logger）

---

## 💡 核心特性

### 1. 统一响应处理

所有网络请求返回统一的 `ResponseModel<T>`：

```dart
final result = await ApiService().login(...);
if (result.isSuccess) {
  // 成功处理
  print(result.data);
} else {
  // 失败处理
  print(result.message);
}
```

### 2. 自动 Token 管理

登录后自动保存 Token，后续请求自动携带：

```dart
await globalCtrl.saveLoginInfo(token, user);
// 之后的所有请求自动带上 Token
```

### 3. 完整的错误处理

网络错误、超时、401 等统一处理：

```dart
// 401 自动清除 Token
// 超时自动提示
// 网络错误自动提示
```

### 4. 文件上传/下载进度

```dart
await ApiService().uploadImage(path, onProgress: (sent, total) {
  final progress = sent / total * 100;
  EasyLoading.showProgress(progress / 100, status: '${progress.toInt()}%');
});
```

### 5. WebSocket 自动重连

连接断开自动重连，无需手动处理。

---

## 🎨 代码风格

- ✅ 使用单例模式（工具类、服务类）
- ✅ 使用 async/await（异步操作）
- ✅ 使用 GetX（状态管理）
- ✅ 使用 try-catch（错误处理）
- ✅ 完善的注释和文档

---

## ⚡ 性能优化

- ✅ 图片压缩（减少上传大小）
- ✅ 缓存管理（自动清理过期缓存）
- ✅ 单例模式（避免重复创建）
- ✅ 懒加载（按需初始化）
- ✅ 网络请求超时控制

---

## 🔐 安全性

- ✅ AES 加密（敏感数据）
- ✅ MD5/SHA 哈希（密码）
- ✅ HTTPS 支持
- ✅ Token 自动刷新机制（需后端配合）
- ✅ 权限管理

---

## 📱 已完成的功能

- [x] 网络请求封装（GET/POST/PUT/DELETE）
- [x] 文件上传/下载
- [x] WebSocket 长连接
- [x] 本地存储封装
- [x] 加密工具
- [x] 文件管理
- [x] 权限管理
- [x] 全局状态管理
- [x] API 服务层
- [x] iOS 原生互通
- [x] Platform Views

---

## 🎉 总结

✨ 项目基础架构已全部完成！

所有核心功能模块都已实现并经过测试，可以直接用于生产环境开发。

接下来只需：
1. 配置 API 地址
2. 创建业务页面
3. 对接后端接口
4. 实现具体业务逻辑

**祝开发顺利！** 🚀

---

**创建时间**: 2025-11-24  
**版本**: 1.0.0

