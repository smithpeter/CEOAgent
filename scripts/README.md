# 部署和维护脚本

本目录包含 CEOAgent 项目的自动化部署和维护脚本。

## 脚本列表

### deploy.sh

自动化部署脚本，用于部署应用到 Kubernetes 集群。

**用法**:
```bash
# 基本用法
./scripts/deploy.sh

# 指定参数
export NAMESPACE=ceoagent-prod
export ENVIRONMENT=production
export IMAGE_TAG=v1.0.0
./scripts/deploy.sh
```

**功能**:
- ✅ 检查前置条件（kubectl、集群连接）
- ✅ 创建命名空间
- ✅ 创建/更新 Secrets
- ✅ 部署 ConfigMap
- ✅ 更新镜像标签
- ✅ 部署应用（Deployment、Service、Ingress、HPA）
- ✅ 等待部署完成
- ✅ 健康检查验证
- ✅ 失败时自动回滚

**环境变量**:
- `NAMESPACE`: Kubernetes 命名空间（默认: ceoagent）
- `ENVIRONMENT`: 环境名称（默认: production）
- `IMAGE_TAG`: 镜像标签（默认: latest）
- `KUBECONFIG_PATH`: kubeconfig 文件路径（可选）
- `DATABASE_URL`: 数据库 URL（创建 Secret 时需要）
- `ANTHROPIC_API_KEY`: Claude API 密钥（创建 Secret 时需要）
- `ENCRYPTION_KEY`: 加密密钥（创建 Secret 时需要）

### backup.sh

数据库备份脚本，用于备份 PostgreSQL 和 Weaviate。

**用法**:
```bash
# 基本用法
./scripts/backup.sh

# 指定参数
export BACKUP_DIR=/path/to/backups
export RETENTION_DAYS=60
export NAMESPACE=ceoagent
./scripts/backup.sh
```

**功能**:
- ✅ 备份 PostgreSQL 数据库
- ✅ 备份 Weaviate 向量数据库
- ✅ 压缩备份文件
- ✅ 清理旧备份（可配置保留天数）

**环境变量**:
- `BACKUP_DIR`: 备份目录（默认: ./backups）
- `NAMESPACE`: Kubernetes 命名空间（默认: ceoagent）
- `RETENTION_DAYS`: 备份保留天数（默认: 30）

**备份文件格式**:
- PostgreSQL: `postgres_backup_YYYYMMDD_HHMMSS.sql.gz`
- Weaviate: 通过 API 备份，ID 格式为 `backup-YYYYMMDD`

## 使用示例

### 部署到开发环境

```bash
export NAMESPACE=ceoagent-dev
export ENVIRONMENT=development
export IMAGE_TAG=develop-abc123
./scripts/deploy.sh
```

### 部署到生产环境

```bash
export NAMESPACE=ceoagent
export ENVIRONMENT=production
export IMAGE_TAG=v1.0.0
export DATABASE_URL="postgresql://user:pass@host:5432/db"
export ANTHROPIC_API_KEY="sk-ant-..."
export ENCRYPTION_KEY="your-encryption-key"
./scripts/deploy.sh
```

### 执行备份

```bash
# 每日备份（可添加到 cron）
0 2 * * * /path/to/scripts/backup.sh

# 手动备份
./scripts/backup.sh
```

### 恢复备份

```bash
# 恢复 PostgreSQL
gunzip backups/postgres_backup_20250111_120000.sql.gz
kubectl exec -i -n ceoagent postgres-0 -- \
  psql -U ceoagent ceoagent < backups/postgres_backup_20250111_120000.sql

# 恢复 Weaviate
kubectl port-forward -n ceoagent weaviate-0 8080:8080
curl -X POST "http://localhost:8080/v1/backups/filesystem/restore" \
  -H "Content-Type: application/json" \
  -d '{"id": "backup-20250111"}'
```

## 注意事项

1. **权限要求**: 脚本需要 kubectl 访问权限
2. **环境检查**: 部署前会自动检查前置条件
3. **失败处理**: 部署失败时会自动回滚
4. **备份验证**: 建议定期验证备份文件完整性
5. **安全**: 不要在脚本中硬编码敏感信息

## 扩展脚本

如需添加新的维护脚本，请遵循以下规范：

1. 使用 bash，设置 `set -euo pipefail`
2. 添加日志输出（使用 log_info、log_warn、log_error）
3. 支持环境变量配置
4. 添加错误处理
5. 提供使用文档
