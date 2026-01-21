#!/bin/bash

# 修复 IMSDK Protobuf 文件的 ARC 问题
# 为所有 .pbobjc.m 文件添加 -fno-objc-arc 编译标志

echo "🔧 修复 IMSDK Protobuf 文件的 ARC 问题..."

PROJECT_FILE="Runner.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ 项目文件不存在: $PROJECT_FILE"
    exit 1
fi

# 备份原始项目文件
cp "$PROJECT_FILE" "$PROJECT_FILE.arc_backup"
echo "📋 已备份项目文件: $PROJECT_FILE.arc_backup"

# 查找所有 .pbobjc.m 文件的引用并添加 -fno-objc-arc 标志
# 这个脚本会在每个 .pbobjc.m 文件的编译设置中添加 COMPILER_FLAGS = "-fno-objc-arc"

python3 << 'EOF'
import re
import sys

# 读取项目文件
with open('Runner.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 查找所有 .pbobjc.m 文件的 PBXBuildFile 条目
# 格式类似: 
# 		ABC123DEF456 /* SomePb.pbobjc.m in Sources */ = {isa = PBXBuildFile; fileRef = DEF456ABC123 /* SomePb.pbobjc.m */; };

# 找到所有 .pbobjc.m 文件的 PBXBuildFile ID
pbobjc_build_files = []
lines = content.split('\n')

for i, line in enumerate(lines):
    if '.pbobjc.m in Sources' in line and 'PBXBuildFile' in line:
        # 提取 build file ID
        match = re.match(r'\s*([A-F0-9]+)\s*/\*.*\.pbobjc\.m in Sources.*', line)
        if match:
            build_file_id = match.group(1)
            pbobjc_build_files.append(build_file_id)
            print(f"找到 .pbobjc.m 文件的 build file ID: {build_file_id}")

# 为每个 build file 添加 settings
modified_content = content
for build_file_id in pbobjc_build_files:
    # 查找对应的 PBXBuildFile 条目
    pattern = rf'(\s*{build_file_id}\s*/\*.*\.pbobjc\.m in Sources.*\*/ = {{isa = PBXBuildFile; fileRef = [A-F0-9]+.*?)(}};)'
    
    def replacement(match):
        prefix = match.group(1)
        suffix = match.group(2)
        
        # 检查是否已经有 settings
        if 'settings' in prefix:
            # 如果已经有 settings，在其中添加 COMPILER_FLAGS
            if 'COMPILER_FLAGS' in prefix:
                # 如果已经有 COMPILER_FLAGS，不重复添加
                return match.group(0)
            else:
                # 在现有 settings 中添加 COMPILER_FLAGS
                settings_pattern = r'(settings = {[^}]*)(};)'
                def add_compiler_flags(settings_match):
                    settings_content = settings_match.group(1)
                    settings_end = settings_match.group(2)
                    return f'{settings_content} COMPILER_FLAGS = "-fno-objc-arc"; {settings_end}'
                
                prefix = re.sub(settings_pattern, add_compiler_flags, prefix)
        else:
            # 如果没有 settings，添加整个 settings 块
            prefix = prefix + '; settings = {COMPILER_FLAGS = "-fno-objc-arc"; }'
        
        return prefix + suffix
    
    modified_content = re.sub(pattern, replacement, modified_content, flags=re.DOTALL)

# 写回文件
with open('Runner.xcodeproj/project.pbxproj', 'w') as f:
    f.write(modified_content)

print(f"✅ 已为 {len(pbobjc_build_files)} 个 .pbobjc.m 文件添加 -fno-objc-arc 标志")
EOF

echo "✅ ARC 问题修复完成"
echo "🔄 请重新运行: flutter run -d macos"