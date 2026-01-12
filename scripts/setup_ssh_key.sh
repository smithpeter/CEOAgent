#!/bin/bash
# SSH Key 生成和配置脚本（用于 GitHub）

set -e

SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"
GITHUB_EMAIL="${1:-}"

if [ -z "$GITHUB_EMAIL" ]; then
    echo "❌ 错误: 请提供你的 GitHub 邮箱地址"
    echo "使用方法: ./scripts/setup_ssh_key.sh <你的邮箱>"
    echo "示例: ./scripts/setup_ssh_key.sh smithpeter@example.com"
    exit 1
fi

echo "🔑 正在生成 SSH key..."
echo "   邮箱: $GITHUB_EMAIL"
echo "   保存路径: $SSH_KEY_PATH"
echo ""

# 检查 key 是否已存在
if [ -f "$SSH_KEY_PATH" ]; then
    echo "⚠️  SSH key 已存在: $SSH_KEY_PATH"
    echo "是否要覆盖？(y/N)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "❌ 操作已取消"
        exit 0
    fi
fi

# 生成 SSH key
ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N ""

echo ""
echo "✅ SSH key 生成成功！"
echo ""

# 启动 ssh-agent
eval "$(ssh-agent -s)" > /dev/null

# 创建或更新 SSH config
SSH_CONFIG="$HOME/.ssh/config"
if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# 检查是否已有 GitHub 配置
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << EOF

# GitHub
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $SSH_KEY_PATH
EOF
    echo "✅ 已添加 GitHub SSH 配置到 ~/.ssh/config"
fi

# 添加 key 到 ssh-agent
ssh-add --apple-use-keychain "$SSH_KEY_PATH" 2>/dev/null || ssh-add "$SSH_KEY_PATH"

echo ""
echo "📋 下一步操作："
echo ""
echo "1. 复制以下公钥内容："
echo "   -------------------------"
cat "$SSH_KEY_PATH.pub"
echo "   -------------------------"
echo ""
echo "2. 添加到 GitHub："
echo "   - 访问: https://github.com/settings/keys"
echo "   - 点击 'New SSH key'"
echo "   - Title: 填写描述（如：MacBook Pro）"
echo "   - Key: 粘贴上面的公钥内容"
echo "   - 点击 'Add SSH key'"
echo ""
echo "3. 测试连接："
echo "   ssh -T git@github.com"
echo ""
echo "4. 切换项目使用 SSH："
echo "   git remote set-url origin git@github.com:smithpeter/CEOAgent.git"
echo ""
