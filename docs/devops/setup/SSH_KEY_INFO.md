# SSH Key 信息

## ✅ SSH Key 已生成

SSH key 已成功生成，位置：`~/.ssh/ceoagent_deploy`

## 📋 公钥内容（需要添加到服务器）

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
```

### 如何添加到服务器？

#### 方法 1: 如果你有现有的 SSH 访问权限

```bash
# 使用现有方式登录服务器
ssh root@136.115.199.54

# 在服务器上执行以下命令
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### 方法 2: 如果服务器支持密码登录

你需要手动登录服务器添加公钥，或者提供服务器密码来完成自动配置。

#### 方法 3: 通过服务器管理面板

如果你有服务器管理面板（如云服务商的 Web 控制台），可以在那里添加 SSH 公钥。

## 🔑 私钥内容（用于 GitHub Secrets）

完整私钥内容如下（**复制所有内容，包括 BEGIN 和 END 行**）：

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpAAAAJgZHlc8GR5X
PAAAAAtzc2gtZWQyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpA
AAAEAQbLp7XTs1lw72KMSC2mrDSWPlRGOLKdLXVyUtN5/MaboJ5tTy11jeqPi+NFap8tD7
hIUvXLWYtrmuH6nQOKekAAAAD2Nlb2FnZW50LWRlcGxveQECAwQFBg==
-----END OPENSSH PRIVATE KEY-----
```

**重要**：这是私钥，请保密！只用于 GitHub Secrets 配置。

## 📝 GitHub Secrets 配置

访问：https://github.com/smithpeter/CEOAgent/settings/secrets/actions

需要添加以下 Secrets：

### 1. SERVER_IP
```
136.115.199.54
```

### 2. SERVER_USER
```
root
```

### 3. SERVER_SSH_PORT
```
22
```

### 4. SERVER_DEPLOY_PATH
```
/opt/ceoagent
```

### 5. SERVER_SSH_PRIVATE_KEY
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpAAAAJgZHlc8GR5X
PAAAAAtzc2gtZWQyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpA
AAAEAQbLp7XTs1lw72KMSC2mrDSWPlRGOLKdLXVyUtN5/MaboJ5tTy11jeqPi+NFap8tD7
hIUvXLWYtrmuH6nQOKekAAAAD2Nlb2FnZW50LWRlcGxveQECAwQFBg==
-----END OPENSSH PRIVATE KEY-----
```

## ✅ 验证配置

配置完成后，测试连接：

```bash
ssh -i ~/.ssh/ceoagent_deploy root@136.115.199.54 "echo '连接成功'"
```

如果成功，会显示 "连接成功"。

## 🆘 如果无法连接服务器

如果你无法直接访问服务器添加公钥，可以：

1. **联系服务器管理员**：请管理员将上面的公钥添加到服务器的 `~/.ssh/authorized_keys` 文件
2. **使用服务器管理面板**：通过云服务商的 Web 控制台添加 SSH 公钥
3. **使用现有 SSH key**：如果你已经有能登录服务器的 SSH key，可以使用那个 key 的私钥配置 GitHub Secrets

---

**提示**：添加公钥到服务器后，记得测试 SSH 连接是否成功！
