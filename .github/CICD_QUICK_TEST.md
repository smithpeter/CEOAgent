# CI/CD 快速测试指南

本文档提供快速测试 CI/CD 配置的步骤。

## 本地验证

### 1. 运行验证脚本

```bash
# 验证所有配置
./scripts/validate-cicd-config.sh

# 测试工作流语法
./scripts/test-workflow-syntax.sh
```

### 2. 验证 YAML 语法

```bash
# 使用 Python 验证
python3 -c "
import yaml
import sys

files = [
    '.github/workflows/ci-cd.yml',
    '.github/workflows/codeql-analysis.yml',
    '.github/workflows/manual-deploy.yml',
    '.github/workflows/rollback.yml',
    '.github/workflows/release.yml',
    '.github/workflows/test-ci-config.yml',
    '.github/dependabot.yml'
]

for f in files:
    try:
        with open(f) as file:
            yaml.safe_load(file)
        print(f'✅ {f}')
    except Exception as e:
        print(f'❌ {f}: {e}')
        sys.exit(1)
"
```

### 3. 测试 Docker 构建

```bash
# 构建镜像（仅测试，不推送）
docker build -t ceoagent:test .

# 测试镜像运行
docker run --rm -p 8000:8000 ceoagent:test
```

### 4. 验证 Docker Compose

```bash
# 验证配置文件
docker-compose config

# 测试启动（可选）
# docker-compose up -d
```

## GitHub 验证

### 1. 推送代码触发工作流

```bash
# 创建测试分支
git checkout -b test/ci-cd-validation

# 做一个小改动
echo "# CI/CD Test" >> .github/TEST.md
git add .github/TEST.md
git commit -m "test: validate CI/CD workflow"

# 推送到 GitHub
git push origin test/ci-cd-validation

# 创建 PR 到 develop 分支
gh pr create --base develop --title "Test CI/CD" --body "Testing CI/CD workflows"
```

### 2. 查看工作流执行

1. 访问 GitHub 仓库的 Actions 页面
2. 查看以下工作流是否触发：
   - ✅ CI/CD Pipeline (ci-cd.yml)
   - ✅ CodeQL Analysis (codeql-analysis.yml)

### 3. 手动触发测试工作流

1. 进入 Actions 页面
2. 选择 "Test CI/CD Configuration"
3. 点击 "Run workflow"
4. 查看验证结果

## 测试清单

### ✅ 文件检查

- [ ] 所有工作流文件存在
- [ ] Dockerfile 存在且有效
- [ ] requirements.txt 存在
- [ ] requirements-dev.txt 存在
- [ ] docker-compose.yml 存在

### ✅ 语法检查

- [ ] 所有 YAML 文件语法正确
- [ ] 工作流文件通过验证
- [ ] Dockerfile 结构正确

### ✅ 功能测试

- [ ] 代码推送触发工作流
- [ ] PR 触发代码检查
- [ ] 测试通过
- [ ] Docker 镜像构建成功

### ✅ 部署测试（需要配置 Secrets）

- [ ] 开发环境部署成功
- [ ] 生产环境部署成功
- [ ] 健康检查通过
- [ ] 回滚功能正常

## 常见问题

### 问题 1: 工作流不触发

**检查**:
- 确认文件在 `.github/workflows/` 目录
- 检查文件扩展名是 `.yml` 或 `.yaml`
- 验证 YAML 语法正确
- 检查分支名称匹配触发器

### 问题 2: 测试失败

**检查**:
- 查看测试日志
- 确认依赖已安装
- 检查测试环境配置

### 问题 3: 构建失败

**检查**:
- Dockerfile 语法
- 依赖文件是否正确
- 构建上下文路径

## 下一步

完成本地验证后：

1. **配置 GitHub Secrets**（参考 CI_CD_SETUP_CHECKLIST.md）
2. **创建 GitHub Environments**
3. **推送代码到 develop 分支触发首次部署**
4. **验证部署结果**

## 参考

- [CI/CD 配置检查清单](./CI_CD_SETUP_CHECKLIST.md)
- [工作流说明](./workflows/README.md)
- [工作流总览](./workflows/SUMMARY.md)
