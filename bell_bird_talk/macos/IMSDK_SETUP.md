# macOS IMSDK 设置指南

## 📋 当前状况

### ✅ 已完成
1. **文件复制**: iOS IMSDK 文件夹已成功复制到 `macos/Runner/IMSDK/`
2. **Podfile 更新**: 已添加与 iOS 端相同的依赖和系统库配置
3. **架构检查**: 静态库文件为 arm64 架构，可在 Apple Silicon Mac 上使用
4. **依赖安装**: CocoaPods 依赖安装成功，包含 Protobuf 3.29.5

### ⚠️ 当前警告
1. **配置文件冲突**: CocoaPods 配置与现有项目配置有冲突
2. **云存储 SDK**: 暂时注释掉了云存储 SDK（AliyunOSS, QCloudCOS, AWS），因为它们可能不支持 macOS

### 🔧 已安装的依赖
- `Protobuf 3.29.5` - Protocol Buffers 支持
- 系统库：`-lc++`, `-lz`, `-lsqlite3`, `-lresolv`
- 系统框架：`Security`, `Foundation`, `CoreFoundation`, `SystemConfiguration`, `Cocoa`, `AppKit`

## 🚀 下一步操作

### 1. 解决配置文件警告
需要在 `Runner/Configs/AppInfo.xcconfig` 中包含 CocoaPods 配置：

```xcconfig
// 在 AppInfo.xcconfig 中添加
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
```

### 2. 复制 iOS 端的 Flutter API 处理器
需要将以下文件从 iOS 端复制到 macOS 端：
- `ios/Runner/FlutterAPI/` → `macos/Runner/FlutterAPI/`
- `ios/Runner/AppDelegate.swift` → 适配为 macOS 版本

### 3. 测试编译
```bash
cd macos
open Runner.xcworkspace
# 在 Xcode 中编译项目
```

## 📦 当前项目结构

```
macos/
├── Runner/
│   ├── IMSDK/                    # ✅ 已复制
│   │   ├── manager/              # SDK 管理器
│   │   ├── ios_sdk_la/           # 静态库文件 (arm64)
│   │   ├── pbobjc/               # Protocol Buffers
│   │   └── proto/                # Proto 定义文件
│   ├── AppDelegate.swift         # 需要适配
│   └── MainFlutterWindow.swift
├── Pods/                         # ✅ CocoaPods 依赖
├── Runner.xcworkspace/           # ✅ Xcode 工作空间
└── Podfile                       # ✅ 依赖配置
```

## 🔍 潜在问题和解决方案

### 1. 架构兼容性
- **当前**: 只支持 arm64 (Apple Silicon)
- **解决**: 如需支持 Intel Mac，需要 x86_64 版本的静态库

### 2. API 差异
- **iOS**: UIKit, UIApplication
- **macOS**: AppKit, NSApplication
- **解决**: 需要适配代码中的平台特定 API

### 3. 权限管理
- **macOS**: 可能需要额外的权限配置
- **解决**: 在 `Info.plist` 和 `*.entitlements` 中添加必要权限

### 4. 云存储 SDK
- **当前**: 已注释掉不兼容的 SDK
- **解决**: 寻找 macOS 兼容的替代方案或使用通用 HTTP 客户端

## 📝 配置文件修复

### AppInfo.xcconfig
需要在 `macos/Runner/Configs/AppInfo.xcconfig` 中添加：

```xcconfig
// 包含 CocoaPods 配置
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"

// 或者根据构建配置分别包含
#ifdef DEBUG
  #include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#endif

#ifdef RELEASE
  #include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#endif

#ifdef PROFILE
  #include "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#endif
```

## 🎯 测试清单

- [ ] 解决 CocoaPods 配置警告
- [ ] 复制并适配 Flutter API 处理器
- [ ] 项目编译成功
- [ ] IMSDK 初始化成功
- [ ] 网络连接功能测试
- [ ] 消息功能测试
- [ ] 在 Apple Silicon Mac 上测试
- [ ] 在 Intel Mac 上测试（如需要）

## 🚨 重要提醒

1. **开发环境**: 建议在 Apple Silicon Mac 上开发
2. **静态库**: 当前只支持 arm64，Intel Mac 需要额外处理
3. **云存储**: 需要单独处理 macOS 兼容的存储 SDK
4. **权限**: macOS 应用可能需要额外的系统权限

---

**更新时间**: 2026-01-21
**状态**: Podfile 配置完成，CocoaPods 安装成功，等待进一步适配