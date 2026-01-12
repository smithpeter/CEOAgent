# 服务器部署指南

本指南介绍如何将 CEOAgent 部署到服务器 `136.115.199.54`，实现持续测试和在线运行。

## 📋 目录

- [快速开始](#快速开始)
- [服务器配置](#服务器配置)
- [手动部署](#手动部署)
- [自动部署](#自动部署)
- [管理命令](#管理命令)
- [故障排除](#故障排除)

## 🚀 快速开始

### 前提条件

1. **服务器信息**
   - IP: `136.115.199.54`
   - 用户: `root` (可通过环境变量 `SERVER_USER` 修改)
   - SSH 端口: `22` (可通过环境变量 `SERVER_PORT` 修改)

2. **服务器要求**
   - Docker 和 Docker Compose 已安装
   - Git 已安装
   - 至少 4GB RAM
   - 至少 20GB 可用磁盘空间
   - 端口 `8000` 可用（API 服务）

### 一键部署

```bash
# 测试服务器连接
./scripts/test-server-connection.sh

# 部署到服务器（使用默认配置）
./scripts/deploy-server.sh

# 部署指定分支
./scripts/deploy-server.sh main production
```

## 🔧 服务器配置

### 1. 首次服务器设置

如果服务器是全新的，需要先安装必要的软件：

```bash
# SSH 连接到服务器
ssh root@136.115.199.54

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 安装 Docker Compose
apt-get update
apt-get install -y docker-compose-plugin

# 或使用旧版 Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 安装 Git
apt-get install -y git

# 创建部署目录
mkdir -p /opt/ceoagent
```

### 2. 配置 SSH Key（用于自动部署）

#### 在本地生成 SSH Key（如果还没有）

```bash
ssh-keygen -t ed25519 -C "ceoagent-deploy" -f ~/.ssh/ceoagent_deploy
```

#### 将公钥添加到服务器

```bash
# 方法 1: 使用 ssh-copy-id
ssh-copy-id -i ~/.ssh/ceoagent_deploy.pub root@136.115.199.54

# 方法 2: 手动添加
cat ~/.ssh/ceoagent_deploy.pub | ssh root@136.115.199.54 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### 测试 SSH 连接

```bash
ssh -i ~/.ssh/ceoagent_deploy root@136.115.199.54 "echo 'SSH key 配置成功'"
```

### 3. 配置环境变量

在服务器上创建 `.env` 文件：

```bash
# SSH 连接到服务器
ssh root@136.115.199.54

# 进入部署目录
cd /opt/ceoagent

# 复制环境变量模板
cp .env.example .env

# 编辑环境变量（重要：设置 ANTHROPIC_API_KEY）
nano .env
```

**必须配置的环境变量**：

```bash
ANTHROPIC_API_KEY=sk-ant-your-actual-api-key-here
DATABASE_URL=postgresql://ceoagent:your_password@postgres:5432/ceoagent
POSTGRES_PASSWORD=your_secure_password
```

## 📦 手动部署

### 方法 1: 使用部署脚本（推荐）

```bash
# 基本部署
./scripts/deploy-server.sh

# 指定分支和环境
./scripts/deploy-server.sh main production

# 使用自定义配置
export SERVER_IP=136.115.199.54
export SERVER_USER=root
export SERVER_PORT=22
export SERVER_DEPLOY_PATH=/opt/ceoagent
./scripts/deploy-server.sh main production
```

### 方法 2: 手动 SSH 部署

```bash
# 1. SSH 连接到服务器
ssh root@136.115.199.54

# 2. 进入部署目录
cd /opt/ceoagent

# 3. 克隆或更新代码
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/smithpeter/CEOAgent.git .
    git checkout main
fi

# 4. 确保 .env 文件存在并配置正确
if [ ! -f .env ]; then
    cp .env.example .env
    # 编辑 .env 文件，设置必要的环境变量
    nano .env
fi

# 5. 停止旧服务
docker-compose down || docker compose down

# 6. 构建并启动服务
docker-compose up -d --build || docker compose up -d --build

# 7. 查看日志
docker-compose logs -f || docker compose logs -f
```

## 🔄 自动部署

### GitHub Actions 自动部署

项目已配置 GitHub Actions，每次推送到 `main` 或 `develop` 分支时自动部署到服务器。

#### 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

1. **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

需要添加的 Secrets：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `SERVER_IP` | 服务器 IP 地址 | `136.115.199.54` |
| `SERVER_USER` | SSH 用户名 | `root` |
| `SERVER_SSH_PORT` | SSH 端口 | `22` |
| `SERVER_DEPLOY_PATH` | 部署路径 | `/opt/ceoagent` |
| `SERVER_SSH_PRIVATE_KEY` | SSH 私钥 | 从 `~/.ssh/ceoagent_deploy` 复制 |

#### 获取 SSH 私钥

```bash
# 显示私钥内容（用于复制到 GitHub Secrets）
cat ~/.ssh/ceoagent_deploy

# 重要：这是私钥，不要泄露！
```

#### 自动部署流程

1. **推送代码到 GitHub**
   ```bash
   git push origin main
   ```

2. **GitHub Actions 自动触发**
   - 运行测试
   - 构建 Docker 镜像
   - 部署到服务器
   - 运行健康检查

3. **查看部署状态**
   - 访问: https://github.com/smithpeter/CEOAgent/actions

## 🛠️ 管理命令

### 查看服务状态

```bash
# SSH 连接到服务器
ssh root@136.115.199.54

# 查看容器状态
cd /opt/ceoagent
docker-compose ps || docker compose ps

# 查看所有容器
docker ps -a
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f || docker compose logs -f

# 查看特定服务日志
docker-compose logs -f api || docker compose logs -f api

# 查看最近 100 行日志
docker-compose logs --tail=100 || docker compose logs --tail=100
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart || docker compose restart

# 重启特定服务
docker-compose restart api || docker compose restart api

# 完全重启（停止并启动）
docker-compose down && docker-compose up -d
```

### 更新代码

```bash
# 方法 1: 使用部署脚本（推荐）
./scripts/deploy-server.sh

# 方法 2: 手动更新
ssh root@136.115.199.54 "cd /opt/ceoagent && git pull && docker-compose up -d --build"
```

### 停止服务

```bash
# 停止所有服务（保留数据）
docker-compose down || docker compose down

# 停止并删除所有数据（谨慎使用！）
docker-compose down -v || docker compose down -v
```

### 健康检查

```bash
# 检查 API 健康状态
curl http://136.115.199.54:8000/health

# 检查服务是否运行
curl http://136.115.199.54:8000/docs
```

## 📊 访问服务

部署成功后，可以通过以下地址访问服务：

- **API 服务**: http://136.115.199.54:8000
- **健康检查**: http://136.115.199.54:8000/health
- **API 文档**: http://136.115.199.54:8000/docs
- **OpenAPI Schema**: http://136.115.199.54:8000/openapi.json

## 🔍 故障排除

### 问题 1: SSH 连接失败

**症状**: 无法连接到服务器

**解决方案**:
```bash
# 检查网络连接
ping 136.115.199.54

# 检查 SSH 服务
telnet 136.115.199.54 22

# 使用详细模式查看错误
ssh -v root@136.115.199.54
```

### 问题 2: Docker 未安装

**症状**: 部署脚本提示 Docker 未安装

**解决方案**:
```bash
# 在服务器上安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### 问题 3: 端口被占用

**症状**: 服务启动失败，提示端口被占用

**解决方案**:
```bash
# 检查端口占用
netstat -tlnp | grep 8000

# 停止占用端口的服务
docker-compose down
# 或
lsof -ti:8000 | xargs kill -9
```

### 问题 4: 服务无法访问

**症状**: 健康检查失败

**解决方案**:
```bash
# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs api

# 检查防火墙
ufw status
# 如果防火墙开启，需要开放端口
ufw allow 8000/tcp
```

### 问题 5: 环境变量未配置

**症状**: API 调用失败，提示 API key 错误

**解决方案**:
```bash
# 检查 .env 文件
ssh root@136.115.199.54 "cat /opt/ceoagent/.env"

# 更新环境变量
ssh root@136.115.199.54 "cd /opt/ceoagent && nano .env"
# 然后重启服务
docker-compose restart
```

### 问题 6: 磁盘空间不足

**症状**: 构建失败或服务无法启动

**解决方案**:
```bash
# 检查磁盘空间
df -h

# 清理 Docker 资源
docker system prune -a

# 清理旧镜像
docker image prune -a
```

## 🔐 安全建议

1. **修改默认密码**: 确保所有服务的默认密码都已修改
2. **配置防火墙**: 只开放必要的端口
3. **使用非 root 用户**: 创建专用用户进行部署
4. **定期更新**: 保持系统和 Docker 镜像更新
5. **备份数据**: 定期备份数据库和配置文件

## 📝 维护计划

- **每日**: 检查服务健康状态
- **每周**: 查看日志，检查错误
- **每月**: 更新依赖和安全补丁
- **每季度**: 审查和优化配置

## 🆘 获取帮助

如果遇到问题：

1. 查看日志: `docker-compose logs`
2. 检查 GitHub Issues: https://github.com/smithpeter/CEOAgent/issues
3. 运行测试脚本: `./scripts/test-server-connection.sh`

---

**提示**: 建议在生产环境使用域名和 HTTPS。可以使用 Nginx 反向代理和 Let's Encrypt 证书。
