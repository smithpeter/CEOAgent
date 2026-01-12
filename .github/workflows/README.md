# GitHub Actions CI/CD 工作流说明

本文档说明项目中配置的 GitHub Actions CI/CD 工作流。

## 工作流概览

### 1. CI/CD Pipeline (`ci-cd.yml`)

主要的 CI/CD 工作流，包含以下阶段：

#### 代码质量检查 (Lint and Format)
- **触发条件**: 所有 Push 和 PR
- **工具**: ruff (代码检查和格式化), mypy (类型检查)
- **并行执行**: ✅

#### 单元测试 (Test)
- **触发条件**: 所有 Push 和 PR
- **Python 版本**: 3.11, 3.12
- **服务**: PostgreSQL 15, Redis 7
- **覆盖率要求**: ≥ 80%
- **报告**: 上传到 Codecov

#### 安全扫描 (Security Scan)
- **触发条件**: 所有 Push 和 PR
- **工具**: Safety (依赖漏洞), Bandit (代码安全)
- **报告**: 上传为 Artifact

#### Docker 镜像构建 (Build)
- **触发条件**: Push 到 main/develop 分支（非 PR）
- **平台**: linux/amd64, linux/arm64
- **注册表**: GitHub Container Registry (ghcr.io)
- **标签策略**:
  - 分支名: `main`, `develop`
  - SHA: `main-abc123`, `develop-abc123`
  - 语义版本: `v1.0.0`, `v1.0`, `v1`
  - 最新: `latest` (仅 main 分支)

#### 部署到开发环境 (Deploy Dev)
- **触发条件**: Push 到 `develop` 分支
- **命名空间**: `ceoagent-dev`
- **步骤**:
  1. 配置 kubectl
  2. 更新 Deployment
  3. 等待滚动更新
  4. 运行健康检查
  5. 发送通知

#### 部署到生产环境 (Deploy Prod)
- **触发条件**: Push 到 `main` 分支或标签 `v*`
- **命名空间**: `ceoagent`
- **步骤**:
  1. 创建备份
  2. 更新 Deployment
  3. 等待滚动更新（最长 5 分钟）
  4. 运行健康检查
  5. 失败时自动回滚
  6. 发送通知

#### 性能测试 (Performance Test)
- **触发条件**: 开发环境部署成功后
- **工具**: k6
- **状态**: 待实现

### 2. CodeQL Analysis (`codeql-analysis.yml`)

代码安全分析工作流：

- **触发条件**: 
  - Push 到 main/develop
  - PR 到 main/develop
  - 每日定时 (凌晨 2 点)
- **语言**: Python
- **扫描**: 安全漏洞和质量问题

### 3. Manual Deployment (`manual-deploy.yml`)

手动部署工作流，支持：

- **触发方式**: 手动触发 (workflow_dispatch)
- **选项**:
  - 环境: development / production
  - 镜像标签: 可选，留空使用最新 SHA
- **用途**: 紧急部署、回滚、测试特定版本

### 4. Manual Deployment (`manual-deploy.yml`)

手动部署工作流，支持：

- **触发方式**: 手动触发 (workflow_dispatch)
- **选项**:
  - 环境: development / production
  - 镜像标签: 可选，留空使用最新 SHA
- **用途**: 紧急部署、回滚、测试特定版本

### 5. Rollback (`rollback.yml`)

回滚工作流：

- **触发方式**: 手动触发 (workflow_dispatch)
- **选项**:
  - 环境: development / production
  - 版本: 可选，留空回滚到上一个版本
- **功能**:
  - 显示部署历史
  - 回滚到指定版本
  - 验证回滚结果
  - 健康检查

### 6. Release (`release.yml`)

发布工作流：

- **触发方式**: 
  - 推送标签 `v*.*.*` (如 `v1.0.0`)
  - 手动触发（输入版本号）
- **功能**:
  - 创建 GitHub Release
  - 生成变更日志
  - 构建并推送 Docker 镜像（多个标签）
  - 发送通知

### 7. Test CI/CD Configuration (`test-ci-config.yml`)

CI/CD 配置验证工作流：

- **触发方式**: 
  - 手动触发
  - PR 修改 CI/CD 相关文件时自动触发
- **功能**:
  - 验证工作流文件语法
  - 验证 Dockerfile
  - 验证 requirements 文件
  - 测试 Docker 构建
  - 生成配置摘要

### 8. Dependabot (`dependabot.yml`)

依赖自动更新：

- **Python 依赖**: 每周一 9:00
- **Docker 依赖**: 每周一 9:00
- **GitHub Actions**: 每月
- **分组**: 开发依赖、生产依赖分别分组

## 配置要求

### GitHub Secrets

需要在 GitHub 仓库 Settings > Secrets and variables > Actions 中配置：

#### 必需
- `KUBECONFIG_DEV`: 开发环境 kubeconfig (base64 编码)
- `KUBECONFIG_PROD`: 生产环境 kubeconfig (base64 编码)
- `ANTHROPIC_API_KEY`: Claude API 密钥（用于测试）

#### 可选
- `SLACK_WEBHOOK`: Slack Webhook URL（用于通知）

### GitHub Environments

需要在仓库 Settings > Environments 中创建：

#### Development
- **名称**: `development`
- **URL**: `https://dev-api.ceoagent.com`
- **保护规则**: 可选

#### Production
- **名称**: `production`
- **URL**: `https://api.ceoagent.com`
- **保护规则**: 建议启用审批

### 生成 KUBECONFIG Secret

```bash
# 导出开发环境 kubeconfig
kubectl config view --flatten --minify --context=dev-context > kubeconfig-dev.yaml
cat kubeconfig-dev.yaml | base64 | pbcopy  # macOS
# 将 base64 内容添加到 GitHub Secrets 的 KUBECONFIG_DEV

# 导出生产环境 kubeconfig
kubectl config view --flatten --minify --context=prod-context > kubeconfig-prod.yaml
cat kubeconfig-prod.yaml | base64 | pbcopy
# 将 base64 内容添加到 GitHub Secrets 的 KUBECONFIG_PROD
```

## 使用指南

### 自动部署

1. **开发环境**: 推送代码到 `develop` 分支
2. **生产环境**: 推送代码到 `main` 分支或创建标签 `v*`

### 手动部署

1. 进入 Actions 页面
2. 选择 "Manual Deployment" 工作流
3. 点击 "Run workflow"
4. 选择环境和镜像标签
5. 点击 "Run workflow" 按钮

### 回滚部署

1. 进入 Actions 页面
2. 选择 "Rollback Deployment" 工作流
3. 点击 "Run workflow"
4. 选择环境
5. （可选）输入要回滚到的版本号
6. 点击 "Run workflow" 按钮

### 创建发布

**方式 1: 使用 Git 标签**
```bash
git tag v1.0.0
git push origin v1.0.0
```

**方式 2: 手动触发**
1. 进入 Actions 页面
2. 选择 "Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号（如 `v1.0.0`）
5. 点击 "Run workflow" 按钮

### 验证配置

1. 进入 Actions 页面
2. 选择 "Test CI/CD Configuration" 工作流
3. 点击 "Run workflow"
4. 查看验证结果摘要

### 查看工作流状态

```bash
# 使用 GitHub CLI
gh run list
gh run view <run-id>
gh run watch <run-id>
```

## 故障排查

### 构建失败

1. 查看 Actions 日志
2. 检查 Dockerfile 是否有效
3. 验证依赖是否安装成功

### 部署失败

1. 检查 Kubernetes 连接
2. 验证 kubeconfig 是否正确
3. 查看 Pod 日志：
   ```bash
   kubectl logs -n ceoagent deployment/ceoagent-api
   ```

### 健康检查失败

1. 检查应用是否正常启动
2. 验证 `/health` 端点是否可访问
3. 查看应用日志排查错误

### 回滚

```bash
# 手动回滚
kubectl rollout undo deployment/ceoagent-api -n ceoagent

# 或使用手动部署工作流回滚到特定版本
```

## 最佳实践

1. **小步提交**: 频繁提交，快速反馈
2. **代码审查**: 所有代码必须经过 PR 审查
3. **测试优先**: 确保测试通过后再合并
4. **版本标签**: 使用语义化版本号 (`v1.0.0`)
5. **监控告警**: 配置 Slack 通知及时发现问题

## 相关文档

- [CICD.md](../../CICD.md) - 完整的 CI/CD 文档
- [DEPLOYMENT.md](../../DEPLOYMENT.md) - 部署架构指南
- [MONITORING.md](../../MONITORING.md) - 监控指南
