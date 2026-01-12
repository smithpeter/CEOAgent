# Docker 安装指南

由于需要 sudo 权限，建议通过 **GCP Browser SSH** 安装。

## 方法 1: 通过 Browser SSH 安装（推荐）

### 步骤：

1. **打开 GCP Browser SSH**
   - 访问：https://console.cloud.google.com/compute/instances
   - 找到 IP 为 `136.115.199.54` 的实例
   - 点击右侧的 **SSH** 按钮

2. **在 Browser SSH 终端中执行以下命令**（一条一条执行）：

```bash
# 更新包列表
sudo apt-get update

# 安装必要的依赖
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 创建目录
sudo mkdir -p /etc/apt/keyrings

# 添加 Docker 官方 GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 将用户添加到 docker 组（避免每次都需要 sudo）
sudo usermod -aG docker zouyongming
```

3. **验证安装**

```bash
docker --version
docker compose version
```

如果显示 "command not found"，运行：
```bash
newgrp docker
docker --version
```

---

## 方法 2: 一键安装脚本（Browser SSH）

在 Browser SSH 中执行：

```bash
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo apt-get install -y docker-compose-plugin && sudo usermod -aG docker zouyongming && echo "✅ Docker 安装完成！" && newgrp docker && docker --version
```

---

## 验证安装

安装完成后，在 Browser SSH 中测试：

```bash
docker --version
docker compose version
```

或者在本地终端测试：

```bash
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54 "docker --version"
```

---

## 如果仍然失败

1. 确认你有 sudo 权限
2. 尝试重新登录 SSH 会话
3. 运行 `newgrp docker` 刷新用户组
