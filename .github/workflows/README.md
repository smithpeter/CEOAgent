# GitHub Actions 工作流

本目录包含项目的 CI/CD 自动化工作流配置。

## 工作流文件

### ci-cd.yml

完整的 CI/CD 流水线，包括：

- **代码质量检查**: Black, isort, flake8, mypy
- **单元测试**: pytest 多版本测试
- **安全扫描**: Safety, Bandit
- **镜像构建**: 多平台 Docker 镜像构建
- **自动部署**: 开发/生产环境自动部署
- **数据库迁移**: 自动运行迁移
- **性能测试**: k6 负载测试

## 工作流触发

- **Push 到 main**: 触发生产部署
- **Push 到 develop**: 触发开发部署
- **创建标签 v***: 触发生产部署
- **Pull Request**: 触发测试和检查

## 环境配置

需要在 GitHub 仓库 Settings > Secrets 中配置：

- `KUBECONFIG_DEV`: 开发环境 kubeconfig
- `KUBECONFIG_PROD`: 生产环境 kubeconfig
- `ANTHROPIC_API_KEY`: Claude API 密钥
- `DATABASE_URL_PROD`: 生产数据库 URL
- `SLACK_WEBHOOK`: Slack 通知（可选）

## 使用说明

详细使用说明请参考 [CICD.md](../CICD.md)。
