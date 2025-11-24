# 项目架构文档

## 📁 项目结构

```
lib/
├── main.dart                           # 应用入口
│
├── config/                             # 配置文件
│   └── constants.dart                  # 常量配置
│
├── models/                             # 数据模型
│   ├── response_model.dart             # 统一响应模型
│   └── user_model.dart                 # 用户模型
│
├── network/                            # 网络层
│   ├── http_client.dart                # HTTP 客户端（Dio 封装）
│   ├── websocket_client.dart           # WebSocket 客户端
│   └── interceptors/                   # 拦截器
│       ├── auth_interceptor.dart       # 认证拦截器
│       ├── log_interceptor.dart        # 日志拦截器
│       └── error_interceptor.dart      # 错误拦截器
│
├── services/                           # 服务层
│   ├── api_service.dart                # API 服务
│   └── native_bridge.dart              # 原生桥接服务
│
├── controllers/                        # 控制器（GetX）
│   └── global_controller.dart          # 全局控制器
│
├── utils/                              # 工具类
│   ├── storage_util.dart               # 本地存储工具
│   ├── encrypt_util.dart               # 加密工具
│   ├── file_util.dart                  # 文件管理工具
│   └── permission_util.dart            # 权限管理工具
│
├── pages/                              # 页面
│   └── native_demo_page.dart           # 原生功能演示页面
│
└── widgets/                            # 自定义组件
    └── native_ui_widget.dart           # Platform View 组件
```

---

## 🚀 快速开始

### 1. 初始化

在 `main.dart` 中已经完成初始化：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化本地存储
  await StorageUtil.init();
  
  // 初始化全局控制器
  Get.put(GlobalController());
  
  runApp(const MyApp());
}
```

### 2. 使用网络请求

#### 方式一：直接使用 HttpClient

```dart
import 'package:bell_bird_talk/network/http_client.dart';

// GET 请求
final response = await HttpClient().get<Map>(
  '/api/user/info',
  queryParameters: {'userId': '123'},
  fromJsonT: (json) => json as Map<String, dynamic>,
);

if (response.isSuccess) {
  print('数据: ${response.data}');
} else {
  print('错误: ${response.message}');
}
```

#### 方式二：使用 ApiService（推荐）

```dart
import 'package:bell_bird_talk/services/api_service.dart';

// 登录
final result = await ApiService().login(
  username: 'test',
  password: '123456',
);

if (result.isSuccess) {
  final token = result.data?['token'];
  print('登录成功，Token: $token');
}
```

### 3. 文件上传

```dart
import 'package:bell_bird_talk/services/api_service.dart';

// 上传图片
final result = await ApiService().uploadImage(
  imagePath,
  onProgress: (sent, total) {
    print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);

if (result.isSuccess) {
  final imageUrl = result.data?['url'];
  print('上传成功: $imageUrl');
}
```

### 4. 文件下载

```dart
import 'package:bell_bird_talk/services/api_service.dart';
import 'package:bell_bird_talk/utils/file_util.dart';

// 获取保存路径
final dir = await FileUtil().getImageCacheDir();
final savePath = '${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';

// 下载文件
final result = await ApiService().downloadFile(
  'https://example.com/image.jpg',
  savePath,
  onProgress: (received, total) {
    print('下载进度: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);

if (result.isSuccess) {
  print('下载完成: ${result.data}');
}
```

### 5. WebSocket 连接

```dart
import 'package:bell_bird_talk/network/websocket_client.dart';

// 连接
await WebSocketClient().connect();

// 监听消息
WebSocketClient().messageStream.listen((message) {
  print('收到消息: $message');
});

// 发送消息
WebSocketClient().send({
  'type': 'chat',
  'content': 'Hello',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

// 断开连接
await WebSocketClient().disconnect();
```

### 6. 本地存储

```dart
import 'package:bell_bird_talk/utils/storage_util.dart';

// 保存数据
await StorageUtil().setString('key', 'value');
await StorageUtil().setInt('count', 100);
await StorageUtil().setBool('isVip', true);

// 读取数据
final value = StorageUtil().getString('key');
final count = StorageUtil().getInt('count');
final isVip = StorageUtil().getBool('isVip');

// 保存对象
await StorageUtil().setObject('user', userModel.toJson());

// 读取对象
final user = StorageUtil().getObject<UserModel>(
  'user',
  (json) => UserModel.fromJson(json),
);

// 删除数据
await StorageUtil().remove('key');

// 清空所有数据
await StorageUtil().clear();
```

### 7. 加密/解密

```dart
import 'package:bell_bird_talk/utils/encrypt_util.dart';

// AES 加密
final encrypted = EncryptUtil().aesEncrypt('Hello World');
print('加密: $encrypted');

// AES 解密
final decrypted = EncryptUtil().aesDecrypt(encrypted);
print('解密: $decrypted');

// MD5
final md5Hash = EncryptUtil().md5('password');
print('MD5: $md5Hash');

// 使用扩展方法
final encrypted2 = 'Hello'.aesEncrypt;
final md5Hash2 = 'password'.md5;
```

### 8. 文件管理

```dart
import 'package:bell_bird_talk/utils/file_util.dart';

// 获取缓存目录
final cacheDir = await FileUtil().getCacheDir();
print('缓存目录: ${cacheDir.path}');

// 压缩图片
final compressedPath = await FileUtil().compressImage(
  imagePath,
  quality: 85,
);

// 保存到相册
final saved = await FileUtil().saveImageToGallery(imagePath);
if (saved) {
  print('已保存到相册');
}

// 获取缓存大小
final cacheSize = await FileUtil().getCacheSize();
print('缓存大小: ${FileUtil().formatFileSize(cacheSize)}');

// 清理缓存
await FileUtil().clearAllCache();
```

### 9. 权限管理

```dart
import 'package:bell_bird_talk/utils/permission_util.dart';

// 请求相机权限
final granted = await PermissionUtil().requestCamera();
if (granted) {
  // 打开相机
} else {
  print('相机权限被拒绝');
}

// 请求多个权限
final permissions = await PermissionUtil().requestChatPermissions();
if (permissions) {
  print('所有权限已授予');
}

// 打开设置
await PermissionUtil().openSettings();
```

### 10. 全局状态管理

```dart
import 'package:get/get.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';

// 获取全局控制器
final globalCtrl = Get.find<GlobalController>();

// 监听登录状态
Obx(() {
  if (globalCtrl.isLoggedIn.value) {
    return Text('已登录');
  } else {
    return Text('未登录');
  }
});

// 监听未读消息数
Obx(() => Badge(
  count: globalCtrl.unreadCount.value,
  child: Icon(Icons.message),
));

// 切换主题
await globalCtrl.toggleTheme();

// 退出登录
await globalCtrl.logout();
```

---

## 🔥 核心功能详解

### 网络请求流程

```
1. 调用 ApiService 方法
   ↓
2. HttpClient 处理请求
   ↓
3. AuthInterceptor 添加 Token
   ↓
4. LogInterceptor 打印日志
   ↓
5. 发送请求
   ↓
6. 接收响应
   ↓
7. ErrorInterceptor 处理错误
   ↓
8. 返回 ResponseModel
```

### WebSocket 连接流程

```
1. 调用 connect()
   ↓
2. 建立连接
   ↓
3. 启动心跳
   ↓
4. 监听消息（messageStream）
   ↓
5. 发送消息（send）
   ↓
6. 连接断开自动重连
```

### 数据持久化策略

| 数据类型 | 存储方式 | 使用场景 |
|---------|---------|---------|
| Token | SharedPreferences | 用户认证 |
| 用户信息 | SharedPreferences (JSON) | 用户资料 |
| 聊天记录 | SQLite（需扩展） | 历史消息 |
| 图片/文件 | 本地文件系统 | 媒体缓存 |
| 配置信息 | SharedPreferences | 应用设置 |

---

## 📝 最佳实践

### 1. 错误处理

```dart
try {
  final result = await ApiService().login(
    username: username,
    password: password,
  );
  
  if (result.isSuccess) {
    // 成功处理
    await GlobalController().saveLoginInfo(
      result.data!['token'],
      UserModel.fromJson(result.data!['user']),
    );
  } else {
    // 失败处理
    EasyLoading.showError(result.message);
  }
} catch (e) {
  // 异常处理
  EasyLoading.showError('网络请求失败');
  print('错误: $e');
}
```

### 2. Loading 提示

```dart
// 显示 Loading
EasyLoading.show(status: '加载中...');

// 请求
final result = await ApiService().getUserInfo('123');

// 关闭 Loading
EasyLoading.dismiss();

// 显示成功
EasyLoading.showSuccess('操作成功');

// 显示错误
EasyLoading.showError('操作失败');
```

### 3. 路由导航

```dart
// 跳转页面
Get.to(() => const DetailPage());

// 替换页面
Get.off(() => const HomePage());

// 返回
Get.back();

// 命名路由
Get.toNamed('/demo');

// 传参
Get.toNamed('/detail', arguments: {'id': '123'});

// 获取参数
final args = Get.arguments as Map;
final id = args['id'];
```

### 4. 状态管理

```dart
class ChatController extends GetxController {
  // 响应式变量
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  
  // 加载消息
  Future<void> loadMessages() async {
    isLoading.value = true;
    
    final result = await ApiService().getChatHistory(userId: '123');
    
    if (result.isSuccess) {
      messages.value = result.data!.list;
    }
    
    isLoading.value = false;
  }
  
  // 发送消息
  Future<void> sendMessage(String content) async {
    final result = await ApiService().sendMessage(
      toUserId: '456',
      content: content,
      type: 'text',
    );
    
    if (result.isSuccess) {
      messages.add(Message.fromJson(result.data!));
    }
  }
}
```

---

## 🛠️ 扩展建议

### 1. 添加数据库支持

```yaml
dependencies:
  sqflite: ^2.3.0
```

### 2. 添加国际化

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

### 3. 添加图片选择

已包含 `image_picker`，使用示例：

```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.camera);
if (image != null) {
  print('选择的图片: ${image.path}');
}
```

### 4. 添加缓存图片

已包含 `cached_network_image`，使用示例：

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
);
```

---

## 📱 iOS 原生互通

参见 [NATIVE_BRIDGE_GUIDE.md](./NATIVE_BRIDGE_GUIDE.md)

---

## 🎨 主题配置

在 `main.dart` 中配置主题：

```dart
GetMaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
);
```

---

## 🔐 安全建议

1. ✅ **不要在代码中硬编码敏感信息**
   - API Key、加密密钥应该从服务器获取或使用环境变量
   
2. ✅ **使用 HTTPS**
   - 确保所有网络请求使用 HTTPS

3. ✅ **Token 安全存储**
   - 敏感信息可以使用 `flutter_secure_storage`

4. ✅ **输入验证**
   - 所有用户输入都应该验证

5. ✅ **加密通信**
   - 敏感数据传输时使用加密

---

## 📞 支持

如有问题，请查看：
- [完整文档](./NATIVE_BRIDGE_GUIDE.md)
- [快速参考](./QUICK_REFERENCE.md)
- [架构说明](./ARCHITECTURE.md)

---

**最后更新**: 2025-11-24

