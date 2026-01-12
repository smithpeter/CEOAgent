# MVP 部署清单

> **创建日期**: 2026-01-12
> **创建人**: 运维工程师 (DevOps)
> **关联文档**: DEPLOYMENT.md, MASTER_PLAN.md

---

## 一、部署方案验证

### 1.1 验证结论

| 验证项 | 状态 | 说明 |
|--------|------|------|
| Docker 配置完整 | ✅ | Dockerfile + docker-compose |
| K8s 配置存在 | ✅ | k8s/base/ 目录 |
| CI/CD 流程定义 | ✅ | GitHub Actions |
| 监控方案定义 | ✅ | Prometheus + Grafana |

### 1.2 MVP 部署简化

根据 `MASTER_PLAN.md`，MVP 阶段使用简化部署方案：

| 组件 | 完整方案 | MVP 方案 |
|------|---------|---------|
| 运行环境 | Kubernetes | Docker Compose |
| 数据库 | PostgreSQL | 内存 + JSON 文件 |
| 缓存 | Redis | 内存 |
| 向量库 | Weaviate | 不使用 |
| 监控 | Prometheus + Grafana | 基础日志 |

---

## 二、MVP 部署架构

```
┌─────────────────────────────────────────────────────────┐
│                    MVP 部署架构                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │               Docker Compose                     │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐ │   │
│  │  │          ceoagent-api                       │ │   │
│  │  │          FastAPI (Port 8000)               │ │   │
│  │  │                                            │ │   │
│  │  │  ┌──────────────────────────────────────┐ │ │   │
│  │  │  │         Application                  │ │ │   │
│  │  │  │  ┌─────────┐  ┌─────────┐           │ │ │   │
│  │  │  │  │AgentCore│  │PromptMgr│           │ │ │   │
│  │  │  │  └─────────┘  └─────────┘           │ │ │   │
│  │  │  │  ┌─────────┐  ┌─────────┐           │ │ │   │
│  │  │  │  │ Claude  │  │Response │           │ │ │   │
│  │  │  │  │ Client  │  │ Parser  │           │ │ │   │
│  │  │  │  └─────────┘  └─────────┘           │ │ │   │
│  │  │  └──────────────────────────────────────┘ │ │   │
│  │  └────────────────────────────────────────────┘ │   │
│  │                                                  │   │
│  │  Volumes:                                        │   │
│  │  - ./prompts:/app/prompts (只读)                │   │
│  │  - ./data:/app/data (读写)                      │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  外部依赖:                                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Claude API (api.anthropic.com)                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 三、部署检查清单

### 3.1 环境准备

- [ ] **Python 环境**
  - [ ] Python 3.11+ 已安装
  - [ ] pip 已更新到最新版本
  - [ ] virtualenv 或 venv 可用

- [ ] **Docker 环境**
  - [ ] Docker Engine 已安装 (>= 20.10)
  - [ ] Docker Compose 已安装 (>= 2.0)
  - [ ] Docker daemon 运行中

- [ ] **网络访问**
  - [ ] 可访问 api.anthropic.com
  - [ ] 可访问 pypi.org (安装依赖)

### 3.2 配置准备

- [ ] **环境变量**
  - [ ] `.env` 文件已创建
  - [ ] `ANTHROPIC_API_KEY` 已配置
  - [ ] `MODEL_NAME` 已配置 (默认: claude-3-5-sonnet-20241022)
  - [ ] `HOST` 已配置 (默认: 0.0.0.0)
  - [ ] `PORT` 已配置 (默认: 8000)

- [ ] **Prompt 模板**
  - [ ] `prompts/v1/system.txt` 存在
  - [ ] `prompts/v1/decision_analysis.txt` 存在

### 3.3 构建检查

- [ ] **代码检查**
  - [ ] 所有测试通过 (`pytest tests/`)
  - [ ] 代码格式检查通过 (`ruff check .`)
  - [ ] 类型检查通过 (`mypy src/`)

- [ ] **镜像构建**
  - [ ] Dockerfile 语法正确
  - [ ] 镜像构建成功 (`docker build -t ceoagent:latest .`)
  - [ ] 镜像大小合理 (< 500MB)

### 3.4 部署执行

- [ ] **启动服务**
  - [ ] `docker-compose up -d` 成功
  - [ ] 容器状态正常 (`docker ps`)
  - [ ] 无启动错误日志

- [ ] **健康检查**
  - [ ] `/health` 返回 200
  - [ ] `/docs` 可访问

- [ ] **功能验证**
  - [ ] `/api/v1/analyze` 接口可用
  - [ ] 返回结果格式正确
  - [ ] 响应时间 < 30s

---

## 四、部署配置文件

### 4.1 MVP Dockerfile

```dockerfile
# MVP Dockerfile
FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制代码
COPY src/ ./src/
COPY prompts/ ./prompts/

# 设置环境变量
ENV PYTHONPATH=/app/src
ENV HOST=0.0.0.0
ENV PORT=8000

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "ceo_agent.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 4.2 MVP docker-compose.yml

```yaml
# MVP docker-compose.yml
version: '3.8'

services:
  ceoagent-api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ceoagent-api
    ports:
      - "8000:8000"
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - MODEL_NAME=${MODEL_NAME:-claude-3-5-sonnet-20241022}
      - HOST=0.0.0.0
      - PORT=8000
      - DEBUG=${DEBUG:-false}
    volumes:
      - ./prompts:/app/prompts:ro
      - ./data:/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

### 4.3 .env.example

```bash
# MVP 环境变量配置示例

# Anthropic API 配置 (必需)
ANTHROPIC_API_KEY=sk-ant-xxxx

# 模型配置
MODEL_NAME=claude-3-5-sonnet-20241022

# 服务配置
HOST=0.0.0.0
PORT=8000
DEBUG=false

# 限制配置
MAX_QUERY_LENGTH=10000
REQUEST_TIMEOUT=60
MAX_RETRIES=3
```

---

## 五、部署命令

### 5.1 本地开发部署

```bash
# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# 2. 安装依赖
pip install -r requirements.txt

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 填入 ANTHROPIC_API_KEY

# 4. 启动服务
uvicorn src.ceo_agent.main:app --reload --host 0.0.0.0 --port 8000
```

### 5.2 Docker 部署

```bash
# 1. 配置环境变量
cp .env.example .env
# 编辑 .env 填入 ANTHROPIC_API_KEY

# 2. 构建镜像
docker build -t ceoagent:latest .

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f

# 5. 停止服务
docker-compose down
```

### 5.3 验证命令

```bash
# 健康检查
curl http://localhost:8000/health

# API 测试
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "Should we expand to new markets?"}'

# 查看 API 文档
open http://localhost:8000/docs
```

---

## 六、监控方案 (MVP 简化版)

### 6.1 日志监控

```python
# 日志配置
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# 关键日志点
logger.info(f"Request received: {request_id}")
logger.info(f"Claude API called: {tokens_used} tokens")
logger.info(f"Request completed: {execution_time}ms")
logger.error(f"Request failed: {error}")
```

### 6.2 关键指标

| 指标 | 采集方式 | 告警阈值 |
|------|---------|---------|
| 服务可用性 | health endpoint | 连续 3 次失败 |
| 响应时间 | 日志 | P95 > 30s |
| 错误率 | 日志 | > 5% |
| Token 使用 | 日志 | 日均 > 100k |

### 6.3 MVP 监控脚本

```bash
#!/bin/bash
# mvp_monitor.sh - MVP 简易监控脚本

# 健康检查
check_health() {
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
    if [ "$response" != "200" ]; then
        echo "ALERT: Service unhealthy (HTTP $response)"
        # 可添加通知逻辑
    fi
}

# 每 30 秒检查一次
while true; do
    check_health
    sleep 30
done
```

---

## 七、故障排查

### 7.1 常见问题

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 启动失败 | 端口被占用 | 检查 8000 端口，或修改 PORT |
| API 超时 | Claude API 慢 | 检查网络，增加超时时间 |
| 认证失败 | API Key 错误 | 检查 ANTHROPIC_API_KEY |
| 内存不足 | 容器限制 | 增加 Docker 内存限制 |

### 7.2 日志查看

```bash
# Docker 日志
docker-compose logs -f ceoagent-api

# 过滤错误
docker-compose logs ceoagent-api | grep ERROR

# 查看最近 100 行
docker-compose logs --tail=100 ceoagent-api
```

### 7.3 重启服务

```bash
# 重启容器
docker-compose restart ceoagent-api

# 完全重建
docker-compose down
docker-compose up -d --build
```

---

## 八、升级路径

### 8.1 MVP → Phase 2

| 组件 | MVP | Phase 2 |
|------|-----|---------|
| 存储 | 内存 | PostgreSQL + Redis |
| 认证 | 无 | JWT |
| 部署 | Docker Compose | Kubernetes |
| 监控 | 日志 | Prometheus + Grafana |

### 8.2 迁移检查清单

- [ ] 数据迁移脚本准备
- [ ] PostgreSQL 部署
- [ ] Redis 部署
- [ ] K8s 配置更新
- [ ] 监控系统部署
- [ ] 负载测试

---

## 九、验证结论

✅ **部署方案验证通过**

- Docker 配置完整可用
- 部署命令清晰
- 监控方案（简化版）可行
- 故障排查文档完整
- 升级路径明确

---

## 更新日志

| 日期 | 修改内容 | 修改人 |
|------|---------|--------|
| 2026-01-12 | 创建 MVP 部署清单 | DevOps |
