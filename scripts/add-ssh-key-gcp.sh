#!/bin/bash
# GCP SSH 密钥添加脚本
# 使用方法: ./scripts/add-ssh-key-gcp.sh [INSTANCE_NAME]

set -e

INSTANCE_NAME="${1:-}"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy"
SSH_USER="${SSH_USER:-root}"
PROJECT_ID="${GCP_PROJECT_ID:-}"

echo "🔑 GCP SSH 密钥添加工具"
echo ""

# 检查 gcloud 是否安装
if ! command -v gcloud &> /dev/null; then
    echo "❌ 错误: gcloud CLI 未安装"
    echo ""
    echo "安装方法："
    echo "  macOS: brew install --cask google-cloud-sdk"
    echo "  或访问: https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "或者使用 GCP Console Web 界面添加："
    echo "  1. 访问: https://console.cloud.google.com/compute/instances"
    echo "  2. 找到 IP 为 136.115.199.54 的实例"
    echo "  3. 点击 EDIT → SSH Keys → Add item"
    echo "  4. 添加: ${SSH_USER}:${PUBLIC_KEY}"
    exit 1
fi

# 如果没有提供实例名称，尝试通过 IP 查找
if [ -z "$INSTANCE_NAME" ]; then
    echo "🔍 通过 IP 地址查找实例..."
    INSTANCE_NAME=$(gcloud compute instances list \
        --filter="networkInterfaces.accessConfigs.natIP=136.115.199.54" \
        --format="value(name)" 2>/dev/null | head -1)
    
    if [ -z "$INSTANCE_NAME" ]; then
        echo "❌ 错误: 无法找到 IP 为 136.115.199.54 的实例"
        echo ""
        echo "请手动指定实例名称："
        echo "  ./scripts/add-ssh-key-gcp.sh INSTANCE_NAME"
        echo ""
        echo "或者列出所有实例："
        echo "  gcloud compute instances list"
        exit 1
    fi
    
    echo "✅ 找到实例: $INSTANCE_NAME"
fi

# 如果没有设置项目，尝试获取当前项目
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
fi

if [ -n "$PROJECT_ID" ]; then
    echo "📁 项目: $PROJECT_ID"
fi

echo "📝 实例: $INSTANCE_NAME"
echo "👤 用户: $SSH_USER"
echo ""

# 确认操作
read -p "是否要继续添加 SSH key？(Y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "操作已取消"
    exit 0
fi

# 添加 SSH key 到实例元数据
echo ""
echo "🚀 正在添加 SSH key 到实例元数据..."

# 获取现有 SSH keys
EXISTING_KEYS=$(gcloud compute instances describe "$INSTANCE_NAME" \
    --format="value(metadata.items[key=ssh-keys].value)" 2>/dev/null || echo "")

# 检查是否已存在
if echo "$EXISTING_KEYS" | grep -q "ceoagent-deploy"; then
    echo "⚠️  此 SSH key 已存在于实例元数据中"
    read -p "是否要重新添加（替换）？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
fi

# 准备新的 SSH key 条目
NEW_KEY_ENTRY="${SSH_USER}:${PUBLIC_KEY}"

# 如果有现有 keys，追加；否则新建
if [ -n "$EXISTING_KEYS" ]; then
    # 移除旧的 ceoagent-deploy key（如果存在）
    UPDATED_KEYS=$(echo "$EXISTING_KEYS" | grep -v "ceoagent-deploy" || echo "")
    # 添加新 key
    FINAL_KEYS=$(echo -e "${UPDATED_KEYS}\n${NEW_KEY_ENTRY}" | grep -v '^$' | tr '\n' '\n')
else
    FINAL_KEYS="$NEW_KEY_ENTRY"
fi

# 更新实例元数据
gcloud compute instances add-metadata "$INSTANCE_NAME" \
    --metadata ssh-keys="$FINAL_KEYS" \
    --format="value(name)" > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ SSH key 已添加到实例元数据"
    echo ""
    echo "⏳ 等待元数据生效（通常需要 10-30 秒）..."
    sleep 5
    
    # 测试连接
    echo ""
    echo "🔍 测试 SSH 连接..."
    if ssh -i ~/.ssh/ceoagent_deploy -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "${SSH_USER}@136.115.199.54" "echo '✅ SSH 连接成功！'" 2>/dev/null; then
        echo "✅ 连接测试成功！"
    else
        echo "⚠️  连接测试失败，可能需要等待更长时间"
        echo "   请稍后手动测试："
        echo "   ssh -i ~/.ssh/ceoagent_deploy ${SSH_USER}@136.115.199.54"
    fi
else
    echo "❌ 添加失败"
    exit 1
fi

echo ""
echo "✅ 完成！"
