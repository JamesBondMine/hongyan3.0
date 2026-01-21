#!/bin/bash

# macOS IMSDK ARC 设置恢复脚本
# 恢复 ARC 设置，确保 Protobuf 文件使用 -fno-objc-arc

echo "🔧 恢复 macOS IMSDK ARC 设置..."

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MACOS_DIR="$PROJECT_ROOT/macos"

echo "📁 项目路径: $PROJECT_ROOT"
echo "📁 macOS 路径: $MACOS_DIR"

# 进入 macOS 目录
cd "$MACOS_DIR"

echo "🧹 清理 CocoaPods 缓存..."
pod deintegrate
rm -rf Pods
rm -f Podfile.lock

echo "📦 重新安装 CocoaPods 依赖..."
pod install

echo "✅ ARC 设置恢复完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在 Xcode 中打开 Runner.xcworkspace"
echo "2. 尝试编译项目"
echo "3. 检查是否还有链接错误"
echo ""
echo "🚀 运行命令: flutter run -d macos"