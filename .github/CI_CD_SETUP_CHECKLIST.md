# CI/CD 配置检查清单

本文档用于验证 GitHub Actions CI/CD 配置是否完整。

## ✅ 已创建的文件

- [x] `.github/workflows/ci-cd.yml` - 主要 CI/CD 工作流
- [x] `.github/workflows/codeql-analysis.yml` - 代码安全分析
- [x] `.github/workflows/manual-deploy.yml` - 手动部署工作流
- [x] `.github/dependabot.yml` - 依赖自动更新
- [x] `.github/workflows/README.md` - 工作流说明文档

## 🔧 需要配置的项目

### 1. GitHub Secrets

进入仓库 Settings > Secrets and variables > Actions，添加以下 Secrets：

#### 必需 Secrets

- [ ] `KUBECONFIG_DEV`
  - 描述: 开发环境 Kubernetes 配置（base64 编码）
  - 生成方式:
    ```bash
    kubectl config view --flatten --minify --context=YOUR_DEV_CONTEXT > kubeconfig-dev.yaml
    cat kubeconfig-dev.yaml | base64 | pbcopy  # macOS
    # Linux: cat kubeconfig-dev.yaml | base64 | xclip
    ```

- [ ] `KUBECONFIG_PROD`
  - 描述: 生产环境 Kubernetes 配置（base64 编码）
  - 生成方式: 同上，替换为生产环境上下文

- [ ] `ANTHROPIC_API_KEY`
  - 描述: Claude API 密钥（用于测试）
  - 获取方式: 从 Anthropic 控制台获取

#### 可选 Secrets

- [ ] `SLACK_WEBHOOK`
  - 描述: Slack Webhook URL（用于部署通知）
  - 获取方式: Slack 应用配置中创建 Incoming Webhook

### 2. GitHub Environments

进入仓库 Settings > Environments，创建以下环境：

- [ ] `development`
  - URL: `https://dev-api.ceoagent.com` (根据实际情况修改)
  - Protection rules: 可选

- [ ] `production`
  - URL: `https://api.ceoagent.com` (根据实际情况修改)
  - Protection rules: 建议启用 Required reviewers

### 3. Kubernetes 集群配置

#### 开发环境

```bash
# 创建命名空间
kubectl create namespace ceoagent-dev

# 创建 Secret（根据实际情况修改）
kubectl create secret generic ceoagent-secrets \
  --from-literal=database-url='postgresql://...' \
  --from-literal=anthropic-api-key='sk-ant-...' \
  -n ceoagent-dev

# 应用 ConfigMap（如果存在）
kubectl apply -f k8s/base/configmap.yaml -n ceoagent-dev

# 应用 Deployment（需要先修改镜像地址）
kubectl apply -f k8s/base/deployment.yaml -n ceoagent-dev
```

#### 生产环境

```bash
# 创建命名空间
kubectl create namespace ceoagent

# 创建 Secret
kubectl create secret generic ceoagent-secrets \
  --from-literal=database-url='postgresql://...' \
  --from-literal=anthropic-api-key='sk-ant-...' \
  -n ceoagent

# 应用配置
kubectl apply -f k8s/base/configmap.yaml -n ceoagent
kubectl apply -f k8s/base/deployment.yaml -n ceoagent
```

### 4. 代码仓库设置

- [ ] 确保 `main` 和 `develop` 分支存在
- [ ] 确认 GitHub Actions 已启用（Settings > Actions > General）
- [ ] 配置分支保护规则（建议）:
  - `main`: 需要 PR 审查、状态检查通过
  - `develop`: 需要状态检查通过

### 5. 依赖和工具验证

- [ ] 验证 `requirements.txt` 存在且包含所有必需的依赖
- [ ] 确认 Dockerfile 可以正常构建
- [ ] 验证测试可以通过: `pytest tests/`

## 🧪 测试 CI/CD 流程

### 1. 测试代码质量检查

创建测试 PR：

```bash
# 创建测试分支
git checkout -b test/ci-cd-lint
# 做一些小的代码修改
git commit -m "test: CI/CD lint check"
git push origin test/ci-cd-lint
# 创建 PR 到 develop 分支
```

验证：
- [ ] Lint 工作流成功运行
- [ ] 测试工作流成功运行
- [ ] 安全扫描工作流成功运行

### 2. 测试构建

推送到 develop 分支：

```bash
git checkout develop
git merge test/ci-cd-lint
git push origin develop
```

验证：
- [ ] Docker 镜像成功构建
- [ ] 镜像推送到 GHCR
- [ ] 部署到开发环境成功

### 3. 测试生产部署

推送到 main 分支或创建标签：

```bash
# 方式 1: 推送到 main
git checkout main
git merge develop
git push origin main

# 方式 2: 创建标签
git tag v1.0.0
git push origin v1.0.0
```

验证：
- [ ] 镜像构建成功
- [ ] 部署到生产环境成功
- [ ] 健康检查通过

### 4. 测试手动部署

1. 进入 GitHub Actions 页面
2. 选择 "Manual Deployment" 工作流
3. 点击 "Run workflow"
4. 选择环境和镜像标签

验证：
- [ ] 手动部署成功
- [ ] 健康检查通过

## 🔍 常见问题排查

### 问题 1: KUBECONFIG Secret 配置错误

**症状**: kubectl 连接失败

**解决**:
1. 重新生成 base64 编码的 kubeconfig
2. 确保包含正确的上下文和认证信息
3. 验证 kubeconfig 文件格式正确

### 问题 2: 镜像拉取失败

**症状**: ImagePullBackOff 错误

**解决**:
1. 检查镜像标签是否正确
2. 验证 GitHub Container Registry 权限
3. 确保 Deployment 中镜像地址正确

### 问题 3: 健康检查失败

**症状**: Pod 无法通过健康检查

**解决**:
1. 检查应用是否正确启动
2. 验证 `/health` 端点是否可访问
3. 查看 Pod 日志: `kubectl logs -n <namespace> <pod-name>`

### 问题 4: 测试覆盖率低于 80%

**症状**: 覆盖率检查失败

**解决**:
1. 增加测试覆盖
2. 检查测试是否正常运行
3. 验证 coverage.xml 文件生成正确

## 📊 监控指标

建议监控以下指标：

- **构建成功率**: 目标 > 95%
- **部署时间**: 目标 < 10 分钟
- **测试执行时间**: 目标 < 5 分钟
- **覆盖率**: 目标 ≥ 80%

## 📚 相关文档

- [工作流说明](./workflows/README.md)
- [CI/CD 文档](../../CICD.md)
- [部署指南](../../DEPLOYMENT.md)
- [监控指南](../../MONITORING.md)

## ✅ 完成检查

完成所有配置后，请确认：

- [ ] 所有 GitHub Secrets 已配置
- [ ] 所有 GitHub Environments 已创建
- [ ] Kubernetes 集群已配置（dev 和 prod）
- [ ] 代码质量检查通过
- [ ] 构建流程正常
- [ ] 部署流程正常
- [ ] 健康检查通过
- [ ] 通知功能正常（如配置了 Slack）

---

**最后更新**: 2024-01-XX  
**维护者**: CEOAgent Team
