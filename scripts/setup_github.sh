#!/bin/bash
# GitHub 仓库设置脚本
# 使用方法: ./scripts/setup_github.sh <github_username> <repository_name>

set -e

GITHUB_USER="${1:-}"
REPO_NAME="${2:-CEOAgent}"

if [ -z "$GITHUB_USER" ]; then
    echo "❌ 错误: 请提供 GitHub 用户名"
    echo "使用方法: ./scripts/setup_github.sh <github_username> [repository_name]"
    echo "示例: ./scripts/setup_github.sh yourusername CEOAgent"
    exit 1
fi

REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo "🚀 设置 GitHub 远程仓库..."
echo "   用户: $GITHUB_USER"
echo "   仓库: $REPO_NAME"
echo "   URL: $REMOTE_URL"
echo ""

# 检查是否已经存在远程仓库
if git remote get-url origin 2>/dev/null; then
    echo "⚠️  检测到已存在的远程仓库，是否要更新？(y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        git remote set-url origin "$REMOTE_URL"
        echo "✅ 远程仓库 URL 已更新"
    else
        echo "❌ 操作已取消"
        exit 0
    fi
else
    git remote add origin "$REMOTE_URL"
    echo "✅ 远程仓库已添加"
fi

echo ""
echo "📋 下一步操作："
echo "   1. 在 GitHub 上创建新仓库: https://github.com/new"
echo "      - 仓库名称: $REPO_NAME"
echo "      - 设置为 Private 或 Public（根据你的需求）"
echo "      - ⚠️  不要初始化 README、.gitignore 或 license（我们已经有了）"
echo ""
echo "   2. 创建仓库后，运行以下命令推送代码："
echo "      git push -u origin main"
echo ""
echo "   或者，如果你想使用 SSH（如果已配置 SSH key）："
echo "      git remote set-url origin git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
echo "      git push -u origin main"
echo ""
