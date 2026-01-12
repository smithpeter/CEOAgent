#!/bin/bash
# 自动生成 SSH key 并配置用于 GitHub Actions 部署
# 使用方法: ./scripts/setup-ssh-for-github.sh

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SSH_KEY_PATH="$HOME/.ssh/ceoagent_deploy"
SERVER_IP="${SERVER_IP:-136.115.199.54}"
SERVER_USER="${SERVER_USER:-root}"

echo -e "${BLUE}🔐 GitHub Actions SSH Key 配置工具${NC}"
echo ""

# 检查是否已存在 key
if [ -f "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}⚠️  SSH key 已存在: $SSH_KEY_PATH${NC}"
    echo "是否要重新生成？(y/N)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "使用现有 key"
    else
        echo "备份现有 key..."
        mv "$SSH_KEY_PATH" "${SSH_KEY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${SSH_KEY_PATH}.pub" "${SSH_KEY_PATH}.pub.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi
fi

# 生成新的 SSH key
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${GREEN}📝 生成新的 SSH key...${NC}"
    ssh-keygen -t ed25519 -C "ceoagent-deploy" -f "$SSH_KEY_PATH" -N ""
    echo -e "${GREEN}✅ SSH key 生成成功${NC}"
fi

# 显示公钥
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}📋 公钥内容（需要添加到服务器）:${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
cat "${SSH_KEY_PATH}.pub"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 询问是否自动添加到服务器
echo "是否要将公钥自动添加到服务器？(Y/n)"
read -r response
if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
    echo -e "${GREEN}🚀 添加公钥到服务器...${NC}"
    
    if ssh-copy-id -i "${SSH_KEY_PATH}.pub" "${SERVER_USER}@${SERVER_IP}" 2>/dev/null; then
        echo -e "${GREEN}✅ 公钥已添加到服务器${NC}"
    else
        echo -e "${YELLOW}⚠️  自动添加失败，请手动添加：${NC}"
        echo ""
        echo "方法 1: 使用 ssh-copy-id"
        echo "  ssh-copy-id -i ${SSH_KEY_PATH}.pub ${SERVER_USER}@${SERVER_IP}"
        echo ""
        echo "方法 2: 手动添加"
        echo "  1. 复制上面的公钥内容"
        echo "  2. SSH 连接到服务器: ssh ${SERVER_USER}@${SERVER_IP}"
        echo "  3. 运行: mkdir -p ~/.ssh && echo '粘贴公钥' >> ~/.ssh/authorized_keys"
    fi
fi

# 测试连接
echo ""
echo -e "${GREEN}🔍 测试 SSH 连接...${NC}"
if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" "echo '连接成功'" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH 连接测试成功${NC}"
else
    echo -e "${RED}❌ SSH 连接测试失败${NC}"
    echo "请检查："
    echo "  1. 服务器 IP 是否正确: ${SERVER_IP}"
    echo "  2. 公钥是否已添加到服务器"
    echo "  3. 服务器是否允许 SSH 连接"
fi

# 显示私钥
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}🔑 私钥内容（用于 GitHub Secrets）:${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}⚠️  这是私钥，请保密！只用于 GitHub Secrets${NC}"
echo ""
cat "$SSH_KEY_PATH"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# macOS 自动复制到剪贴板
if [[ "$OSTYPE" == "darwin"* ]]; then
    cat "$SSH_KEY_PATH" | pbcopy
    echo -e "${GREEN}✅ 私钥已复制到剪贴板（macOS）${NC}"
    echo "可以直接粘贴到 GitHub Secrets"
fi

# 显示配置指南
echo ""
echo -e "${GREEN}📋 下一步操作：${NC}"
echo ""
echo "1. 访问 GitHub Secrets 页面："
echo "   https://github.com/smithpeter/CEOAgent/settings/secrets/actions"
echo ""
echo "2. 添加以下 Secrets："
echo ""
echo "   Secret 名称: SERVER_IP"
echo "   值: ${SERVER_IP}"
echo ""
echo "   Secret 名称: SERVER_USER"
echo "   值: ${SERVER_USER}"
echo ""
echo "   Secret 名称: SERVER_SSH_PORT"
echo "   值: 22"
echo ""
echo "   Secret 名称: SERVER_DEPLOY_PATH"
echo "   值: /opt/ceoagent"
echo ""
echo "   Secret 名称: SERVER_SSH_PRIVATE_KEY"
echo "   值: (复制上面显示的完整私钥内容)"
echo ""
echo "3. 测试自动部署："
echo "   git commit --allow-empty -m '测试自动部署'"
echo "   git push origin main"
echo ""
echo -e "${GREEN}✅ 配置完成！${NC}"
