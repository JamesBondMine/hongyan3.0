#!/bin/bash

# Protobuf to iOS Objective-C 转换脚本
# 用法: ./pb_to_ios.sh <proto_file_path>
# 示例: ./pb_to_ios.sh proto/cmty/cmty_pb.proto
# 示例: ./pb_to_ios.sh proto/app_pb.proto

# 获取脚本所在目录（IMSDK 目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMSDK_DIR="$(dirname "$SCRIPT_DIR")"

# 检查是否提供了 proto 文件路径
if [ $# -eq 0 ]; then
    echo "Usage: $0 <proto_file_path>"
    echo "Example: $0 proto/cmty/cmty_pb.proto"
    echo "Example: $0 proto/app_pb.proto"
    exit 1
fi

# 获取 proto 文件路径（相对于 IMSDK 目录）
PROTO_FILE_PATH="$1"

# 检查 proto 文件是否存在
PROTO_FILE="$IMSDK_DIR/$PROTO_FILE_PATH"
if [ ! -f "$PROTO_FILE" ]; then
    echo "Error: Proto file does not exist: $PROTO_FILE"
    exit 1
fi

# 检查 protoc 是否可用
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed or not in PATH"
    exit 1
fi

# 提取目录和文件名
PROTO_DIR=$(dirname "$PROTO_FILE_PATH")
PROTO_FILE_NAME=$(basename "$PROTO_FILE_PATH")
BASE_NAME=$(basename "$PROTO_FILE_NAME" .proto)

# 确定输出目录
if [ "$PROTO_DIR" = "." ] || [ "$PROTO_DIR" = "proto" ]; then
    # 根目录的 proto 文件，输出到 pbobjc/
    OUTPUT_DIR="$IMSDK_DIR/pbobjc"
else
    # 子目录的 proto 文件，输出到 pbobjc/子目录/
    OUTPUT_DIR="$IMSDK_DIR/pbobjc/${PROTO_DIR#proto/}"
    # 确保输出目录存在
    mkdir -p "$OUTPUT_DIR"
fi

# 生成 Objective-C 文件
echo "Generating iOS Objective-C files from $PROTO_FILE..."
echo "Output directory: $OUTPUT_DIR"

# 切换到 IMSDK 目录，以便正确处理 import 路径
cd "$IMSDK_DIR" || exit 1

protoc --objc_out="$OUTPUT_DIR" \
       --proto_path="proto" \
       "$PROTO_FILE_PATH"

# 检查生成是否成功
if [ $? -eq 0 ]; then
    echo "✅ Successfully generated:"
    echo "   - $OUTPUT_DIR/${BASE_NAME}.pbobjc.h"
    echo "   - $OUTPUT_DIR/${BASE_NAME}.pbobjc.m"
    
    # 自动修复枚举描述符问题
    PBOBJC_M_FILE="$OUTPUT_DIR/${BASE_NAME}.pbobjc.m"
    if [ -f "$PBOBJC_M_FILE" ]; then
        echo "🔧 Fixing enum descriptor initialization issues..."
        
        # 创建临时文件
        TEMP_FILE=$(mktemp)
        
        # 使用 awk 处理文件，修复枚举描述符
        awk '
        /^GPBEnumDescriptor \*.*_EnumDescriptor\(void\) \{/ {
            in_enum = 1
            print
            next
        }
        in_enum && /static _Atomic\(GPBEnumDescriptor\*\) descriptor = nil;/ {
            print
            next
        }
        in_enum && /if \(!descriptor\) \{/ {
            print
            print "    GPB_DEBUG_CHECK_RUNTIME_VERSIONS();"
            next
        }
        in_enum && /enumVerifier:.*IsValidValue\];$/ {
            # 检查是否已经有 flags 参数
            if ($0 !~ /flags:/) {
                sub(/];$/, " flags:GPBEnumDescriptorInitializationFlag_None];");
            }
            print
            next
        }
        in_enum && /^    GPBEnumDescriptor \*expected = nil;/ {
            print
            next
        }
        in_enum && /^\/\/    if \(!atomic_compare_exchange_strong/ {
            print "    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {"
            next
        }
        in_enum && /^\/\/      \[worker release\];/ {
            print "      // ARC 模式下，worker 会自动释放，无需手动调用 release"
            next
        }
        in_enum && /^\/\/    \}/ {
            print "    }"
            next
        }
        in_enum && /^  \}$/ {
            in_enum = 0
            print
            next
        }
        {
            print
        }
        ' "$PBOBJC_M_FILE" > "$TEMP_FILE"
        
        # 替换原文件
        mv "$TEMP_FILE" "$PBOBJC_M_FILE"
        
        echo "✅ Enum descriptors fixed successfully"
    fi
    
    echo ""
    echo "📝 Note: Please review the generated files and test compilation."
else
    echo "❌ Error: Failed to generate Objective-C files"
    exit 1
fi
