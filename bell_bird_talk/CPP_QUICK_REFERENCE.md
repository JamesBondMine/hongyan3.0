# C++ 数据传输快速参考

## 🎯 一句话总结
**Flutter 通过 MethodChannel 调用 iOS 原生 Objective-C++，再调用 C++ 代码进行高性能数据处理。**

---

## 📂 文件结构

```
bell_bird_talk/
│
├── 📱 Flutter 层
│   ├── lib/pages/native_demo_page.dart         👉 UI 界面 + 按钮
│   └── lib/services/native_bridge.dart         👉 封装 MethodChannel 调用
│
├── 🍎 iOS 原生层
│   ├── ios/Runner/AppDelegate.swift            👉 注册 MethodChannel 方法
│   └── ios/Runner/DataTrans/
│       ├── DataTransViewController.h           👉 OC 头文件
│       └── DataTransViewController.mm          👉 OC++ 实现（调用 C++）
│
├── ⚡ C++ 层
│   └── ios/Runner/DataTrans/
│       ├── DataCPlus.hpp                       👉 C++ 头文件
│       └── DataCPlus.cpp                       👉 C++ 实现
│
└── 📚 文档
    ├── CPP_DATA_TRANSFER_GUIDE.md              👉 完整实现指南
    ├── CPP_TRANSFER_TEST.md                    👉 测试指南
    ├── CPP_IMPLEMENTATION_SUMMARY.md           👉 实现总结
    └── CPP_QUICK_REFERENCE.md                  👉 本文件
```

---

## 🔄 调用流程

```
Flutter 按钮点击
    ↓
_nativeService.generateCppData()
    ↓ (MethodChannel)
AppDelegate.swift → handleMethodCall("generateCppData")
    ↓
DataTransViewController.generateSimulationDataFromCPP()
    ↓
C++ DataCPlus.generateSimulationData()
    ↓
返回 JSON 字符串
    ↓
转换为 NSDictionary
    ↓ (MethodChannel)
返回到 Flutter
    ↓
显示在界面上
```

---

## 🎨 4 个核心功能

| 功能 | Flutter 方法 | iOS 方法 | C++ 方法 |
|------|-------------|----------|----------|
| 🎲 生成数据 | `generateCppData()` | `generateCppData` | `generateSimulationData()` |
| 🔐 字符串加密 | `processCppString()` | `processCppString` | `processString()` |
| 📊 统计计算 | `calculateCppStatistics()` | `calculateCppStatistics` | `calculateStatistics()` |
| 📦 复杂传输 | `simulateCppDataTransfer()` | `simulateCppDataTransfer` | `simulateDataTransfer()` |

---

## 💻 代码速查

### Flutter 调用
```dart
// 在 native_demo_page.dart 中
final result = await _nativeService.generateCppData();
```

### iOS 注册
```swift
// 在 AppDelegate.swift 的 handleMethodCall 中
case "generateCppData":
    generateCppData(result: result)
```

### iOS 调用 C++
```objc
// 在 DataTransViewController.mm 中
+ (NSString *)generateSimulationDataFromCPP {
    DataCPlus dataCPlus;
    std::string result = dataCPlus.generateSimulationData();
    return [NSString stringWithUTF8String:result.c_str()];
}
```

### C++ 实现
```cpp
// 在 DataCPlus.cpp 中
std::string DataCPlus::generateSimulationData() {
    std::ostringstream oss;
    oss << "{"
        << "\"timestamp\":" << getCurrentTimestamp() << ","
        << "\"randomString\":\"" << generateRandomString(10) << "\""
        << "}";
    return oss.str();
}
```

---

## 🔑 关键知识点

### 1. 文件扩展名
- `.m` = Objective-C
- `.mm` = Objective-C++ (可以混用 OC 和 C++)
- ⚠️ **必须使用 .mm 才能调用 C++ 代码！**

### 2. 数据类型转换

#### C++ → Objective-C
```objc
// 字符串
std::string cppStr = "Hello";
NSString *ocStr = [NSString stringWithUTF8String:cppStr.c_str()];

// 数字
int cppNum = 42;
NSNumber *ocNum = @(cppNum);

// 数组
std::vector<int> cppVec = {1, 2, 3};
NSMutableArray *ocArr = [NSMutableArray array];
for (int num : cppVec) {
    [ocArr addObject:@(num)];
}

// 字典
std::map<std::string, double> cppMap;
NSMutableDictionary *ocDict = [NSMutableDictionary dictionary];
for (const auto& pair : cppMap) {
    ocDict[[NSString stringWithUTF8String:pair.first.c_str()]] = @(pair.second);
}
```

#### Objective-C → C++
```cpp
// 字符串
NSString *ocStr = @"Hello";
std::string cppStr = [ocStr UTF8String];

// 数字
NSNumber *ocNum = @42;
int cppNum = [ocNum intValue];

// 数组
NSArray *ocArr = @[@1, @2, @3];
std::vector<int> cppVec;
for (NSNumber *num in ocArr) {
    cppVec.push_back([num intValue]);
}
```

### 3. JSON 传输
```cpp
// C++ 生成 JSON 字符串
std::ostringstream oss;
oss << "{\"key\":\"value\"}";
return oss.str();
```

```swift
// iOS 解析 JSON
if let data = jsonString.data(using: .utf8),
   let json = try? JSONSerialization.jsonObject(with: data) {
    result(json)  // 自动传回 Flutter
}
```

---

## 🧪 测试步骤

1. **构建项目**
```bash
flutter clean
cd ios && pod install && cd ..
flutter run -d [设备]
```

2. **打开测试页面**
   - 点击首页的 "原生功能演示"
   - 找到 "⚡ C++ 数据传输" 区域

3. **依次点击 4 个按钮**
   - C++ 生成模拟数据 ✓
   - C++ 字符串加密 ✓
   - C++ 统计计算 ✓
   - C++ 复杂数据传输 ✓

4. **验证结果**
   - 检查显示的数据是否符合预期
   - 确认没有报错

---

## 🐛 常见问题

### ❌ "Undefined symbols for architecture"
**原因**: 文件扩展名不是 `.mm`  
**解决**: 确认 `DataTransViewController.m` 已改为 `.mm`

### ❌ "MissingPluginException"
**原因**: MethodChannel 未注册  
**解决**: 检查 `AppDelegate.swift` 中的 `case` 语句

### ❌ JSON 解析失败
**原因**: JSON 格式错误  
**解决**: 检查 C++ 生成的字符串格式

### ❌ 应用崩溃
**原因**: C++ 内存错误  
**解决**: 在 Xcode 中调试，检查空指针和数组越界

---

## 📖 延伸阅读

| 文档 | 内容 | 大小 |
|------|------|------|
| [CPP_DATA_TRANSFER_GUIDE.md](./CPP_DATA_TRANSFER_GUIDE.md) | 完整实现指南 | 6 KB |
| [CPP_TRANSFER_TEST.md](./CPP_TRANSFER_TEST.md) | 详细测试步骤 | 5.7 KB |
| [CPP_IMPLEMENTATION_SUMMARY.md](./CPP_IMPLEMENTATION_SUMMARY.md) | 实现总结 | 8 KB |

---

## 🚀 快速上手命令

```bash
# 1. 清理并构建
flutter clean && flutter pub get

# 2. iOS 依赖安装
cd ios && pod install && cd ..

# 3. 运行应用
flutter run

# 4. 如果遇到问题，完全重新构建
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

---

## 💡 提示

- ✅ C++ 代码适合处理计算密集型任务
- ✅ 使用 JSON 格式传输复杂数据
- ✅ 在 Xcode 中调试 iOS/C++ 代码
- ✅ 添加日志帮助追踪数据流
- ⚠️ 注意内存管理，避免泄漏
- ⚠️ 大数据传输考虑异步处理

---

**最后更新**: 2025-11-24  
**版本**: 1.0.0

