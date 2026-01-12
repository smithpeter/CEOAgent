# CEOAgent 文档索引

> 本文档是 CEOAgent 项目所有文档的导航索引。

---

## 快速导航

| 需求 | 文档 |
|------|------|
| 🚀 **新手入门** | [快速开始](guides/START_HERE.md) |
| 📋 **了解需求** | [产品需求](product/PRD_decision_analysis.md) |
| 🏗️ **了解架构** | [系统架构](architecture/ARCHITECTURE.md) |
| 💻 **后端开发** | [后端开发指南](backend/BACKEND_DEV_GUIDE.md) |
| 🎨 **前端开发** | [UI 设计指南](frontend/UI_DESIGN_GUIDE.md) |
| 🚢 **部署运维** | [部署指南](devops/DEPLOYMENT.md) |
| 🧪 **测试验证** | [验证清单](testing/VERIFICATION_CHECKLIST.md) |

---

## 目录结构

```
docs/
├── guides/                 # 快速指南
├── product/                # 产品文档
├── architecture/           # 架构文档
├── backend/                # 后端文档
├── frontend/               # 前端文档
├── devops/                 # 运维文档
├── management/             # 项目管理
├── testing/                # 测试文档
└── validation/             # 验证记录
```

---

## 一、快速指南 (`guides/`)

新手入门和快速参考。

| 文档 | 说明 |
|------|------|
| [START_HERE.md](guides/START_HERE.md) | 从这里开始 |
| [QUICK_START.md](guides/QUICK_START.md) | 快速开始 |
| [QUICK_SETUP.md](guides/QUICK_SETUP.md) | 快速设置 |
| [UPDATE_GUIDE.md](guides/UPDATE_GUIDE.md) | 更新指南 |

---

## 二、产品文档 (`product/`)

产品需求、用户故事和验收标准。

| 文档 | 说明 |
|------|------|
| [PRD_decision_analysis.md](product/PRD_decision_analysis.md) | 决策分析 PRD |
| [USE_CASES.md](product/USE_CASES.md) | 用例定义 |
| [REQUIREMENTS_TRACE.md](product/REQUIREMENTS_TRACE.md) | 需求追踪矩阵 |
| [stories/](product/stories/) | 用户故事目录 |

---

## 三、架构文档 (`architecture/`)

系统架构、技术选型和 API 设计。

| 文档 | 说明 |
|------|------|
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | 系统架构设计（主文档） |
| [ARCHITECTURE_ENHANCED.md](architecture/ARCHITECTURE_ENHANCED.md) | 架构优化方案 |
| [SKILL_ARCHITECTURE.md](architecture/SKILL_ARCHITECTURE.md) | Skill 架构设计 |
| [MEMORY_SYSTEM.md](architecture/MEMORY_SYSTEM.md) | Memory 系统设计 |
| [TECHNICAL_BLUEPRINT.md](architecture/TECHNICAL_BLUEPRINT.md) | 技术蓝图 |
| [API_DESIGN.md](architecture/API_DESIGN.md) | API 设计规范 |
| [INTEGRATION_GUIDE.md](architecture/INTEGRATION_GUIDE.md) | 集成指南 |
| [adr/](architecture/adr/) | 架构决策记录 |

---

## 四、后端文档 (`backend/`)

后端开发规范、API 详设和数据模型。

| 文档 | 说明 |
|------|------|
| [BACKEND_DEV_GUIDE.md](backend/BACKEND_DEV_GUIDE.md) | 后端开发指南 |
| [BACKEND_DEVELOPMENT.md](backend/BACKEND_DEVELOPMENT.md) | 后端开发准备 |
| [BACKEND_SPEC.md](backend/BACKEND_SPEC.md) | 后端规范 |
| [BACKEND_TASKS.md](backend/BACKEND_TASKS.md) | 后端任务 |
| [BACKEND_REVIEW.md](backend/BACKEND_REVIEW.md) | 后端评审 |
| [API_LIMIT_GUIDE.md](backend/API_LIMIT_GUIDE.md) | API 限制指南 |
| [CLAUDE_API_LIMIT.md](backend/CLAUDE_API_LIMIT.md) | Claude API 限制 |

---

## 五、前端文档 (`frontend/`)

UI 设计、组件规划和交互流程。

| 文档 | 说明 |
|------|------|
| [UI_DESIGN_GUIDE.md](frontend/UI_DESIGN_GUIDE.md) | UI 设计指南 |
| [pages/](frontend/pages/) | 页面设计 |
| [components/](frontend/components/) | 组件设计 |
| [flows/](frontend/flows/) | 交互流程 |

---

## 六、运维文档 (`devops/`)

部署、CI/CD、监控和运维。

| 文档 | 说明 |
|------|------|
| [DEPLOYMENT.md](devops/DEPLOYMENT.md) | 部署架构（主文档） |
| [SERVER_DEPLOYMENT.md](devops/SERVER_DEPLOYMENT.md) | 服务器部署 |
| [CICD.md](devops/CICD.md) | CI/CD 指南 |
| [CI_CD_TROUBLESHOOTING.md](devops/CI_CD_TROUBLESHOOTING.md) | CI/CD 故障排除 |
| [MONITORING.md](devops/MONITORING.md) | 监控方案 |
| [OPERATIONS.md](devops/OPERATIONS.md) | 运维手册 |
| [PERFORMANCE.md](devops/PERFORMANCE.md) | 性能优化 |
| [SECURITY.md](devops/SECURITY.md) | 安全指南 |
| [DOCKER_INSTALL.md](devops/DOCKER_INSTALL.md) | Docker 安装 |
| [setup/](devops/setup/) | 环境设置指南 |

### 环境设置 (`devops/setup/`)

| 文档 | 说明 |
|------|------|
| [GCP_SSH_SETUP.md](devops/setup/GCP_SSH_SETUP.md) | GCP SSH 设置 |
| [GITHUB_SETUP.md](devops/setup/GITHUB_SETUP.md) | GitHub 设置 |
| [GITHUB_SECRETS_SETUP.md](devops/setup/GITHUB_SECRETS_SETUP.md) | GitHub Secrets |
| [SSH_KEY_SETUP.md](devops/setup/SSH_KEY_SETUP.md) | SSH Key 设置 |
| [AUTO_PUSH_SETUP.md](devops/setup/AUTO_PUSH_SETUP.md) | 自动推送设置 |

---

## 七、项目管理 (`management/`)

项目计划、进度和目标管理。

| 文档 | 说明 |
|------|------|
| [GOAL_ALIGNMENT.md](management/GOAL_ALIGNMENT.md) | 目标对齐机制 |
| [PHASE0_COMPLETION.md](management/PHASE0_COMPLETION.md) | Phase 0 完成度 |
| [DOCUMENT_REORGANIZATION.md](management/DOCUMENT_REORGANIZATION.md) | 文档重组方案 |
| [planning/](management/planning/) | 计划文档 |

### 计划文档 (`management/planning/`)

| 文档 | 说明 |
|------|------|
| [DEVELOPMENT_PLAN.md](management/planning/DEVELOPMENT_PLAN.md) | 开发计划 |
| [EXECUTION_PLAN.md](management/planning/EXECUTION_PLAN.md) | 执行计划 |
| [AGILE_METHODOLOGY.md](management/planning/AGILE_METHODOLOGY.md) | 敏捷方法论 |

---

## 八、测试文档 (`testing/`)

测试计划、用例和验证。

| 文档 | 说明 |
|------|------|
| [VERIFICATION_CHECKLIST.md](testing/VERIFICATION_CHECKLIST.md) | 验证清单 |
| [DESIGN_VALIDATION.md](testing/DESIGN_VALIDATION.md) | 设计验证 |
| [checklists/](testing/checklists/) | 检查清单 |
| [plans/](testing/plans/) | 测试计划 |
| [cases/](testing/cases/) | 测试用例 |
| [reports/](testing/reports/) | 测试报告 |

---

## 九、验证记录 (`validation/`)

逻辑验证框架和验证报告。

| 文档 | 说明 |
|------|------|
| [VALIDATION_LOGIC.md](VALIDATION_LOGIC.md) | 逻辑验证框架 |
| [VALIDATION_REPORT.md](validation/VALIDATION_REPORT.md) | 验证报告 |

---

## 根目录核心文件

| 文件 | 说明 |
|------|------|
| `README.md` | 项目说明 |
| `CLAUDE.md` | AI Agent 指令 |
| `MASTER_PLAN.md` | 主计划（权威） |
| `REQUIREMENTS.md` | 需求概述 |
| `TASKS.md` | 任务看板 |
| `DECISIONS.md` | CEO 决策 |
| `REVIEWS.md` | 评审记录 |
| `QUESTIONS.md` | 待澄清问题 |
| `ISSUES.md` | 问题追踪 |
| `CHANGELOG.md` | 变更日志 |

---

## 更新日志

| 日期 | 修改内容 |
|------|---------|
| 2026-01-12 | 创建文档索引，完成文档重组 |
