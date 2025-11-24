# 🚀 快速开始指南

## 立即运行

```bash
cd /Users/lj/bell_bird_talk
flutter run
```

---

## 📱 登录测试

### 测试账号
- **用户名**: `test`
- **密码**: `123456`

### 登录流程
1. 启动应用（首次会显示登录页）
2. 输入测试账号和密码
3. 可勾选"记住密码"
4. 点击"登录"按钮
5. 登录成功后进入首页

---

## 🎯 主要功能测试

### 1. 自动登录
- **测试步骤**:
  1. 登录成功后关闭应用
  2. 重新启动应用
  3. 应该直接进入首页（不需要再次登录）

### 2. 退出登录
- **测试步骤**:
  1. 在首页点击右上角"设置"图标
  2. 点击"退出登录"
  3. 确认退出
  4. 返回登录页

### 3. 记住密码
- **测试步骤**:
  1. 在登录页勾选"记住密码"
  2. 登录成功
  3. 退出登录
  4. 返回登录页，账号密码自动填充

---

## 🔧 框架功能测试

在首页点击"框架测试"可以测试：
- ✅ HTTP 客户端
- ✅ WebSocket 连接
- ✅ 本地存储
- ✅ 加密工具
- ✅ 文件管理
- ✅ 权限管理
- ✅ 全局状态

---

## 📱 iOS 原生功能测试

在首页点击"原生功能"可以测试：
- ✅ 设备信息获取
- ✅ 本地数据存储
- ✅ 通讯录访问
- ✅ 通知推送
- ✅ 原生弹窗
- ✅ Platform Views

---

## 📂 项目结构

```
lib/
├── main.dart              # 应用入口（自动登录）
├── pages/
│   ├── login_page.dart    # 登录页
│   ├── home_page.dart     # 首页
│   ├── native_demo_page.dart   # 原生演示
│   └── framework_test_page.dart # 框架测试
├── controllers/
│   ├── global_controller.dart  # 全局状态
│   └── login_controller.dart   # 登录逻辑
├── network/               # 网络层
├── services/              # 服务层
├── utils/                 # 工具类
├── models/                # 数据模型
└── config/                # 配置文件
```

---

## 🎨 页面说明

### 登录页
- 精美的渐变背景
- 卡片式表单设计
- 密码显示/隐藏
- 记住密码功能
- 加载动画

### 首页
- 用户信息卡片
- 功能网格（3x2）
- 快速访问列表
- 底部导航栏
- 设置菜单

---

## 🔐 登录状态管理

### 状态保存
登录成功后会保存：
- ✅ Token（用户令牌）
- ✅ 用户信息（完整）
- ✅ 登录状态标识

### 自动登录
- 启动时自动检查本地 Token
- Token 存在 → 直接进入首页
- Token 不存在 → 显示登录页

### 退出登录
- 清除所有本地数据
- 断开 WebSocket 连接
- 返回登录页

---

## 📝 开发指南

### 1. 对接真实接口

修改 `lib/config/constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com';
```

修改 `lib/controllers/login_controller.dart`，取消注释真实接口代码。

### 2. 添加新页面

```dart
// 1. 创建页面文件
class NewPage extends StatelessWidget { ... }

// 2. 在 main.dart 添加路由
getPages: [
  GetPage(name: '/new', page: () => const NewPage()),
],

// 3. 导航到新页面
Get.toNamed('/new');
```

### 3. 使用全局状态

```dart
// 获取控制器
final globalCtrl = Get.find<GlobalController>();

// 监听状态
Obx(() => Text('${globalCtrl.isLoggedIn.value}'));

// 修改状态
globalCtrl.unreadCount.value = 10;
```

---

## 🛠️ 常用命令

```bash
# 运行应用
flutter run

# 安装依赖
flutter pub get

# 清理构建
flutter clean

# 查看设备
flutter devices

# 热重载
r (在运行中按)

# 热重启
R (在运行中按)
```

---

## 📚 完整文档

- [BASE_FRAMEWORK_README.md](./BASE_FRAMEWORK_README.md) - 基础架构
- [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) - 使用教程
- [LOGIN_MODULE_README.md](./LOGIN_MODULE_README.md) - 登录模块
- [NATIVE_BRIDGE_GUIDE.md](./NATIVE_BRIDGE_GUIDE.md) - 原生互通
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - 快速参考

---

## 🎯 下一步

1. ✅ 测试登录功能
2. ✅ 测试自动登录
3. ✅ 测试退出登录
4. 📝 创建聊天页面
5. 📝 对接后端接口
6. 📝 实现实时聊天

---

## 🆘 常见问题

### Q1: 首次运行报错？
```bash
flutter clean
flutter pub get
flutter run
```

### Q2: 登录失败？
检查是否使用测试账号：`test` / `123456`

### Q3: 自动登录不工作？
确保登录成功后关闭应用，而不是退出登录。

### Q4: 如何重置登录状态？
在首页点击"设置" → "退出登录"

---

## 💡 提示

- 🔑 测试账号: `test` / `123456`
- 💾 数据会自动保存到本地
- 🔄 自动登录会检查 Token 有效性
- 🚪 退出登录会清除所有数据
- 🔐 记住密码功能可选

---

## 🎉 开始使用

现在就运行项目试试吧！

```bash
flutter run
```

---

**最后更新**: 2025-11-24

