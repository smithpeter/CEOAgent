#!/bin/bash
# 卸载自动推送 Git hook
# 使用方法: ./scripts/uninstall-auto-push.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_FILE="$PROJECT_ROOT/.git/hooks/post-commit"

echo "🗑️  卸载自动推送 Git Hook..."
echo ""

cd "$PROJECT_ROOT"

if [ ! -f "$HOOK_FILE" ]; then
    echo "⚠️  自动推送 Hook 不存在，无需卸载"
    exit 0
fi

# 检查是否是我们的 hook（通过检查注释）
if grep -q "自动推送到远程仓库" "$HOOK_FILE" 2>/dev/null; then
    rm "$HOOK_FILE"
    echo "✅ 自动推送 Hook 已卸载"
else
    echo "⚠️  检测到自定义的 post-commit hook，未删除"
    echo "   文件位置: $HOOK_FILE"
    echo "   如需删除，请手动操作"
fi

echo ""
