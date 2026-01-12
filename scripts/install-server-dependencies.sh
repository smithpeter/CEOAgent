#!/bin/bash
# 在服务器上安装 Docker 和 Docker Compose
# 使用方法: ./scripts/install-server-dependencies.sh

set -e

SERVER_IP="${SERVER_IP:-136.115.199.54}"
SERVER_USER="${SERVER_USER:-zouyongming}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/ceoagent_deploy}"

echo "🚀 在服务器上安装 Docker 和 Docker Compose..."
echo "服务器: ${SERVER_USER}@${SERVER_IP}"
echo ""

# 检查 SSH 连接
echo "🔍 检查 SSH 连接..."
if ! ssh -i "$SSH_KEY" "${SERVER_USER}@${SERVER_IP}" "echo 'SSH 连接正常'" &>/dev/null; then
    echo "❌ 无法连接到服务器"
    exit 1
fi
echo "✅ SSH 连接正常"
echo ""

# 安装 Docker
echo "📦 安装 Docker..."
ssh -i "$SSH_KEY" "${SERVER_USER}@${SERVER_IP}" bash << 'EOF'
    # 更新包列表
    sudo apt-get update
    
    # 安装必要的依赖
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加 Docker 官方 GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 添加 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装 Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 将当前用户添加到 docker 组（避免每次都需要 sudo）
    sudo usermod -aG docker $USER
    
    echo "✅ Docker 安装完成"
EOF

# 验证 Docker 安装
echo ""
echo "🔍 验证 Docker 安装..."
ssh -i "$SSH_KEY" "${SERVER_USER}@${SERVER_IP}" "docker --version && docker compose version"

echo ""
echo "✅ 安装完成！"
echo ""
echo "⚠️  注意：如果要将用户添加到 docker 组，可能需要重新登录。"
echo "   或者运行：newgrp docker"
