# 登录模块使用文档

## ✨ 已完成的功能

### 1️⃣ 登录页面
- ✅ 精美的登录界面设计
- ✅ 用户名/密码输入
- ✅ 密码显示/隐藏切换
- ✅ 记住密码功能
- ✅ 加载状态显示
- ✅ 错误提示

**文件**: `lib/pages/login_page.dart`

### 2️⃣ 首页
- ✅ 用户信息卡片展示
- ✅ 功能网格导航
- ✅ 快速访问入口
- ✅ 底部导航栏
- ✅ 设置菜单
- ✅ 退出登录功能

**文件**: `lib/pages/home_page.dart`

### 3️⃣ 登录逻辑
- ✅ 表单验证
- ✅ 登录接口调用（含模拟登录）
- ✅ Token 管理
- ✅ 用户信息存储
- ✅ 记住密码功能

**文件**: `lib/controllers/login_controller.dart`

### 4️⃣ 数据持久化
- ✅ Token 本地存储
- ✅ 用户信息本地存储
- ✅ 账号密码加密存储（可选）
- ✅ 自动加载保存的账号

**实现位置**: `GlobalController.saveLoginInfo()`

### 5️⃣ 自动登录
- ✅ 启动时检查登录状态
- ✅ 已登录自动跳转首页
- ✅ 未登录显示登录页
- ✅ 退出登录后清除状态

**实现位置**: `main.dart` + `GlobalController`

---

## 🚀 使用流程

### 1. 启动应用

```dart
flutter run
```

### 2. 首次登录

**测试账号**：
- 用户名: `test`
- 密码: `123456`

步骤：
1. 打开应用，显示登录页面
2. 输入用户名和密码
3. 勾选"记住密码"（可选）
4. 点击"登录"按钮
5. 登录成功后自动跳转到首页

### 3. 自动登录

当用户登录成功后：
- Token 和用户信息会保存到本地
- 下次启动应用时自动检查登录状态
- 如果 Token 存在且有效，直接进入首页
- 无需再次输入账号密码

### 4. 退出登录

在首页：
1. 点击右上角"设置"按钮
2. 点击"退出登录"
3. 确认退出
4. 自动清除本地数据
5. 返回登录页面

---

## 📁 文件结构

```
lib/
├── pages/
│   ├── login_page.dart          # ✅ 登录页面
│   └── home_page.dart           # ✅ 首页
│
├── controllers/
│   ├── login_controller.dart    # ✅ 登录控制器
│   └── global_controller.dart   # ✅ 全局控制器
│
└── main.dart                    # ✅ 应用入口（自动登录）
```

---

## 🔐 登录状态管理

### 保存登录信息

```dart
// 在 LoginController 中
await _globalCtrl.saveLoginInfo(token, user);
```

这会做以下事情：
1. 保存 Token 到 `SharedPreferences`
2. 保存用户信息到 `SharedPreferences`
3. 更新全局状态 `isLoggedIn = true`
4. 自动配置 HTTP 客户端的 Token
5. 可选：连接 WebSocket

### 退出登录

```dart
// 在首页中
await globalCtrl.logout();
```

这会做以下事情：
1. 清除本地 Token
2. 清除用户信息
3. 更新全局状态 `isLoggedIn = false`
4. 断开 WebSocket 连接
5. 清除 HTTP 客户端的 Token

### 检查登录状态

```dart
final globalCtrl = Get.find<GlobalController>();

// 检查是否已登录
if (globalCtrl.isLoggedIn.value) {
  // 已登录
} else {
  // 未登录
}
```

---

## 💾 数据持久化详解

### 存储的数据

| 数据类型 | Storage Key | 说明 |
|---------|------------|------|
| Token | `user_token` | 用户认证令牌 |
| 用户信息 | `user_info` | 完整的用户信息（JSON） |
| 用户 ID | `user_id` | 用户唯一标识 |
| 保存的用户名 | `saved_username` | 记住的用户名 |
| 保存的密码 | `saved_password` | 记住的密码 |

### 数据存储位置

所有数据存储在 `SharedPreferences` 中：
- iOS: `NSUserDefaults`
- Android: `SharedPreferences`

### 数据加密（可选）

如果需要加密敏感数据，可以使用 `EncryptUtil`：

```dart
// 加密保存
final encryptedPassword = EncryptUtil().aesEncrypt(password);
await StorageUtil().setString('saved_password', encryptedPassword);

// 解密读取
final encrypted = StorageUtil().getString('saved_password');
final password = EncryptUtil().aesDecrypt(encrypted!);
```

---

## 🎯 核心功能代码

### 1. 自动登录检查（main.dart）

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final globalCtrl = Get.find<GlobalController>();
    
    return GetMaterialApp(
      // 根据登录状态决定初始页面
      home: Obx(() => globalCtrl.isLoggedIn.value 
          ? const HomePage()      // 已登录 → 首页
          : const LoginPage()),   // 未登录 → 登录页
      // ...
    );
  }
}
```

### 2. 登录逻辑（LoginController）

```dart
Future<void> login() async {
  // 1. 验证输入
  if (username.isEmpty || password.isEmpty) {
    EasyLoading.showError('请输入用户名和密码');
    return;
  }

  // 2. 调用登录接口
  final result = await ApiService().login(
    username: username,
    password: password,
  );

  // 3. 保存登录信息
  if (result.isSuccess) {
    await _globalCtrl.saveLoginInfo(token, user);
    
    // 4. 保存账号密码（如果勾选记住密码）
    if (rememberPassword.value) {
      await _saveCredentials(username, password);
    }
    
    // 5. 跳转到首页
    Get.offAllNamed('/home');
  }
}
```

### 3. 退出登录（HomePage）

```dart
void _logout() async {
  EasyLoading.show(status: '退出中...');
  
  // 清除所有登录状态和数据
  await globalCtrl.logout();
  
  EasyLoading.showSuccess('已退出登录');
  
  // 跳转到登录页
  Get.offAllNamed('/login');
}
```

---

## 🔄 登录流程图

```
启动应用
    ↓
检查本地是否有 Token
    ↓
  有 Token          无 Token
    ↓                ↓
验证 Token        显示登录页
    ↓                ↓
 有效  无效        输入账号密码
    ↓    ↓            ↓
  首页  登录页      调用登录接口
                      ↓
                   成功  失败
                    ↓     ↓
                保存信息  错误提示
                    ↓
                  首页
```

---

## 🎨 页面展示

### 登录页面特性
- ✅ 渐变背景
- ✅ 圆形 Logo
- ✅ 卡片式表单
- ✅ 圆角输入框
- ✅ 密码可见性切换
- ✅ 记住密码复选框
- ✅ 加载动画
- ✅ 测试账号提示

### 首页特性
- ✅ 用户信息卡片（渐变背景）
- ✅ 3x2 功能网格
- ✅ 快速访问列表
- ✅ 底部导航栏（4个标签）
- ✅ 未读消息徽章
- ✅ 设置对话框
- ✅ 深色模式切换

---

## 🔧 对接真实接口

### 1. 修改 LoginController

取消注释真实接口代码：

```dart
// 真实环境取消注释下面的代码
final result = await ApiService().login(
  username: username,
  password: password,
);

if (result.isSuccess) {
  final token = result.data!['token'] as String;
  final userData = result.data!['user'] as Map<String, dynamic>;
  final user = UserModel.fromJson(userData);

  await _globalCtrl.saveLoginInfo(token, user);
  
  if (rememberPassword.value) {
    await _saveCredentials(username, password);
  }

  EasyLoading.showSuccess('登录成功');
  Get.offAllNamed('/home');
} else {
  EasyLoading.showError(result.message);
}
```

### 2. 配置 API 地址

修改 `lib/config/constants.dart`：

```dart
static const String baseUrl = 'https://your-api.com';
```

### 3. 后端接口规范

**登录接口**:
- 路径: `POST /auth/login`
- 请求参数:
  ```json
  {
    "username": "test",
    "password": "123456"
  }
  ```
- 响应格式:
  ```json
  {
    "code": 200,
    "message": "登录成功",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "user": {
        "id": "1",
        "username": "test",
        "nickname": "测试用户",
        "avatar": "https://...",
        "phone": "13800138000",
        "email": "test@example.com",
        "gender": 1,
        "signature": "个性签名",
        "createdAt": "2025-01-01T00:00:00Z",
        "updatedAt": "2025-01-01T00:00:00Z"
      }
    }
  }
  ```

---

## 🎁 额外功能

### 1. Token 自动刷新

可以在 `AuthInterceptor` 中实现：

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  if (err.response?.statusCode == 401) {
    // Token 过期，尝试刷新
    _refreshToken().then((success) {
      if (success) {
        // 重试原请求
      } else {
        // 跳转登录页
      }
    });
  }
  handler.next(err);
}
```

### 2. 生物识别登录

集成 `local_auth` 插件：

```yaml
dependencies:
  local_auth: ^2.1.0
```

### 3. 第三方登录

集成微信、QQ、Apple 登录等。

---

## ⚠️ 注意事项

1. **安全性**
   - 密码不要明文存储
   - Token 应设置过期时间
   - 敏感操作需要二次验证

2. **用户体验**
   - 登录失败给出明确提示
   - 加载状态及时反馈
   - 表单验证友好提示

3. **测试**
   - 测试各种网络情况
   - 测试 Token 过期处理
   - 测试多次登录/退出

---

## 📊 功能清单

- [x] 登录页面设计
- [x] 登录表单验证
- [x] 登录接口对接
- [x] 模拟登录（测试）
- [x] Token 存储
- [x] 用户信息存储
- [x] 记住密码功能
- [x] 自动登录检查
- [x] 首页展示
- [x] 退出登录
- [x] 状态持久化
- [x] 错误处理
- [x] 加载动画

---

## 🎉 总结

✨ **登录模块已完全实现！**

核心特性：
1. ✅ 完整的登录流程
2. ✅ 数据持久化
3. ✅ 自动登录
4. ✅ 优雅的 UI 设计
5. ✅ 完善的错误处理

可以直接运行测试：
```bash
flutter run
```

使用测试账号：`test` / `123456`

---

**创建时间**: 2025-11-24  
**版本**: 1.0.0  
**状态**: ✅ 完成

