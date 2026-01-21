#!/bin/bash

# 清理 Xcode 项目中的 .proto 文件
# 这些文件不应该被编译，只是用于生成 .pbobjc 文件

echo "🧹 清理 Xcode 项目中的 .proto 文件..."

PROJECT_FILE="Runner.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ 项目文件不存在: $PROJECT_FILE"
    exit 1
fi

# 备份原始项目文件
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "📋 已备份项目文件: $PROJECT_FILE.backup"

# 移除所有 .proto 文件的引用
sed -i '' '/\.proto/d' "$PROJECT_FILE"

echo "✅ 已从 Xcode 项目中移除所有 .proto 文件引用"
echo "🔄 请重新运行: flutter run -d macos"