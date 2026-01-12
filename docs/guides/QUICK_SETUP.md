# 🚀 快速设置指南 - 复制执行即可

本指南提供可直接复制执行的命令和操作步骤。

---

## 步骤 1: 在服务器上安装 Docker 和 Docker Compose

**在你的本地电脑终端执行：**

```bash
./scripts/install-server-dependencies.sh
```

**或者手动执行（如果脚本失败）：**

```bash
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo apt-get install -y docker-compose-plugin"
```

---

## 步骤 2: 配置 GitHub Secrets

### 2.1 打开 GitHub Secrets 页面

访问并点击下面这个链接：
```
https://github.com/smithpeter/CEOAgent/settings/secrets/actions
```

### 2.2 添加 Secrets（逐个添加，点击 "New repository secret"）

#### Secret 1: SERVER_IP
- **Name**: `SERVER_IP`
- **Secret**: 
```
136.115.199.54
```

#### Secret 2: SERVER_USER
- **Name**: `SERVER_USER`
- **Secret**: 
```
zouyongming
```

#### Secret 3: SERVER_SSH_PORT
- **Name**: `SERVER_SSH_PORT`
- **Secret**: 
```
22
```

#### Secret 4: SERVER_DEPLOY_PATH
- **Name**: `SERVER_DEPLOY_PATH`
- **Secret**: 
```
/opt/ceoagent
```

#### Secret 5: SERVER_SSH_PRIVATE_KEY
- **Name**: `SERVER_SSH_PRIVATE_KEY`
- **Secret**: （完整复制下面的内容，包括 BEGIN 和 END 行）

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpAAAAJgZHlc8GR5X
PAAAAAtzc2gtZWQyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpA
AAAEAQbLp7XTs1lw72KMSC2mrDSWPlRGOLKdLXVyUtN5/MaboJ5tTy11jeqPi+NFap8tD7
hIUvXLWYtrmuH6nQOKekAAAAD2Nlb2FnZW50LWRlcGxveQECAwQFBg==
-----END OPENSSH PRIVATE KEY-----
```

---

## 步骤 3: 验证配置

### 3.1 测试 SSH 连接

在你的本地电脑终端执行：

```bash
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "echo 'SSH 连接成功'"
```

**预期结果**: 显示 `SSH 连接成功`

### 3.2 检查 Docker 安装

在你的本地电脑终端执行：

```bash
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "docker --version && docker compose version"
```

**预期结果**: 显示 Docker 和 Docker Compose 的版本信息

### 3.3 测试 GitHub Actions 自动部署

在你的本地电脑终端执行：

```bash
git commit --allow-empty -m "测试自动部署"
git push origin main
```

然后访问：https://github.com/smithpeter/CEOAgent/actions

**预期结果**: 看到 "Deploy to Server" 任务开始运行

---

## 步骤 4: 首次手动部署（可选）

如果你想先手动部署测试：

```bash
./scripts/deploy-server.sh main production
```

---

## ✅ 完成！

配置完成后：
- ✅ 每次 `git push` 到 `main` 分支，会自动部署到服务器
- ✅ 部署地址：http://136.115.199.54:8000
- ✅ API 文档：http://136.115.199.54:8000/docs

---

## 🆘 遇到问题？

### 问题 1: SSH 连接失败
```bash
# 检查 SSH key
ls -la ~/.ssh/ceoagent_deploy

# 测试连接（显示详细错误）
ssh -v -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54
```

### 问题 2: Docker 安装失败
```bash
# 查看安装日志
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "sudo journalctl -u docker"
```

### 问题 3: GitHub Actions 部署失败
1. 访问：https://github.com/smithpeter/CEOAgent/actions
2. 点击失败的部署任务
3. 查看错误日志

---

## 📋 快速命令参考

```bash
# 测试服务器连接
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "echo '连接成功'"

# 查看服务器 Docker 状态
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "docker ps"

# 查看服务器日志
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "cd /opt/ceoagent && docker-compose logs -f"

# 手动部署
./scripts/deploy-server.sh

# 测试连接脚本
./scripts/test-server-connection.sh
```

---

**提示**: 所有命令都在项目根目录执行。
