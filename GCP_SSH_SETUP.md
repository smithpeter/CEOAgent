# Google Cloud Platform (GCP) SSH 密钥配置指南

本指南说明如何在 GCP 云服务器上配置 SSH 密钥。

## 🔑 需要添加的公钥

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
```

## 📋 方法 1: 通过 GCP Console（Web 控制台）

### 步骤：

1. **登录 GCP Console**
   - 访问：https://console.cloud.google.com
   - 选择你的项目

2. **进入 Compute Engine**
   - 在左侧菜单找到 **Compute Engine** → **VM instances**
   - 找到 IP 为 `136.115.199.54` 的实例

3. **编辑实例的元数据（Metadata）**
   - 点击实例名称进入详情页
   - 点击顶部的 **EDIT**（编辑）按钮
   - 向下滚动找到 **SSH Keys** 部分
   - 点击 **Add item**（添加项）

4. **添加 SSH 公钥**
   - 在输入框中粘贴以下内容：
     ```
     root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
     ```
   - **重要**：格式为 `用户名:公钥内容`，这里是 `root:公钥`
   - 点击 **SAVE**（保存）

5. **等待生效**
   - 保存后，GCP 会自动将公钥添加到实例的 `~/.ssh/authorized_keys`
   - 通常几秒钟后生效

## 📋 方法 2: 使用 gcloud 命令行工具

如果你本地安装了 `gcloud` CLI 工具：

```bash
# 1. 登录 GCP
gcloud auth login

# 2. 设置项目
gcloud config set project YOUR_PROJECT_ID

# 3. 获取实例信息
gcloud compute instances list

# 4. 添加 SSH key 到实例元数据
gcloud compute instances add-metadata INSTANCE_NAME \
  --metadata-from-file ssh-keys=<(echo "root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy")

# 或者追加到现有 keys（推荐）
gcloud compute instances add-metadata INSTANCE_NAME \
  --metadata ssh-keys="root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy"

# 注意：需要将 INSTANCE_NAME 替换为实际的实例名称
```

## 📋 方法 3: 通过 GCP Console 的 Browser SSH

如果你可以通过 GCP Console 的 Browser SSH 连接到实例：

1. **通过 Browser SSH 连接**
   - 在 VM instances 页面，点击实例右侧的 **SSH** 按钮
   - 会打开浏览器内的 SSH 终端

2. **在实例上手动添加公钥**
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

## 🔍 查找实例信息

如果不知道实例名称：

```bash
# 通过 IP 查找实例
gcloud compute instances list --filter="networkInterfaces.accessConfigs.natIP=136.115.199.54"
```

或者在 GCP Console 中：
- 直接在 VM instances 列表中搜索 IP 地址 `136.115.199.54`

## ✅ 验证配置

添加公钥后，测试连接：

```bash
ssh -i ~/.ssh/ceoagent_deploy root@136.115.199.54 "echo '连接成功'"
```

如果成功，会显示 "连接成功"。

## ⚠️ 注意事项

1. **用户名问题**
   - GCP 默认用户可能不是 `root`
   - 如果是其他用户（如 `your-username`），在添加 SSH key 时使用：
     ```
     your-username:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
     ```
   - 如果实例允许 root 登录，使用 `root:`
   - 如果不确定，可以通过 Browser SSH 连接后运行 `whoami` 查看

2. **多个 SSH keys**
   - GCP Metadata 中的 SSH keys 可以是多行，每行一个
   - 格式：`用户名:公钥内容`

3. **生效时间**
   - 通过 Metadata 添加的 SSH key 通常在几秒钟内生效
   - 如果立即测试失败，等待 10-30 秒后重试

## 🆘 故障排除

### 问题 1: 连接失败 "Permission denied"

**可能原因**：
- 用户名不对（使用了 root 但实际用户不是 root）
- 公钥格式不对
- 实例元数据未更新

**解决方案**：
```bash
# 检查实例的用户名
# 通过 Browser SSH 连接后运行：
whoami

# 然后使用正确的用户名重新添加公钥
```

### 问题 2: 找不到实例

**解决方案**：
- 确认 IP 地址正确
- 确认当前 GCP 项目正确
- 检查实例是否在运行

### 问题 3: Metadata 更新后仍无法连接

**解决方案**：
```bash
# 等待更长时间（有时需要 1-2 分钟）
# 或者重启实例（通过 Console 或命令）
gcloud compute instances reset INSTANCE_NAME
```

## 📚 相关文档

- [GCP SSH Keys 官方文档](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys)
- [gcloud compute instances 命令](https://cloud.google.com/sdk/gcloud/reference/compute/instances)

## 🎯 快速参考

**公钥内容**：
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
```

**GCP Console 添加格式**：
```
root:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
```

---

**提示**：添加公钥后，记得测试连接并配置 GitHub Secrets！
