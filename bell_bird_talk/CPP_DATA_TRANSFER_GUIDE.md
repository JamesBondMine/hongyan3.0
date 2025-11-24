# C++ 数据传输实现说明

## 概述

实现了完整的 **C++ → iOS 原生 → Flutter** 数据传输链路，用于模拟高性能数据处理场景。

## 架构流程

```
Flutter (Dart)
    ↓ MethodChannel
iOS Native (Objective-C++)
    ↓ 调用 C++ 类
C++ (DataCPlus)
    ↓ 返回处理结果
iOS Native
    ↓ MethodChannel
Flutter (显示结果)
```

## 文件结构

### 1. C++ 层

#### `DataCPlus.hpp`
定义了 C++ 数据处理类，包含以下方法：
- `generateSimulationData()` - 生成模拟数据
- `processString()` - 字符串加密处理（Caesar cipher）
- `calculateStatistics()` - 数据统计计算
- `simulateDataTransfer()` - 复杂数据传输模拟

#### `DataCPlus.cpp`
实现了所有 C++ 数据处理逻辑：
- JSON 数据生成
- 字符串加密算法
- 统计计算（平均值、最大值、最小值、总和）
- 复杂结构化数据生成

### 2. iOS 原生层

#### `DataTransViewController.h/.mm`
iOS 视图控制器，作为 C++ 和 Flutter 的桥梁：
- `generateSimulationDataFromCPP` - 调用 C++ 生成数据
- `processStringWithCPP` - 调用 C++ 加密字符串
- `calculateStatisticsWithCPP` - 调用 C++ 计算统计
- `simulateDataTransferWithCPP` - 调用 C++ 传输复杂数据

**注意**: 文件扩展名为 `.mm`（Objective-C++），这样才能同时使用 Objective-C 和 C++ 代码。

#### `AppDelegate.swift`
注册了 4 个新的 MethodChannel 方法：
- `generateCppData` - 生成 C++ 数据
- `processCppString` - C++ 字符串处理
- `calculateCppStatistics` - C++ 统计计算
- `simulateCppDataTransfer` - C++ 数据传输

### 3. Flutter 层

#### `native_bridge.dart`
封装了与 iOS 通信的方法：
```dart
Future<Map<String, dynamic>?> generateCppData()
Future<String?> processCppString(String input)
Future<Map<String, dynamic>?> calculateCppStatistics(List<int> numbers)
Future<Map<String, dynamic>?> simulateCppDataTransfer(int userId, int messageCount)
```

#### `native_demo_page.dart`
添加了新的功能区域 "⚡ C++ 数据传输"，包含 4 个测试按钮：
1. **C++ 生成模拟数据** - 展示 C++ 生成的 JSON 数据
2. **C++ 字符串加密** - 展示 Caesar cipher 加密效果
3. **C++ 统计计算** - 计算数组的统计信息
4. **C++ 复杂数据传输** - 模拟用户消息数据传输

## 使用示例

### 1. 生成模拟数据

```dart
final data = await _nativeService.generateCppData();
// 返回: {
//   "timestamp": 1700812345678,
//   "randomString": "aBcD1234Ef",
//   "randomNumber": 567,
//   "status": "success",
//   "source": "CPlusPlus"
// }
```

### 2. 字符串加密

```dart
final encrypted = await _nativeService.processCppString('Hello World');
// 返回: "Khoor Zruog" (Caesar cipher +3)
```

### 3. 统计计算

```dart
final stats = await _nativeService.calculateCppStatistics([10, 20, 30, 40, 50]);
// 返回: {
//   "average": 30.0,
//   "max": 50.0,
//   "min": 10.0,
//   "sum": 150.0,
//   "count": 5.0
// }
```

### 4. 复杂数据传输

```dart
final data = await _nativeService.simulateCppDataTransfer(12345, 5);
// 返回包含用户ID、消息列表、时间戳等结构化数据
```

## 技术要点

### Objective-C++ (.mm 文件)
- 文件扩展名必须是 `.mm` 才能混合使用 OC 和 C++
- 可以在 `.mm` 文件中 `#import` Objective-C 头文件和 `#include` C++ 头文件
- 需要注意 C++ 和 Objective-C 的数据类型转换

### 数据类型转换

#### C++ → Objective-C
```cpp
std::string cppString = "Hello";
NSString *ocString = [NSString stringWithUTF8String:cppString.c_str()];

std::vector<int> cppVector = {1, 2, 3};
NSMutableArray *ocArray = [NSMutableArray array];
for (int num : cppVector) {
    [ocArray addObject:@(num)];
}

std::map<std::string, double> cppMap;
NSMutableDictionary *ocDict = [NSMutableDictionary dictionary];
for (const auto& pair : cppMap) {
    NSString *key = [NSString stringWithUTF8String:pair.first.c_str()];
    ocDict[key] = @(pair.second);
}
```

#### Objective-C → C++
```objc
NSString *ocString = @"Hello";
std::string cppString = [ocString UTF8String];

NSArray *ocArray = @[@1, @2, @3];
std::vector<int> cppVector;
for (NSNumber *num in ocArray) {
    cppVector.push_back([num intValue]);
}
```

### JSON 数据传输
- C++ 使用 `std::ostringstream` 手动构建 JSON 字符串
- iOS 使用 `JSONSerialization` 解析 JSON 字符串为字典
- Flutter 通过 MethodChannel 自动序列化/反序列化

## 应用场景

1. **高性能计算** - 图像处理、音视频编解码、加密算法
2. **跨平台代码复用** - C++ 代码可在 iOS/Android/桌面平台共享
3. **第三方 C++ SDK 集成** - 如游戏引擎、AI 推理引擎
4. **性能优化** - 将性能敏感的代码用 C++ 实现
5. **数据加密传输** - 敏感数据处理

## 调试建议

1. **iOS 端调试**：在 Xcode 中打开项目，可以在 `.mm` 文件中设置断点
2. **查看日志**：在 C++ 代码中使用 `printf()` 或在 iOS 中使用 `NSLog()`
3. **Flutter 端调试**：使用 `print()` 查看返回数据
4. **数据格式验证**：确保 C++ 生成的 JSON 格式正确

## 注意事项

⚠️ **重要提示**：
1. `.mm` 文件必须正确配置在 Xcode 项目中
2. C++ 异常不会自动传递到 Flutter，需要手动处理
3. 注意内存管理，避免 C++ 对象生命周期问题
4. 复杂数据结构建议使用 JSON 格式传输
5. 性能敏感的场景要避免频繁的跨语言调用

## 下一步扩展

- [ ] 添加更复杂的 C++ 算法（如图像处理）
- [ ] 实现异步数据传输（避免阻塞主线程）
- [ ] 添加错误处理和异常传递机制
- [ ] 集成第三方 C++ 库（如 OpenCV、TensorFlow Lite）
- [ ] 实现 C++ 到 Flutter 的回调机制

## 相关文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 项目整体架构
- [NATIVE_BRIDGE_GUIDE.md](./NATIVE_BRIDGE_GUIDE.md) - Flutter 与原生通信指南
- [Apple Objective-C++ 官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html)

