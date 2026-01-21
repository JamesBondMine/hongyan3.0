#!/bin/bash

# macOS IMSDK Xcode 项目修复脚本
# 修复 Xcode 项目中的配置问题

echo "🔧 修复 macOS Xcode 项目配置..."

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MACOS_DIR="$PROJECT_ROOT/macos"
XCODE_PROJECT="$MACOS_DIR/Runner.xcodeproj/project.pbxproj"

echo "📁 项目路径: $PROJECT_ROOT"
echo "📁 macOS 路径: $MACOS_DIR"
echo "📁 Xcode 项目: $XCODE_PROJECT"

# 检查 Xcode 项目文件是否存在
if [ ! -f "$XCODE_PROJECT" ]; then
    echo "❌ Xcode 项目文件不存在: $XCODE_PROJECT"
    exit 1
fi

echo "📝 备份原始 Xcode 项目文件..."
cp "$XCODE_PROJECT" "$XCODE_PROJECT.backup.$(date +%Y%m%d_%H%M%S)"

echo "🧹 清理 .proto 文件引用..."
# 删除所有 .proto 文件的引用
sed -i '' '/\.proto.*in Sources/d' "$XCODE_PROJECT"
sed -i '' '/\.proto.*fileRef/d' "$XCODE_PROJECT"
sed -i '' '/sourcecode\.protobuf/d' "$XCODE_PROJECT"

echo "🔧 修复构建配置..."
# 确保正确的配置文件被引用
sed -i '' 's/AppInfo\.xcconfig/Debug\.xcconfig/g' "$XCODE_PROJECT"

echo "🧹 清理 Flutter 缓存..."
cd "$PROJECT_ROOT"
flutter clean
flutter pub get

echo "🔄 重新安装 CocoaPods..."
cd "$MACOS_DIR"
pod deintegrate 2>/dev/null || true
rm -rf Pods Podfile.lock
pod install

echo "✅ Xcode 项目修复完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在 Xcode 中打开 Runner.xcworkspace"
echo "2. 检查项目设置中的构建配置"
echo "3. 尝试编译项目"
echo ""
echo "🚀 运行命令: flutter run -d macos"