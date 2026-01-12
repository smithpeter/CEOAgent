# GitHub Secrets 配置指南

本指南将详细说明如何配置 GitHub Secrets，以便实现自动部署到服务器。

## 📋 目录

- [访问 Secrets 设置页面](#访问-secrets-设置页面)
- [配置步骤](#配置步骤)
- [每个 Secret 的详细说明](#每个-secret-的详细说明)
- [SSH Key 生成和配置](#ssh-key-生成和配置)
- [验证配置](#验证配置)

## 🔐 访问 Secrets 设置页面

### 方法 1: 通过仓库设置

1. 访问你的 GitHub 仓库：https://github.com/smithpeter/CEOAgent
2. 点击 **Settings**（设置）标签
3. 在左侧菜单中找到 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**（新建仓库密钥）

### 方法 2: 直接链接

直接访问：https://github.com/smithpeter/CEOAgent/settings/secrets/actions

## 📝 配置步骤

### 步骤 1: 准备 SSH Key（最重要）

首先需要生成 SSH key 用于服务器认证：

```bash
# 1. 生成 SSH key（如果没有的话）
ssh-keygen -t ed25519 -C "ceoagent-deploy" -f ~/.ssh/ceoagent_deploy

# 按 Enter 两次（不设置密码，或者设置密码后记住）
```

**重要提示**：
- 如果询问密码，可以按 Enter 跳过（不设置密码）
- 如果设置了密码，需要配置 `ssh-agent`（后面会说明）

### 步骤 2: 将公钥添加到服务器

```bash
# 方法 1: 使用 ssh-copy-id（推荐）
ssh-copy-id -i ~/.ssh/ceoagent_deploy.pub root@136.115.199.54

# 如果 ssh-copy-id 不可用，使用方法 2
```

```bash
# 方法 2: 手动添加
# 先查看公钥内容
cat ~/.ssh/ceoagent_deploy.pub

# SSH 连接到服务器，添加公钥
ssh root@136.115.199.54 "mkdir -p ~/.ssh && echo '这里粘贴上面的公钥内容' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### 步骤 3: 测试 SSH 连接

```bash
# 测试连接（应该不需要输入密码）
ssh -i ~/.ssh/ceoagent_deploy root@136.115.199.54 "echo 'SSH key 配置成功'"
```

如果成功，会显示 "SSH key 配置成功"

### 步骤 4: 获取 SSH 私钥内容

```bash
# 查看私钥内容（这是你要复制到 GitHub Secrets 的内容）
cat ~/.ssh/ceoagent_deploy
```

**重要提示**：
- 私钥内容应该以 `-----BEGIN OPENSSH PRIVATE KEY-----` 开头
- 以 `-----END OPENSSH PRIVATE KEY-----` 结尾
- **不要泄露这个私钥给任何人！**

## 🔑 每个 Secret 的详细说明

### 1. SERVER_IP

**Secret 名称**：`SERVER_IP`

**值**：
```
136.115.199.54
```

**格式说明**：
- 纯文本，就是服务器 IP 地址
- 不要加引号，不要加空格
- 直接填写：`136.115.199.54`

---

### 2. SERVER_USER

**Secret 名称**：`SERVER_USER`

**值**：
```
root
```

**格式说明**：
- 纯文本，SSH 用户名
- 默认是 `root`，如果服务器使用其他用户，填写实际用户名

---

### 3. SERVER_SSH_PORT

**Secret 名称**：`SERVER_SSH_PORT`

**值**：
```
22
```

**格式说明**：
- 纯文本数字，SSH 端口
- 默认是 `22`，如果服务器使用其他端口，填写实际端口号

---

### 4. SERVER_DEPLOY_PATH

**Secret 名称**：`SERVER_DEPLOY_PATH`

**值**：
```
/opt/ceoagent
```

**格式说明**：
- 纯文本路径，代码部署到的目录
- 默认是 `/opt/ceoagent`，可以修改为其他路径

---

### 5. SERVER_SSH_PRIVATE_KEY（最重要）

**Secret 名称**：`SERVER_SSH_PRIVATE_KEY`

**值**（完整示例）：
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAQEAy8x7J4K1q9Z2H3mN8P5Q6R7S8T9U0V1W2X3Y4Z5A6B7C8D9E0F1G
2H3I4J5K6L7M8N9O0P1Q2R3S4T5U6V7W8X9Y0Z1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P
7Q8R9S0T1U2V3W4X5Y6Z7A8B9C0D1E2F3G4H5I6J7K8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y
2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E4E5F6G
7H8I9J0K1L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6A7B8C9D0E1F2G3H4I5J6K7L8M9N0O1P
2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V4W5X6Y
7Z8A9B0C1D2E3F4G5H6I7J8K9L0M1N2O3P4Q5R6S7T8U9V0W1X2Y3Z4A5B6C7D8E9F0G1H
2I3J4K5L6M7N8O9P0Q1R2S3T4U5V6W7X8Y9Z0A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q
7R8S9T0U1V2W3X4Y5Z6A7B8C9D0E1F2G3H4I5J6K7L8M9N0O1P2Q3R4S5T6U7V8W9X0Y1Z
2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V4W5X6Y7Z8A9B0C1D2E3F4G5H6I
7J8K9L0M1N2O3P4Q5R6S7T8U9V0W1X2Y3Z4A5B6C7D8E9F0G1H2I3J4K5L6M7N8O9P0Q1R2
-----END OPENSSH PRIVATE KEY-----
```

**格式说明**：
- 这是完整的私钥内容
- 包含开头的 `-----BEGIN OPENSSH PRIVATE KEY-----`
- 包含结尾的 `-----END OPENSSH PRIVATE KEY-----`
- 包括中间的所有行
- **不要把私钥分成多行输入，要完整复制**

**如何获取**：
```bash
# 在终端运行，复制所有输出
cat ~/.ssh/ceoagent_deploy
```

**完整操作步骤**：
1. 打开终端
2. 运行：`cat ~/.ssh/ceoagent_deploy`
3. 复制**所有**显示的内容（包括 BEGIN 和 END 行）
4. 粘贴到 GitHub Secrets 的值字段

## 📸 配置示例（可视化步骤）

### 添加单个 Secret 的步骤

1. **点击 "New repository secret"**
   ```
   [Repository settings] → [Secrets and variables] → [Actions] → [New repository secret]
   ```

2. **填写 Secret**
   - **Name**: 输入 Secret 名称（如 `SERVER_IP`）
   - **Secret**: 输入对应的值（如 `136.115.199.54`）
   - **点击 "Add secret"**

3. **重复以上步骤，添加所有 Secrets**

## ✅ 完整配置清单

按照以下顺序添加所有 Secrets：

| 序号 | Secret 名称 | 值 | 必填 |
|------|------------|-----|------|
| 1 | `SERVER_IP` | `136.115.199.54` | ✅ |
| 2 | `SERVER_USER` | `root` | ✅ |
| 3 | `SERVER_SSH_PORT` | `22` | ✅ |
| 4 | `SERVER_DEPLOY_PATH` | `/opt/ceoagent` | ✅ |
| 5 | `SERVER_SSH_PRIVATE_KEY` | (SSH 私钥完整内容) | ✅ |

## 🔍 验证配置

### 方法 1: 通过 GitHub Actions 验证

1. 推送一个小的更改到仓库：
   ```bash
   git commit --allow-empty -m "测试自动部署"
   git push origin main
   ```

2. 访问 Actions 页面：
   https://github.com/smithpeter/CEOAgent/actions

3. 查看部署任务：
   - 如果配置正确，会看到 "Deploy to Server" 任务
   - 如果失败，查看日志找到错误原因

### 方法 2: 本地测试

```bash
# 测试服务器连接脚本
./scripts/test-server-connection.sh

# 如果连接成功，可以手动部署测试
./scripts/deploy-server.sh main production
```

## ❓ 常见问题

### Q1: SSH 私钥格式不对？

**问题**：GitHub Actions 报错 "Permission denied (publickey)"

**解决方案**：
1. 确保私钥完整（包括 BEGIN 和 END 行）
2. 确保没有多余的空格或换行
3. 重新复制私钥内容：
   ```bash
   cat ~/.ssh/ceoagent_deploy | pbcopy  # macOS
   # 或者手动复制所有输出
   ```

### Q2: 如何查看私钥内容？

```bash
# 显示私钥
cat ~/.ssh/ceoagent_deploy

# macOS: 直接复制到剪贴板
cat ~/.ssh/ceoagent_deploy | pbcopy

# Linux: 复制到剪贴板（需要 xclip）
cat ~/.ssh/ceoagent_deploy | xclip -selection clipboard
```

### Q3: 私钥有密码怎么办？

如果生成 SSH key 时设置了密码，需要配置 `ssh-agent`：

```bash
# 启动 ssh-agent
eval "$(ssh-agent -s)"

# 添加私钥（会提示输入密码）
ssh-add ~/.ssh/ceoagent_deploy

# 或者在 GitHub Actions 中使用 ssh-agent action（已配置）
```

**注意**：GitHub Actions 已经配置了 `webfactory/ssh-agent@v0.9.0`，但如果私钥有密码，可能需要额外配置。

**推荐**：重新生成不带密码的 SSH key：
```bash
ssh-keygen -t ed25519 -C "ceoagent-deploy" -f ~/.ssh/ceoagent_deploy -N ""
# -N "" 表示不设置密码
```

### Q4: 如何更新已存在的 Secret？

1. 访问 Secrets 页面
2. 找到要更新的 Secret
3. 点击右侧的 **Update**（更新）按钮
4. 修改值后保存

### Q5: 如何删除 Secret？

1. 访问 Secrets 页面
2. 找到要删除的 Secret
3. 点击右侧的 **Delete**（删除）按钮
4. 确认删除

## 🛡️ 安全建议

1. **不要泄露私钥**：私钥内容不要分享给任何人
2. **定期轮换**：建议定期更新 SSH key
3. **使用专用 key**：为 GitHub Actions 创建专用的 SSH key，不要使用个人 key
4. **限制权限**：服务器上的 SSH key 应该有适当的权限设置

## 📚 相关文档

- [GitHub Secrets 官方文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [SSH Key 生成指南](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [服务器部署指南](./SERVER_DEPLOYMENT.md)

---

**提示**：配置完成后，记得测试一次自动部署，确保一切正常工作！
