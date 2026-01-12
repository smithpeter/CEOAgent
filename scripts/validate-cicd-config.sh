#!/bin/bash

# CI/CD 配置验证脚本
# 用于验证 GitHub Actions 工作流和相关配置

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CI/CD 配置验证脚本${NC}"
echo -e "${BLUE}========================================${NC}\n"

ERRORS=0
WARNINGS=0

# 检查函数
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${RED}❌${NC} $1 (文件不存在)"
        ((ERRORS++))
        return 1
    fi
}

check_optional_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} $1 (可选文件)"
        ((WARNINGS++))
        return 1
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅${NC} $1 已安装"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} $1 未安装 (可选)"
        ((WARNINGS++))
        return 1
    fi
}

# 1. 检查必要文件
echo -e "\n${BLUE}[1/6] 检查必要文件...${NC}"
check_file ".github/workflows/ci-cd.yml"
check_file ".github/workflows/codeql-analysis.yml"
check_file ".github/workflows/manual-deploy.yml"
check_file ".github/workflows/rollback.yml"
check_file ".github/workflows/release.yml"
check_file ".github/workflows/test-ci-config.yml"
check_file ".github/dependabot.yml"
check_file "Dockerfile"
check_file "requirements.txt"
check_file "pyproject.toml"
check_file "docker-compose.yml"

check_optional_file "requirements-dev.txt"
check_optional_file ".github/workflows/README.md"
check_optional_file ".github/CI_CD_SETUP_CHECKLIST.md"

# 2. 验证工作流文件语法
echo -e "\n${BLUE}[2/6] 验证工作流文件语法...${NC}"

if check_command "yamllint"; then
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            if yamllint "$workflow" > /dev/null 2>&1; then
                echo -e "${GREEN}✅${NC} $(basename $workflow)"
            else
                echo -e "${RED}❌${NC} $(basename $workflow) (语法错误)"
                yamllint "$workflow" || true
                ((ERRORS++))
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠️${NC} yamllint 未安装，跳过语法检查"
    echo -e "   安装: pip install yamllint"
fi

# 3. 验证 Dockerfile
echo -e "\n${BLUE}[3/6] 验证 Dockerfile...${NC}"

if check_command "hadolint"; then
    if hadolint Dockerfile > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Dockerfile 通过 hadolint 检查"
    else
        echo -e "${YELLOW}⚠️${NC} Dockerfile 有警告"
        hadolint Dockerfile || true
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠️${NC} hadolint 未安装，跳过 Dockerfile 检查"
    echo -e "   安装: brew install hadolint (macOS) 或从 https://github.com/hadolint/hadolint/releases 下载"
fi

# 检查 Dockerfile 基本结构
if grep -q "^FROM" Dockerfile; then
    echo -e "${GREEN}✅${NC} Dockerfile 包含 FROM 指令"
else
    echo -e "${RED}❌${NC} Dockerfile 缺少 FROM 指令"
    ((ERRORS++))
fi

if grep -q "^WORKDIR" Dockerfile; then
    echo -e "${GREEN}✅${NC} Dockerfile 包含 WORKDIR 指令"
else
    echo -e "${YELLOW}⚠️${NC} Dockerfile 缺少 WORKDIR 指令 (推荐)"
    ((WARNINGS++))
fi

# 4. 验证依赖文件
echo -e "\n${BLUE}[4/6] 验证依赖文件...${NC}"

if [ -f "requirements.txt" ]; then
    if python3 -m pip show pip > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} requirements.txt 格式检查"
        # 检查是否有常见错误
        if grep -q "^[^#-]" requirements.txt; then
            echo -e "${GREEN}✅${NC} requirements.txt 包含依赖项"
        else
            echo -e "${YELLOW}⚠️${NC} requirements.txt 可能为空"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠️${NC} Python pip 未安装，跳过依赖验证"
    fi
fi

if [ -f "requirements-dev.txt" ]; then
    echo -e "${GREEN}✅${NC} requirements-dev.txt 存在"
fi

# 5. 检查 GitHub Secrets 配置（提示）
echo -e "\n${BLUE}[5/6] GitHub Secrets 配置检查...${NC}"

SECRETS=(
    "KUBECONFIG_DEV:开发环境 Kubernetes 配置"
    "KUBECONFIG_PROD:生产环境 Kubernetes 配置"
    "ANTHROPIC_API_KEY:Claude API 密钥"
)

for secret_info in "${SECRETS[@]}"; do
    secret_name="${secret_info%%:*}"
    secret_desc="${secret_info##*:}"
    echo -e "${YELLOW}📋${NC} 检查 Secret: ${secret_name}"
    echo -e "   说明: ${secret_desc}"
    echo -e "   配置: GitHub 仓库 Settings > Secrets and variables > Actions"
done

# 6. 检查 Environments 配置（提示）
echo -e "\n${BLUE}[6/6] GitHub Environments 配置检查...${NC}"

ENVIRONMENTS=(
    "development:开发环境"
    "production:生产环境"
)

for env_info in "${ENVIRONMENTS[@]}"; do
    env_name="${env_info%%:*}"
    env_desc="${env_info##*:}"
    echo -e "${YELLOW}📋${NC} 检查 Environment: ${env_name}"
    echo -e "   说明: ${env_desc}"
    echo -e "   配置: GitHub 仓库 Settings > Environments"
done

# 总结
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}验证完成${NC}"
echo -e "${BLUE}========================================${NC}\n"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ 所有检查通过！${NC}\n"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ 必要检查通过${NC}"
    echo -e "${YELLOW}⚠️  有 $WARNINGS 个警告（非关键）${NC}\n"
    exit 0
else
    echo -e "${RED}❌ 发现 $ERRORS 个错误${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠️  还有 $WARNINGS 个警告${NC}"
    fi
    echo -e "\n请修复上述错误后重新运行此脚本。\n"
    exit 1
fi
