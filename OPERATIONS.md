# 运维手册

## 概述

本文档提供 CEOAgent 项目的日常运维指南，包括监控、故障排查、维护等操作。

## 快速参考

### 常用命令

```bash
# 查看 Pod 状态
kubectl get pods -n ceoagent

# 查看日志
kubectl logs -f -n ceoagent deployment/ceoagent-api

# 查看服务状态
kubectl get svc -n ceoagent

# 查看 Ingress
kubectl get ingress -n ceoagent

# 查看事件
kubectl get events -n ceoagent --sort-by='.lastTimestamp'

# 进入 Pod
kubectl exec -it -n ceoagent deployment/ceoagent-api -- /bin/bash

# 查看资源使用
kubectl top pods -n ceoagent
```

## 监控与告警

### 健康检查

```bash
# API 健康检查
curl https://api.ceoagent.com/health

# 就绪检查
curl https://api.ceoagent.com/ready

# 指标端点
curl https://api.ceoagent.com/metrics
```

### 监控仪表板

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Kubernetes Dashboard**: 使用 `kubectl proxy` 访问

### 关键指标

监控以下关键指标：

1. **系统指标**
   - CPU 使用率 < 70%
   - 内存使用率 < 80%
   - 磁盘使用率 < 85%

2. **应用指标**
   - 请求速率
   - 错误率 < 0.1%
   - P95 响应时间 < 500ms
   - 可用性 > 99.9%

3. **业务指标**
   - 决策处理速率
   - Skill 执行成功率
   - LLM Token 使用量

## 日常运维

### 每日检查清单

- [ ] 检查系统健康状态
- [ ] 查看错误日志
- [ ] 检查资源使用情况
- [ ] 验证备份完整性
- [ ] 检查告警状态

### 每周检查清单

- [ ] 审查性能趋势
- [ ] 检查安全更新
- [ ] 审查日志保留策略
- [ ] 容量规划评估

### 每月检查清单

- [ ] 性能优化审查
- [ ] 安全审计
- [ ] 备份恢复测试
- [ ] 灾难恢复演练

## 故障排查

### 常见问题

#### 1. Pod 无法启动

**症状**: Pod 状态为 `CrashLoopBackOff` 或 `Error`

**排查步骤**:
```bash
# 查看 Pod 详情
kubectl describe pod <pod-name> -n ceoagent

# 查看日志
kubectl logs <pod-name> -n ceoagent --previous

# 检查事件
kubectl get events -n ceoagent --field-selector involvedObject.name=<pod-name>
```

**常见原因**:
- 镜像拉取失败
- 配置错误
- 资源不足
- 健康检查失败

#### 2. 服务不可用

**症状**: API 返回 503 或无法连接

**排查步骤**:
```bash
# 检查 Service
kubectl get svc ceoagent-api -n ceoagent -o yaml

# 检查 Endpoints
kubectl get endpoints ceoagent-api -n ceoagent

# 检查 Ingress
kubectl describe ingress ceoagent-ingress -n ceoagent

# 测试内部连接
kubectl run test-pod --image=curlimages/curl -it --rm -- \
  curl http://ceoagent-api.ceoagent.svc.cluster.local/health
```

#### 3. 性能问题

**症状**: 响应时间过长或超时

**排查步骤**:
```bash
# 查看 Pod 资源使用
kubectl top pods -n ceoagent

# 查看 HPA 状态
kubectl get hpa -n ceoagent

# 查看慢查询日志
kubectl logs -n ceoagent deployment/ceoagent-api | grep "slow"

# 查看 Prometheus 指标
# 访问 http://prometheus:9090 查询相关指标
```

#### 4. 数据库连接问题

**症状**: 数据库连接失败

**排查步骤**:
```bash
# 检查数据库 Pod
kubectl get pods -n ceoagent -l app=postgres

# 测试数据库连接
kubectl exec -n ceoagent postgres-0 -- \
  psql -U ceoagent -d ceoagent -c "SELECT 1"

# 检查 Secret
kubectl get secret ceoagent-secrets -n ceoagent -o yaml
```

## 维护操作

### 扩容/缩容

```bash
# 手动扩缩容
kubectl scale deployment ceoagent-api --replicas=5 -n ceoagent

# HPA 自动扩缩容（已配置）
kubectl get hpa ceoagent-api-hpa -n ceoagent
```

### 更新配置

```bash
# 更新 ConfigMap
kubectl apply -f k8s/base/configmap.yaml -n ceoagent

# 重启 Pod 使配置生效
kubectl rollout restart deployment/ceoagent-api -n ceoagent
```

### 更新 Secrets

```bash
# 更新 Secret
kubectl create secret generic ceoagent-secrets \
  --from-literal=database-url='...' \
  --from-literal=anthropic-api-key='...' \
  --dry-run=client -o yaml | kubectl apply -f - -n ceoagent

# 重启 Pod
kubectl rollout restart deployment/ceoagent-api -n ceoagent
```

### 回滚部署

```bash
# 查看部署历史
kubectl rollout history deployment/ceoagent-api -n ceoagent

# 回滚到上一个版本
kubectl rollout undo deployment/ceoagent-api -n ceoagent

# 回滚到指定版本
kubectl rollout undo deployment/ceoagent-api --to-revision=2 -n ceoagent
```

### 备份与恢复

```bash
# 执行备份
./scripts/backup.sh

# 查看备份文件
ls -lh backups/

# 恢复数据库
# 参见 scripts/README.md
```

## 升级流程

### 零停机升级

1. **准备阶段**
   ```bash
   # 创建备份
   ./scripts/backup.sh
   
   # 验证当前版本
   kubectl get deployment ceoagent-api -n ceoagent -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```

2. **部署新版本**
   ```bash
   # 通过 CI/CD 自动部署
   # 或手动部署
   kubectl set image deployment/ceoagent-api \
     api=ghcr.io/OWNER/CEOAgent:v1.1.0 \
     -n ceoagent
   ```

3. **监控部署**
   ```bash
   # 监控滚动更新
   kubectl rollout status deployment/ceoagent-api -n ceoagent
   
   # 检查健康状态
   curl https://api.ceoagent.com/health
   ```

4. **验证功能**
   - 运行冒烟测试
   - 检查关键指标
   - 验证业务流程

5. **回滚（如需要）**
   ```bash
   kubectl rollout undo deployment/ceoagent-api -n ceoagent
   ```

## 灾难恢复

### 恢复场景

#### 场景 1: 数据丢失

```bash
# 1. 停止服务
kubectl scale deployment ceoagent-api --replicas=0 -n ceoagent

# 2. 恢复数据库
gunzip backups/postgres_backup_*.sql.gz
kubectl exec -i -n ceoagent postgres-0 -- \
  psql -U ceoagent ceoagent < backups/postgres_backup_*.sql

# 3. 恢复 Weaviate
# 参见 scripts/README.md

# 4. 重启服务
kubectl scale deployment ceoagent-api --replicas=3 -n ceoagent
```

#### 场景 2: 集群故障

1. 切换到备用集群
2. 恢复配置和 Secrets
3. 恢复数据
4. 重新部署应用

#### 场景 3: 完全重建

1. 创建新的 Kubernetes 集群
2. 应用所有配置文件
3. 恢复数据备份
4. 部署应用
5. 验证功能

## 性能调优

### 应用层优化

- 调整 Worker 数量
- 优化数据库查询
- 启用缓存
- 批量处理请求

### 基础设施优化

- 调整 Pod 资源限制
- 优化 HPA 策略
- 使用节点亲和性
- 启用 Pod Disruption Budget

## 安全运维

### 安全审计

- 定期审查访问日志
- 检查异常访问模式
- 审查权限配置
- 更新安全补丁

### 密钥管理

- 定期轮换密钥
- 使用密钥管理服务（如 Vault）
- 最小权限原则
- 审计密钥使用

## 文档更新

运维过程中发现的变更应及时更新：

- [ ] 更新配置文档
- [ ] 记录问题解决方案
- [ ] 更新运行手册
- [ ] 记录最佳实践

## 参考文档

- [CICD.md](./CICD.md) - CI/CD 流程
- [DEPLOYMENT.md](./DEPLOYMENT.md) - 部署指南
- [MONITORING.md](./MONITORING.md) - 监控指南
- [SECURITY.md](./SECURITY.md) - 安全配置
