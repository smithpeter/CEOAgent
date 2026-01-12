#!/bin/bash
# 测试服务器连接脚本

set -euo pipefail

# 配置变量
SERVER_IP="${SERVER_IP:-136.115.199.54}"
SERVER_USER="${SERVER_USER:-zouyongming}"
SERVER_PORT="${SERVER_PORT:-22}"

# SSH 选项
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${SERVER_PORT}"
SSH_CMD="ssh ${SSH_OPTS} ${SERVER_USER}@${SERVER_IP}"

echo "🔍 测试服务器连接: ${SERVER_USER}@${SERVER_IP}:${SERVER_PORT}"
echo ""

# 测试 SSH 连接
echo "1. 测试 SSH 连接..."
if $SSH_CMD "echo 'SSH 连接成功'" 2>/dev/null; then
    echo "✅ SSH 连接正常"
else
    echo "❌ SSH 连接失败"
    exit 1
fi

echo ""

# 检查系统信息
echo "2. 检查系统信息..."
$SSH_CMD "uname -a"
echo ""

# 检查 Docker
echo "3. 检查 Docker..."
if $SSH_CMD "command -v docker &> /dev/null"; then
    $SSH_CMD "docker --version"
    $SSH_CMD "docker ps"
else
    echo "❌ Docker 未安装"
fi
echo ""

# 检查 Docker Compose
echo "4. 检查 Docker Compose..."
if $SSH_CMD "command -v docker-compose &> /dev/null || docker compose version &> /dev/null"; then
    $SSH_CMD "docker-compose --version || docker compose version"
else
    echo "❌ Docker Compose 未安装"
fi
echo ""

# 检查 Git
echo "5. 检查 Git..."
if $SSH_CMD "command -v git &> /dev/null"; then
    $SSH_CMD "git --version"
else
    echo "❌ Git 未安装"
fi
echo ""

# 检查端口
echo "6. 检查端口占用..."
$SSH_CMD "netstat -tlnp | grep -E ':(8000|5432|6379|8080)' || ss -tlnp | grep -E ':(8000|5432|6379|8080)' || echo '端口检查命令不可用'"
echo ""

# 检查磁盘空间
echo "7. 检查磁盘空间..."
$SSH_CMD "df -h /"
echo ""

echo "✅ 服务器连接测试完成"
