#!/bin/bash
# 安装自动推送 Git hook
# 使用方法: ./scripts/install-auto-push.sh

set -e

HOOK_FILE=".git/hooks/post-commit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 安装自动推送 Git Hook..."
echo ""

cd "$PROJECT_ROOT"

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 错误: 当前目录不是 Git 仓库"
    exit 1
fi

# 确保 hooks 目录存在
mkdir -p .git/hooks

# 创建 post-commit hook
cat > "$HOOK_FILE" << 'HOOK_EOF'
#!/bin/bash
# Git post-commit hook: 自动推送到远程仓库
# 每次 commit 后自动执行 git push

# 获取当前分支名
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

# 如果不在任何分支上（比如 detached HEAD），则退出
if [ -z "$BRANCH" ]; then
    exit 0
fi

# 检查是否有远程仓库配置
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "⚠️  未配置远程仓库，跳过自动推送"
    exit 0
fi

# 检查是否设置了 SKIP_AUTO_PUSH 环境变量（用于临时禁用自动推送）
if [ "$SKIP_AUTO_PUSH" = "true" ]; then
    echo "⏭️  跳过自动推送（SKIP_AUTO_PUSH=true）"
    exit 0
fi

# 显示推送信息
echo ""
echo "🚀 自动推送到远程仓库..."
echo "   分支: $BRANCH"
echo "   远程: origin"
echo ""

# 执行推送
if git push origin "$BRANCH" 2>&1 | tee /tmp/git-auto-push.log | grep -v "^$" | head -20; then
    # 检查推送是否成功
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ 自动推送成功"
    else
        echo ""
        echo "❌ 自动推送失败，请手动运行: git push"
        exit 1
    fi
else
    # 如果 git push 没有输出（可能是已经是最新的），也认为成功
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ 远程仓库已是最新"
    else
        echo ""
        echo "❌ 自动推送失败，请手动运行: git push"
        exit 1
    fi
fi

echo ""
HOOK_EOF

chmod +x "$HOOK_FILE"

echo "✅ 自动推送 Hook 已安装: $HOOK_FILE"
echo ""
echo "📋 使用说明："
echo "   - 每次运行 'git commit' 后会自动推送代码"
echo "   - 如果想临时跳过自动推送，设置环境变量：SKIP_AUTO_PUSH=true git commit -m '...'"
echo "   - 如果推送失败，会提示你手动运行 git push"
echo ""
