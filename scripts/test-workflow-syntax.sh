#!/bin/bash

# 工作流语法测试脚本
# 使用 GitHub Actions 的 act 工具或在线 API 验证

set -euo pipefail

echo "=========================================="
echo "GitHub Actions 工作流语法测试"
echo "=========================================="
echo ""

# 检查是否安装了 act（本地测试工具）
if command -v act &> /dev/null; then
    echo "✅ 检测到 act 工具，进行本地验证..."
    echo ""
    
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            echo "测试: $(basename $workflow)"
            if act workflow list --workflows "$workflow" > /dev/null 2>&1; then
                echo "  ✅ 语法正确"
            else
                echo "  ❌ 语法错误"
                exit 1
            fi
        fi
    done
    
    echo ""
    echo "✅ 所有工作流语法验证通过"
else
    echo "⚠️  act 工具未安装"
    echo ""
    echo "选项 1: 安装 act 进行本地测试"
    echo "  macOS: brew install act"
    echo "  Linux: 从 https://github.com/nektos/act/releases 下载"
    echo ""
    echo "选项 2: 使用在线验证"
    echo "  1. 推送到 GitHub"
    echo "  2. 在 Actions 页面查看工作流是否正常运行"
    echo ""
    echo "选项 3: 使用 GitHub CLI 验证"
    if command -v gh &> /dev/null; then
        echo "  运行: gh workflow list"
        gh workflow list 2>/dev/null || echo "  需要先登录: gh auth login"
    else
        echo "  安装: brew install gh"
    fi
fi

echo ""
echo "=========================================="
echo "手动验证步骤："
echo "=========================================="
echo "1. 检查工作流文件 YAML 语法"
echo "2. 推送到 GitHub 查看 Actions 是否触发"
echo "3. 运行 test-ci-config.yml 工作流验证配置"
echo ""
