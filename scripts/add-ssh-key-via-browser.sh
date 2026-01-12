#!/bin/bash
# 生成通过 Browser SSH 添加公钥的命令
# 使用方法：运行此脚本，复制输出的命令到 Browser SSH 执行

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy"

cat << 'EOF'
═══════════════════════════════════════════════════════════════
📋 在 Browser SSH 中执行的命令（复制并执行）
═══════════════════════════════════════════════════════════════

请在 GCP Console 的 Browser SSH 终端中运行以下命令：

───────────────────────────────────────────────────────────────

mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo "✅ SSH 公钥已添加！" && cat ~/.ssh/authorized_keys | grep ceoagent-deploy

───────────────────────────────────────────────────────────────

或者分步执行：

1. mkdir -p ~/.ssh
2. chmod 700 ~/.ssh
3. echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy" >> ~/.ssh/authorized_keys
4. chmod 600 ~/.ssh/authorized_keys
5. cat ~/.ssh/authorized_keys | grep ceoagent-deploy

═══════════════════════════════════════════════════════════════
✅ 执行完成后，退出 Browser SSH，然后测试连接：
═══════════════════════════════════════════════════════════════

ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "echo '连接成功'"

═══════════════════════════════════════════════════════════════
EOF
