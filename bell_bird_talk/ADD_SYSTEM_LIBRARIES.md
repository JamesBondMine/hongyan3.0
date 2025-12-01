# 添加系统库到 Xcode 项目

## 问题原因

`network_init()` 崩溃是因为缺少必要的系统库：
- `libc++.tbd` - C++ 标准库（**最关键**）
- `libz.tbd` - 压缩库
- `libsqlite3.tbd` - SQLite 数据库
- `libresolv.tbd` - DNS 解析
- `Security.framework` - 安全框架

## 🔧 手动添加步骤

### 1. 打开 Xcode 项目

```bash
cd /Users/lj/hongyan3.0/bell_bird_talk
open ios/Runner.xcworkspace
```

### 2. 在 Xcode 中添加系统库

1. ✅ 点击左侧项目导航中的 **Runner** 项目（蓝色图标）
2. ✅ 选择 **Runner** target（不是项目，是 target）
3. ✅ 点击 **Build Phases** 标签
4. ✅ 展开 **Link Binary With Libraries** 部分
5. ✅ 点击 **+** 按钮

### 3. 添加以下库（逐个添加）

**第一个（最重要）**:
- 搜索 `libc++`
- 选择 `libc++.tbd`
- 点击 **Add**

**第二个**:
- 搜索 `libz`
- 选择 `libz.tbd`
- 点击 **Add**

**第三个**:
- 搜索 `libsqlite3`
- 选择 `libsqlite3.tbd`
- 点击 **Add**

**第四个**:
- 搜索 `libresolv`
- 选择 `libresolv.tbd`
- 点击 **Add**

**第五个**:
- 搜索 `Security`
- 选择 `Security.framework`
- 点击 **Add**

### 4. 保存并重新编译

按 `Cmd + B` 编译项目

### 5. 运行测试

```bash
flutter run --device-id=00008101-00146C9C1E10001E
```

## 🎯 为什么需要这些库

| 库 | 作用 | SDK 使用场景 |
|---|---|---|
| `libc++.tbd` | C++ 标准库 | **必须**，所有 C++ 代码都需要 |
| `libz.tbd` | 数据压缩 | 压缩网络数据 |
| `libsqlite3.tbd` | SQLite 数据库 | 存储消息、联系人等 |
| `libresolv.tbd` | DNS 解析 | 解析服务器域名 |
| `Security.framework` | SSL/TLS | 加密通信 |

## ⚠️ 如果还是崩溃

### 检查库是否添加成功

1. 在 Xcode 中，选择 **Runner** target
2. 查看 **Build Phases** → **Link Binary With Libraries**
3. 确认看到以下库：
   - ✅ libc++.tbd
   - ✅ libz.tbd
   - ✅ libsqlite3.tbd
   - ✅ libresolv.tbd
   - ✅ Security.framework

### 检查崩溃日志

如果添加后还是崩溃，查看 Xcode 控制台的完整崩溃日志：
- 崩溃在哪一行？
- 有没有 "symbol not found" 错误？
- 记录下来并告诉我

## 📝 快速脚本（可选）

如果不想手动添加，可以运行这个命令添加编译标志：

```bash
cd /Users/lj/hongyan3.0/bell_bird_talk/ios
pod install
```

然后在 Xcode 中：
1. 选择 **Runner** target
2. **Build Settings** 标签
3. 搜索 "Other Linker Flags"
4. 添加以下内容（每行一个）:
   ```
   -lc++
   -lz
   -lsqlite3
   -lresolv
   -framework Security
   ```

## 更新时间

2025-12-01 - 添加系统库指导

