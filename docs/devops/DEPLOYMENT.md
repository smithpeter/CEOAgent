# 部署架构与运维指南

## 部署架构概览

```mermaid
graph TB
    subgraph Cloud[云平台]
        subgraph K8s[Kubernetes 集群]
            subgraph Namespace[命名空间: ceoagent]
                API[API Pods<br/>FastAPI]
                Agent[Agent Pods<br/>ReAct/Plan]
                Worker[Worker Pods<br/>Celery]
            end
            
            subgraph Infra[基础设施]
                Ingress[Ingress Controller<br/>Nginx/Traefik]
                Service[Services<br/>Load Balancer]
                ConfigMap[ConfigMaps]
                Secret[Secrets]
            end
        end
        
        subgraph Storage[存储]
            PostgreSQL[(PostgreSQL<br/>主从复制)]
            Weaviate[(Weaviate<br/>集群)]
            Redis[(Redis<br/>集群)]
            Neo4j[(Neo4j<br/>单节点/集群)]
        end
        
        subgraph Monitoring[监控]
            Prometheus[Prometheus]
            Grafana[Grafana]
            ELK[ELK Stack]
        end
    end
    
    Internet[互联网] --> Ingress
    Ingress --> API
    API --> Agent
    API --> Worker
    Agent --> PostgreSQL
    Agent --> Weaviate
    Agent --> Redis
    Worker --> PostgreSQL
    Worker --> Redis
    Monitoring --> Prometheus
    Monitoring --> Grafana
```

## 1. 部署环境

### 1.1 开发环境

**技术栈**：Docker Compose

**架构**：
- 单机部署所有服务
- 使用 Docker Compose 编排
- 适合本地开发和测试

**配置文件**：`docker-compose.dev.yml`

### 1.2 测试环境

**技术栈**：Kubernetes (单节点)

**架构**：
- Kubernetes 单节点集群
- 简化配置，快速部署
- 用于集成测试和 QA

### 1.3 生产环境

**技术栈**：Kubernetes (多节点，高可用)

**架构**：
- Kubernetes 多节点集群
- 高可用配置
- 自动扩缩容
- 负载均衡

## 2. Docker 配置

### 2.1 应用 Dockerfile

```dockerfile
# 多阶段构建
FROM python:3.11-slim as builder

WORKDIR /app

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# 运行时阶段
FROM python:3.11-slim

WORKDIR /app

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# 从构建阶段复制依赖
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .

# 设置环境变量
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# 切换到非 root 用户
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health')"

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "src.ceo_agent.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2.2 Docker Compose 开发环境

```yaml
version: '3.8'

services:
  # API 服务
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/ceoagent
      - REDIS_URL=redis://redis:6379/0
      - WEAVIATE_URL=http://weaviate:8080
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    depends_on:
      - postgres
      - redis
      - weaviate
    volumes:
      - ./src:/app/src
    command: uvicorn src.ceo_agent.main:app --reload --host 0.0.0.0

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=ceoagent
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=ceoagent
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # Weaviate
  weaviate:
    image: semitechnologies/weaviate:latest
    ports:
      - "8080:8080"
    environment:
      - PERSISTENCE_DATA_PATH=/var/lib/weaviate
      - DEFAULT_VECTORIZER_MODULE=none
      - ENABLE_MODULES=text2vec-openai,text2vec-cohere,text2vec-huggingface
      - CLUSTER_HOSTNAME=node1
    volumes:
      - weaviate_data:/var/lib/weaviate

  # Neo4j (可选)
  neo4j:
    image: neo4j:5
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      - NEO4J_AUTH=neo4j/password
    volumes:
      - neo4j_data:/data

volumes:
  postgres_data:
  redis_data:
  weaviate_data:
  neo4j_data:
```

## 3. Kubernetes 配置

### 3.1 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ceoagent-api
  namespace: ceoagent
  labels:
    app: ceoagent-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ceoagent-api
  template:
    metadata:
      labels:
        app: ceoagent-api
    spec:
      containers:
      - name: api
        image: ceoagent/api:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ceoagent-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: ceoagent-config
              key: redis-url
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: ceoagent-secrets
              key: anthropic-api-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
```

### 3.2 Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ceoagent-api
  namespace: ceoagent
spec:
  selector:
    app: ceoagent-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: ClusterIP
```

### 3.3 Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ceoagent-ingress
  namespace: ceoagent
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.ceoagent.com
    secretName: ceoagent-tls
  rules:
  - host: api.ceoagent.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ceoagent-api
            port:
              number: 80
```

### 3.4 ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceoagent-config
  namespace: ceoagent
data:
  redis-url: "redis://redis-service:6379/0"
  weaviate-url: "http://weaviate-service:8080"
  log-level: "INFO"
  max-workers: "10"
```

### 3.5 Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceoagent-secrets
  namespace: ceoagent
type: Opaque
stringData:
  database-url: "postgresql://user:password@postgres-service:5432/ceoagent"
  anthropic-api-key: "sk-ant-api03-..."
  encryption-key: "..."
```

## 4. 数据库部署

### 4.1 PostgreSQL

**生产环境配置**：
- 主从复制（High Availability）
- 自动备份
- 连接池优化

```yaml
# PostgreSQL StatefulSet (简化版)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: ceoagent
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

### 4.2 Weaviate

**集群配置**：
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: weaviate
  namespace: ceoagent
spec:
  serviceName: weaviate
  replicas: 3
  selector:
    matchLabels:
      app: weaviate
  template:
    metadata:
      labels:
        app: weaviate
    spec:
      containers:
      - name: weaviate
        image: semitechnologies/weaviate:latest
        env:
        - name: PERSISTENCE_DATA_PATH
          value: "/var/lib/weaviate"
        - name: CLUSTER_HOSTNAME
          value: "weaviate-$(POD_NAME)"
        volumeMounts:
        - name: weaviate-storage
          mountPath: /var/lib/weaviate
  volumeClaimTemplates:
  - metadata:
      name: weaviate-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
```

### 4.3 Redis

**集群配置**（使用 Redis Operator 或 Helm）：
```bash
helm install redis bitnami/redis \
  --set auth.enabled=true \
  --set auth.password=password \
  --set cluster.enabled=true \
  --set cluster.nodes=6
```

## 5. 自动扩缩容

### 5.1 Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ceoagent-api-hpa
  namespace: ceoagent
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ceoagent-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max
```

## 6. CI/CD 流程

### 6.1 概述

本项目采用 **GitHub Actions** 实现完整的 CI/CD 自动化流程，包括：

- ✅ 代码质量检查（Lint、Format、Type Check）
- ✅ 自动化测试（单元测试、集成测试）
- ✅ 安全扫描（依赖漏洞、代码安全）
- ✅ Docker 镜像构建和推送
- ✅ 自动部署到开发/生产环境
- ✅ 数据库迁移
- ✅ 性能测试
- ✅ 部署后健康检查

**详细文档**: 请参考 [CICD.md](./CICD.md) 获取完整的 CI/CD 配置和运维指南。

### 6.2 快速开始

#### 配置文件位置

- **CI/CD 工作流**: `.github/workflows/ci-cd.yml`
- **Docker 配置**: `Dockerfile`, `docker-compose.yml`
- **Kubernetes 配置**: `k8s/base/`
- **部署脚本**: `scripts/deploy.sh`, `scripts/backup.sh`

#### 基本流程

```mermaid
graph LR
    A[代码推送] --> B[代码检查]
    B --> C[单元测试]
    C --> D[构建镜像]
    D --> E{分支判断}
    E -->|develop| F[部署开发环境]
    E -->|main| G[部署生产环境]
```

#### 环境配置

1. **配置 GitHub Secrets**:
   ```bash
   KUBECONFIG_DEV       # 开发环境 kubeconfig
   KUBECONFIG_PROD      # 生产环境 kubeconfig
   ANTHROPIC_API_KEY    # Claude API 密钥
   DATABASE_URL_PROD    # 生产数据库 URL
   ```

2. **部署到开发环境**: Push 到 `develop` 分支
3. **部署到生产环境**: Push 到 `main` 分支或创建标签 `v*`

#### 手动部署

```bash
# 使用部署脚本
export NAMESPACE=ceoagent
export IMAGE_TAG=v1.0.0
./scripts/deploy.sh

# 或使用 kubectl
kubectl set image deployment/ceoagent-api \
  api=ghcr.io/OWNER/CEOAgent:v1.0.0 \
  -n ceoagent
```

## 7. 备份和恢复

### 7.1 自动化备份

使用提供的备份脚本进行自动化备份：

```bash
# 执行备份脚本
./scripts/backup.sh

# 配置备份目录和保留天数
export BACKUP_DIR=/path/to/backups
export RETENTION_DAYS=30
export NAMESPACE=ceoagent
./scripts/backup.sh
```

#### PostgreSQL 备份

```bash
# 手动备份 PostgreSQL
kubectl exec -n ceoagent postgres-0 -- \
  pg_dump -U ceoagent ceoagent > backup_$(date +%Y%m%d_%H%M%S).sql

# 压缩备份
gzip backup_*.sql

# 上传到 S3 (可选)
aws s3 cp backup_*.sql.gz s3://ceoagent-backups/postgres/
```

#### Weaviate 备份

```bash
# Weaviate 备份（导出数据）
curl -X POST "http://weaviate:8080/v1/backups/filesystem" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "backup-20250111",
    "include": ["Decision"]
  }'
```

### 7.2 备份策略

- **频率**: 每日自动备份
- **保留期**: 30 天（可配置）
- **存储**: 本地 + 云端（S3/OSS）
- **验证**: 定期验证备份完整性

### 7.3 恢复流程

```bash
# 恢复 PostgreSQL
gunzip backup_20250111_120000.sql.gz
kubectl exec -i -n ceoagent postgres-0 -- \
  psql -U ceoagent ceoagent < backup_20250111_120000.sql

# 恢复 Weaviate
curl -X POST "http://weaviate:8080/v1/backups/filesystem/restore" \
  -H "Content-Type: application/json" \
  -d '{"id": "backup-20250111"}'
```

## 8. 监控和日志

### 8.1 健康检查端点

```python
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/ready")
async def readiness_check():
    """就绪检查"""
    # 检查数据库连接
    db_ok = await check_database()
    redis_ok = await check_redis()
    weaviate_ok = await check_weaviate()
    
    if db_ok and redis_ok and weaviate_ok:
        return {"status": "ready"}
    else:
        raise HTTPException(status_code=503, detail="Not ready")
```

## 9. 安全配置

### 9.1 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ceoagent-network-policy
  namespace: ceoagent
spec:
  podSelector:
    matchLabels:
      app: ceoagent-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
```

## 10. 运维清单

### 日常运维

- [ ] 监控系统健康状态
- [ ] 检查日志错误
- [ ] 监控资源使用
- [ ] 验证备份完整性

### 定期维护

- [ ] 数据库备份验证
- [ ] 安全更新
- [ ] 性能优化审查
- [ ] 容量规划

### 故障处理

- [ ] 服务降级流程
- [ ] 回滚流程
- [ ] 数据恢复流程
- [ ] 应急联系清单

## 11. 持续更新与完善

### 11.1 版本管理

- **语义化版本**: 使用 `vMAJOR.MINOR.PATCH` 格式
- **标签发布**: 创建 Git 标签触发生产部署
- **变更日志**: 维护 CHANGELOG.md 记录变更

### 11.2 持续改进流程

1. **代码质量监控**
   - 代码覆盖率 > 80%
   - 代码审查必须通过
   - 自动化测试必须通过

2. **性能监控**
   - 部署后自动运行性能测试
   - 监控关键指标
   - 定期性能优化审查

3. **安全更新**
   - 定期扫描依赖漏洞
   - 及时更新安全补丁
   - 审计访问日志

4. **文档维护**
   - 保持文档与代码同步
   - 记录架构变更
   - 更新运维流程

### 11.3 自动化运维

- ✅ **自动部署**: 通过 CI/CD 实现零停机部署
- ✅ **自动备份**: 定时备份数据库和向量数据库
- ✅ **自动扩缩容**: HPA 根据负载自动调整 Pod 数量
- ✅ **自动告警**: Prometheus + Alertmanager 自动告警
- ✅ **自动回滚**: 部署失败时自动回滚

### 11.4 监控指标

定期审查以下指标：

- 部署成功率 > 95%
- 部署时间 < 10 分钟
- 系统可用性 > 99.9%
- 平均响应时间 < 500ms
- 错误率 < 0.1%

## 参考文档

- [CICD.md](./CICD.md) - **CI/CD 完整运维指南** ⭐ 新增
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构
- [MONITORING.md](./MONITORING.md) - 监控指南
- [SECURITY.md](./SECURITY.md) - 安全配置
- [PERFORMANCE.md](./PERFORMANCE.md) - 性能优化
