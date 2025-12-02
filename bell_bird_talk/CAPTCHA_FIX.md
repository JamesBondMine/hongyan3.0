# CaptchaInfo 字段修复文档

## 🔧 遇到的问题

### 编译错误
```objective-c
Property 'phone' not found on object of type 'CaptchaInfo *'
```

**原因**：`CaptchaInfo` protobuf 只有两个字段，代码中使用了不存在的字段。

---

## 📋 CaptchaInfo 的正确定义

根据 `captcha_pb.proto`（第 18-21 行）：

```protobuf
message CaptchaInfo {
  string captcha_id = 1;  // 验证码ID，最大长度: 100字符
  string answer = 2;      // 验证码答案，最大长度: 20字符
}
```

**只有两个字段**：
- `captcha_id`：验证码的唯一标识
- `answer`：用户输入的验证码答案

**没有的字段**：
- ❌ `captcha_code`
- ❌ `phone`
- ❌ `email`

---

## ✅ 修复内容

### 1. iOS 端（IMSDKAuthManager.mm）

**修改前**：
```objective-c
if (captchaDict[@"captcha_code"]) {
    captcha.captchaCode = captchaDict[@"captcha_code"];  // ❌ 不存在
}
if (captchaDict[@"phone"]) {
    captcha.phone = captchaDict[@"phone"];  // ❌ 不存在
}
```

**修改后**：
```objective-c
// CaptchaInfo 只有两个字段：captcha_id 和 answer
if (captchaDict[@"captcha_id"]) {
    captcha.captchaId = captchaDict[@"captcha_id"];
}
if (captchaDict[@"captcha_code"] || captchaDict[@"answer"]) {
    // Flutter 可能传 captcha_code 或 answer，映射到 protobuf 的 answer 字段
    captcha.answer = captchaDict[@"captcha_code"] ?: captchaDict[@"answer"];
}
```

### 2. Flutter 端（register_page.dart）

#### 2.1 添加状态变量存储 captcha_id
```dart
class _RegisterPageState extends State<RegisterPage> {
  // ... 其他变量
  String? _captchaId; // ✅ 存储验证码 ID
  // ...
}
```

#### 2.2 获取验证码时保存 captcha_id
```dart
void _getVerifyCode() async {
  // ...
  final result = await _nativeService.imGetCaptcha(_phoneController.text);
  
  if (errorCode == 0) {
    // ✅ 保存 captcha_id
    final data = result['data'];
    if (data != null && data.isNotEmpty) {
      try {
        final dataMap = json.decode(data);
        _captchaId = dataMap['captcha_id'];
        print('✅ 获取到 captcha_id: $_captchaId');
      } catch (e) {
        print('⚠️ 解析 captcha_id 失败: $e');
      }
    }
    // ...
  }
}
```

#### 2.3 注册时传递完整的 captcha 对象
**修改前**：
```dart
registerData = {
  'phone': _phoneController.text,
  'captcha': _verifyCodeController.text,  // ❌ 只传了验证码，缺少 captcha_id
  'password': _passwordController.text,
};
```

**修改后**：
```dart
registerData = {
  'phone': _phoneController.text,
  'password': _passwordController.text,
};

// ✅ 添加完整的验证码信息
if (_captchaId != null && _verifyCodeController.text.isNotEmpty) {
  registerData['captcha'] = {
    'captcha_id': _captchaId,
    'answer': _verifyCodeController.text,
  };
}
```

---

## 📊 完整的验证码流程

```
1. 用户输入手机号
   ↓
2. 点击"获取验证码"按钮
   ↓
3. Flutter 调用 imGetCaptcha(phone)
   ↓
4. Native 调用 C++ SDK get_captcha()
   ↓
5. 服务器返回验证码 ID 和发送状态
   ↓
6. Flutter 保存 captcha_id
   ↓
7. 用户收到短信，输入验证码
   ↓
8. 点击"注册"按钮
   ↓
9. Flutter 传递 {captcha_id, answer} 字典
   ↓
10. Native 创建 CaptchaInfo protobuf 对象
    ├─ captchaId = captcha_id
    └─ answer = 验证码答案
   ↓
11. 序列化并发送到服务器
```

---

## 🔍 数据格式对照

### Flutter → iOS
```dart
// Flutter 传递的数据
{
  'phone': '13800138000',
  'password': 'xxx',
  'captcha': {                // ← 注意：这是一个字典
    'captcha_id': 'abc123',
    'answer': '123456'
  }
}
```

### iOS → Protobuf
```objective-c
// 创建 CaptchaInfo 对象
CaptchaInfo *captcha = [[CaptchaInfo alloc] init];
captcha.captchaId = @"abc123";   // string captcha_id = 1
captcha.answer = @"123456";      // string answer = 2

// 序列化为二进制
NSData *data = [captcha data];
```

### Protobuf Binary → C++ SDK
```cpp
// C++ SDK 接收
register_user(callback, data, dataLen, reqId);
// SDK 内部会反序列化 data，得到 CaptchaInfo 对象
```

---

## ✅ 验证清单

- [x] iOS 端移除了不存在的字段（`phone`, `captcha_code`）
- [x] iOS 端正确映射 `answer` 字段
- [x] Flutter 端添加了 `_captchaId` 状态变量
- [x] Flutter 端在获取验证码时保存 `captcha_id`
- [x] Flutter 端注册时传递完整的 captcha 对象
- [x] 添加了 `dart:convert` import

---

## 🧪 测试步骤

1. **运行应用**
   ```bash
   flutter run --device-id=00008101-00146C9C1E10001E
   ```

2. **测试流程**
   - 进入注册页面
   - 输入手机号
   - 点击"获取验证码"
   - 查看日志：应该看到 `✅ 获取到 captcha_id: xxx`
   - 输入收到的验证码
   - 填写密码
   - 点击"立即注册"
   - 查看日志：应该看到正确的 protobuf 序列化

3. **预期日志（Flutter）**
   ```
   ✅ 获取到 captcha_id: abc123
   📝 注册数据: {phone: 13800138000, password: xxx, captcha: {captcha_id: abc123, answer: 123456}}
   ```

4. **预期日志（iOS）**
   ```
   📝 用户注册（字典）: {phone: 13800138000, captcha: {captcha_id: abc123, answer: 123456}, ...}
   📦 Protobuf 序列化成功: XXX bytes
   🔧 调用 C++ register_user...
   ```

---

## 📚 相关文件

- `ios/Runner/IMSDK/proto/captcha_pb.proto` - Protobuf 定义
- `ios/Runner/IMSDK/IMSDKAuthManager.mm` - iOS 验证码处理
- `lib/pages/register_page.dart` - Flutter 注册页面
- `lib/services/native_bridge.dart` - Flutter-Native 桥接

---

## 💡 关键要点

1. **Protobuf 字段必须严格匹配**：不能使用未定义的字段
2. **验证码需要 ID + 答案**：两者缺一不可
3. **数据结构要对齐**：Flutter 字典 → iOS 字典 → Protobuf 对象
4. **ID 需要在获取验证码时保存**：供注册时使用

这样才能保证验证码功能正常工作！🎉

