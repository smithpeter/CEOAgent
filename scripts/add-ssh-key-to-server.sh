#!/bin/bash
# 使用密码将 SSH 公钥添加到服务器
# 使用方法: ./scripts/add-ssh-key-to-server.sh

set -e

SERVER_IP="136.115.199.54"
SERVER_USER="root"
SSH_KEY_PATH="$HOME/.ssh/ceoagent_deploy.pub"

echo "🔑 将 SSH 公钥添加到服务器..."
echo ""

# 读取公钥
PUBLIC_KEY=$(cat "$SSH_KEY_PATH")

echo "服务器: ${SERVER_USER}@${SERVER_IP}"
echo "公钥文件: ${SSH_KEY_PATH}"
echo ""
echo "⚠️  注意：此脚本需要使用 sshpass，如果没有安装请先安装："
echo "   macOS: brew install hudochenkov/sshpass/sshpass"
echo "   Ubuntu: sudo apt-get install sshpass"
echo ""
read -p "请输入服务器密码（不会显示）: " -s SERVER_PASSWORD
echo ""

# 检查 sshpass 是否安装
if ! command -v sshpass &> /dev/null; then
    echo "❌ 错误: sshpass 未安装"
    echo ""
    echo "安装方法："
    echo "  macOS: brew install hudochenkov/sshpass/sshpass"
    echo "  Ubuntu/Debian: sudo apt-get install sshpass"
    echo ""
    echo "或者手动添加公钥："
    echo "  ssh ${SERVER_USER}@${SERVER_IP}"
    echo "  mkdir -p ~/.ssh"
    echo "  chmod 700 ~/.ssh"
    echo "  echo '${PUBLIC_KEY}' >> ~/.ssh/authorized_keys"
    echo "  chmod 600 ~/.ssh/authorized_keys"
    exit 1
fi

echo ""
echo "正在添加公钥到服务器..."

# 使用 sshpass 执行命令
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_IP}" bash << EOF
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    if ! grep -q "${PUBLIC_KEY}" ~/.ssh/authorized_keys 2>/dev/null; then
        echo "${PUBLIC_KEY}" >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo "✅ 公钥已添加"
    else
        echo "⚠️  公钥已存在"
    fi
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 公钥添加成功！"
    echo ""
    echo "测试连接..."
    ssh -i "$HOME/.ssh/ceoagent_deploy" "${SERVER_USER}@${SERVER_IP}" "echo '✅ SSH 连接成功！'"
else
    echo ""
    echo "❌ 添加失败，请手动添加"
fi
