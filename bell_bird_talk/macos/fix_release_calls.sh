#!/bin/bash

# 注释掉所有 .pbobjc.m 文件中的 [worker release]; 调用
# 这样可以避免 ARC 错误

echo "🔧 注释掉 Protobuf 文件中的 [worker release]; 调用..."

# 查找所有 .pbobjc.m 文件
find Runner/IMSDK/pbobjc -name "*.pbobjc.m" | while read file; do
    echo "处理文件: $file"
    
    # 备份原文件
    cp "$file" "$file.backup"
    
    # 注释掉 [worker release]; 调用
    sed -i '' 's/\[worker release\];/\/\/ [worker release]; \/\/ 注释掉以避免 ARC 错误/g' "$file"
    
    echo "✅ 已处理: $file"
done

echo "✅ 所有 [worker release]; 调用已注释"
echo "🔄 请重新运行: flutter run -d macos"