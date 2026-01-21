#!/bin/bash

# macOS IMSDK 配置脚本
# 用于配置 Xcode 项目以正确链接 IMSDK 静态库

echo "🔧 开始配置 macOS IMSDK..."

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MACOS_DIR="$PROJECT_ROOT/macos"
IMSDK_DIR="$MACOS_DIR/Runner/IMSDK"

echo "📁 项目路径: $PROJECT_ROOT"
echo "📁 macOS 路径: $MACOS_DIR"
echo "📁 IMSDK 路径: $IMSDK_DIR"

# 检查 IMSDK 目录是否存在
if [ ! -d "$IMSDK_DIR" ]; then
    echo "❌ IMSDK 目录不存在: $IMSDK_DIR"
    exit 1
fi

# 检查静态库文件
MAIN_LIB="$IMSDK_DIR/libnet_core.a"
if [ ! -f "$MAIN_LIB" ]; then
    echo "❌ 主静态库不存在: $MAIN_LIB"
    exit 1
fi

echo "✅ IMSDK 文件检查通过"

# 创建 Xcode 配置文件
XCCONFIG_FILE="$MACOS_DIR/Runner/Configs/IMSDK.xcconfig"
echo "📝 创建 Xcode 配置文件: $XCCONFIG_FILE"

mkdir -p "$(dirname "$XCCONFIG_FILE")"

cat > "$XCCONFIG_FILE" << 'EOF'
// IMSDK 配置文件
// 用于配置静态库链接和头文件搜索路径

// 头文件搜索路径
HEADER_SEARCH_PATHS = $(inherited) "$(SRCROOT)/Runner/IMSDK" "$(SRCROOT)/Runner/IMSDK/manager" "$(SRCROOT)/Runner/IMSDK/pbobjc"

// 库搜索路径
LIBRARY_SEARCH_PATHS = $(inherited) "$(SRCROOT)/Runner/IMSDK" "$(SRCROOT)/Runner/IMSDK/ios_sdk_la"

// 链接的静态库
OTHER_LDFLAGS = $(inherited) -lnet_core -lprotobuf -lprotobuf-lite -lcrypto -lssl -lcurl -lsqlcipher -labsl_base -labsl_strings -labsl_synchronization -labsl_time -labsl_status -labsl_statusor -labsl_cord -labsl_hash -labsl_raw_hash_set -labsl_city -labsl_int128 -labsl_low_level_hash -labsl_throw_delegate -labsl_bad_any_cast_impl -labsl_bad_optional_access -labsl_bad_variant_access -labsl_civil_time -labsl_time_zone -labsl_debugging_internal -labsl_demangle_internal -labsl_examine_stack -labsl_failure_signal_handler -labsl_leak_check -labsl_stacktrace -labsl_symbolize -labsl_malloc_internal -labsl_raw_logging_internal -labsl_spinlock_wait -labsl_exponential_biased -labsl_periodic_sampler -labsl_random_distributions -labsl_random_seed_sequences -labsl_random_internal_platform -labsl_random_internal_randen -labsl_random_internal_randen_hwaes -labsl_random_internal_randen_hwaes_impl -labsl_random_internal_randen_slow -labsl_random_internal_seed_material -labsl_random_internal_pool_urbg -labsl_random_seed_gen_exception -labsl_crc32c -labsl_crc_cord_state -labsl_crc_cpu_detect -labsl_crc_internal -labsl_str_format_internal -labsl_string_view -labsl_strings_internal -labsl_cord_internal -labsl_cordz_functions -labsl_cordz_handle -labsl_cordz_info -labsl_cordz_sample_token -labsl_hashtablez_sampler -labsl_kernel_timeout_internal -labsl_graphcycles_internal -labsl_log_severity -labsl_log_entry -labsl_log_flags -labsl_log_globals -labsl_log_initialize -labsl_log_internal_check_op -labsl_log_internal_conditions -labsl_log_internal_format -labsl_log_internal_globals -labsl_log_internal_log_sink_set -labsl_log_internal_message -labsl_log_internal_nullguard -labsl_log_internal_proto -labsl_log_sink -labsl_flags_commandlineflag -labsl_flags_commandlineflag_internal -labsl_flags_config -labsl_flags_internal -labsl_flags_marshalling -labsl_flags_parse -labsl_flags_private_handle_accessor -labsl_flags_program_name -labsl_flags_reflection -labsl_flags_usage -labsl_flags_usage_internal -labsl_scoped_set_env -labsl_strerror -labsl_die_if_null -labsl_log_internal_fnmatch -labsl_vlog_config_internal -labsl_random_internal_distribution_test_util -lbreakpad -lupb -lutf8_range -lutf8_validity -lprotoc

// 系统框架
OTHER_LDFLAGS = $(inherited) -framework Foundation -framework CoreFoundation -framework Security -framework SystemConfiguration -framework Cocoa -framework AppKit

// C++ 标准库和系统库
OTHER_LDFLAGS = $(inherited) -lc++ -lz -lsqlite3 -lresolv

// 编译器标志
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) GOOGLE_PROTOBUF_NO_RTTI=1

// C++ 标准
CLANG_CXX_LANGUAGE_STANDARD = c++17
CLANG_CXX_LIBRARY = libc++
EOF

echo "✅ Xcode 配置文件创建完成"

# 检查是否需要更新 AppInfo.xcconfig
APPINFO_CONFIG="$MACOS_DIR/Runner/Configs/AppInfo.xcconfig"
if [ -f "$APPINFO_CONFIG" ]; then
    if ! grep -q "IMSDK.xcconfig" "$APPINFO_CONFIG"; then
        echo "📝 更新 AppInfo.xcconfig 以包含 IMSDK 配置"
        echo "" >> "$APPINFO_CONFIG"
        echo "// 包含 IMSDK 配置" >> "$APPINFO_CONFIG"
        echo "#include \"IMSDK.xcconfig\"" >> "$APPINFO_CONFIG"
        echo "✅ AppInfo.xcconfig 更新完成"
    else
        echo "✅ AppInfo.xcconfig 已包含 IMSDK 配置"
    fi
else
    echo "⚠️ AppInfo.xcconfig 不存在，创建新文件"
    cat > "$APPINFO_CONFIG" << 'EOF'
// App 信息配置
#include "IMSDK.xcconfig"
EOF
    echo "✅ AppInfo.xcconfig 创建完成"
fi

echo ""
echo "🎉 macOS IMSDK 配置完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在 Xcode 中打开 Runner.xcworkspace"
echo "2. 选择 Runner 项目 -> Build Settings"
echo "3. 确认配置文件已正确应用"
echo "4. 尝试编译项目"
echo ""
echo "🚀 运行命令: flutter run -d macos"