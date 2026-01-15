#!/bin/bash

# 方法迁移助手脚本
# 用法: ./migrate_methods.sh <handler_name>

HANDLER=$1
OLD_FILE="ios/Runner/AppDelegate_old.swift"

if [ -z "$HANDLER" ]; then
    echo "用法: ./migrate_methods.sh <handler_name>"
    echo "可用的 handler:"
    echo "  - auth"
    echo "  - contact"
    echo "  - conversation"
    echo "  - message"
    echo "  - group"
    echo "  - storage"
    exit 1
fi

echo "🔄 开始迁移 ${HANDLER} 相关方法..."
echo "📁 从 ${OLD_FILE} 提取方法..."

case $HANDLER in
    auth)
        echo "认证相关方法:"
        grep -n "private func im.*\(Register\|Login\|Logout\|Captcha\|Password\|User\|Deactivate\)" $OLD_FILE | head -20
        ;;
    contact)
        echo "联系人相关方法:"
        grep -n "private func im.*\(Contact\|Friend\|Black\|Remark\)" $OLD_FILE | head -20
        ;;
    conversation)
        echo "会话相关方法:"
        grep -n "private func im.*\(Conversation\|Notification\)" $OLD_FILE | head -20
        ;;
    message)
        echo "消息相关方法:"
        grep -n "private func im.*\(Message\|Send\|Pull\)" $OLD_FILE | head -20
        ;;
    group)
        echo "群组相关方法:"
        grep -n "private func im.*Group" $OLD_FILE | head -20
        ;;
    storage)
        echo "存储相关方法:"
        grep -n "private func im.*\(Upload\|Prepare\)" $OLD_FILE | head -20
        ;;
    *)
        echo "❌ 未知的 handler: $HANDLER"
        exit 1
        ;;
esac

echo ""
echo "✅ 方法列表已显示"
echo "📝 请手动复制这些方法到对应的 Handler 文件中"
