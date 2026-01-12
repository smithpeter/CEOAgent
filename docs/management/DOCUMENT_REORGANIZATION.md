# 文档重组方案

> **分析日期**: 2026-01-12
> **问题**: 主目录下有 40+ 个 Markdown 文件，过于混乱，难以导航和维护

---

## 一、当前问题分析

### 1.1 主目录文件统计

| 类别 | 数量 | 问题 |
|------|------|------|
| 后端相关 | 6 | 分散在根目录 |
| 架构相关 | 7 | 有重复内容 |
| 部署/运维相关 | 17 | 过多，应归类 |
| 计划相关 | 4 | 有声明废弃的文件 |
| 指南相关 | 5 | 分散 |
| 协作文件 | 6 | 应保留在根目录 |
| 配置文件 | 6 | 应保留在根目录 |

### 1.2 主要问题

1. **混乱**: 40+ 文件在根目录，难以找到需要的文档
2. **重复**: 多个文件内容相似（如 ARCHITECTURE.md 和 ARCHITECTURE_ENHANCED.md）
3. **过时**: 部分文件已声明废弃但仍在根目录
4. **不一致**: 命名规范不统一，有的用全名有的用缩写
5. **缺乏索引**: 没有文档导航，新人难以入手

---

## 二、重组方案

### 2.1 根目录保留文件（14 个）

```
/                              # 根目录
├── README.md                  # 项目说明（入口）
├── CLAUDE.md                  # AI Agent 指令
├── MASTER_PLAN.md             # 主计划（权威）
├── REQUIREMENTS.md            # 需求概述（引用）
│
├── # 协作文件（多角色协作使用）
├── TASKS.md                   # 任务看板
├── DECISIONS.md               # CEO 决策
├── REVIEWS.md                 # 评审记录
├── QUESTIONS.md               # 待澄清问题
├── ISSUES.md                  # 问题追踪
├── CHANGELOG.md               # 变更日志
│
├── # 配置文件
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── Dockerfile
├── docker-compose.yml
└── docker-compose.prod.yml
```

### 2.2 文档目录结构（重组后）

```
docs/
├── README.md                       # 文档索引（新建）
│
├── guides/                         # 快速指南
│   ├── START_HERE.md              # 从这里开始
│   ├── QUICK_START.md             # 快速开始
│   ├── QUICK_SETUP.md             # 快速设置
│   └── UPDATE_GUIDE.md            # 更新指南
│
├── product/                        # 产品文档
│   ├── PRD_decision_analysis.md
│   ├── USE_CASES.md               # ← 从根目录移入
│   ├── stories/
│   ├── acceptance/
│   └── REQUIREMENTS_TRACE.md
│
├── architecture/                   # 架构文档
│   ├── ARCHITECTURE.md            # ← 从根目录移入（主架构）
│   ├── ARCHITECTURE_ENHANCED.md   # ← 从根目录移入
│   ├── SKILL_ARCHITECTURE.md      # ← 从根目录移入
│   ├── MEMORY_SYSTEM.md           # ← 从根目录移入
│   ├── TECHNICAL_BLUEPRINT.md     # ← 从根目录移入
│   ├── API_DESIGN.md              # ← 从根目录移入
│   ├── INTEGRATION_GUIDE.md       # ← 从根目录移入
│   ├── adr/
│   ├── api/
│   ├── diagrams/
│   └── models/
│
├── backend/                        # 后端文档
│   ├── BACKEND_DEV_GUIDE.md       # ← 从根目录移入
│   ├── BACKEND_DEVELOPMENT.md     # ← 从根目录移入
│   ├── BACKEND_SPEC.md            # ← 从根目录移入
│   ├── BACKEND_TASKS.md           # ← 从根目录移入
│   ├── BACKEND_REVIEW.md          # ← 从根目录移入
│   ├── API_LIMIT_GUIDE.md         # ← 合并 API 限制相关
│   ├── api/
│   ├── models/
│   └── modules/
│
├── frontend/                       # 前端文档
│   ├── UI_DESIGN_GUIDE.md         # ← 从根目录移入
│   ├── pages/
│   ├── components/
│   └── flows/
│
├── devops/                         # 运维文档
│   ├── DEPLOYMENT.md              # ← 从根目录移入（主部署）
│   ├── SERVER_DEPLOYMENT.md       # ← 从根目录移入
│   ├── CICD.md                    # ← 从根目录移入
│   ├── CI_CD_TROUBLESHOOTING.md   # ← 从根目录移入
│   ├── MONITORING.md              # ← 从根目录移入
│   ├── OPERATIONS.md              # ← 从根目录移入
│   ├── PERFORMANCE.md             # ← 从根目录移入
│   ├── SECURITY.md                # ← 从根目录移入
│   ├── DOCKER_INSTALL.md          # ← 从根目录移入
│   └── setup/                     # 设置相关
│       ├── GCP_SSH_SETUP.md
│       ├── GCP_USER_INFO.md
│       ├── SSH_KEY_SETUP.md
│       ├── SSH_KEY_INFO.md
│       ├── GITHUB_SETUP.md
│       ├── GITHUB_SECRETS_SETUP.md
│       ├── GITHUB_SECRETS_QUICK.md
│       └── AUTO_PUSH_SETUP.md
│
├── management/                     # 项目管理
│   ├── GOAL_ALIGNMENT.md
│   ├── PHASE0_COMPLETION.md
│   ├── planning/                  # 计划文档
│   │   ├── DEVELOPMENT_PLAN.md    # ← 从根目录移入
│   │   ├── EXECUTION_PLAN.md      # ← 从根目录移入
│   │   └── AGILE_METHODOLOGY.md   # ← 从根目录移入
│   ├── iterations/
│   ├── reports/
│   └── tasks/
│
├── testing/                        # 测试文档
│   ├── VERIFICATION_CHECKLIST.md  # ← 从根目录移入
│   ├── DESIGN_VALIDATION.md       # ← 从根目录移入
│   ├── plans/
│   ├── cases/
│   ├── checklists/
│   │   └── WEEKLY_CHECKLIST.md    # ← 从根目录移入
│   └── reports/
│
├── validation/                     # 验证记录
│   └── VALIDATION_REPORT.md
│
└── VALIDATION_LOGIC.md             # 验证框架
```

---

## 三、移动清单

### 3.1 移动到 docs/guides/

| 源文件 | 目标文件 |
|--------|---------|
| `START_HERE.md` | `docs/guides/START_HERE.md` |
| `QUICK_START.md` | `docs/guides/QUICK_START.md` |
| `QUICK_SETUP.md` | `docs/guides/QUICK_SETUP.md` |
| `UPDATE_CLAUDE_CODE.md` | `docs/guides/UPDATE_GUIDE.md` |

### 3.2 移动到 docs/architecture/

| 源文件 | 目标文件 |
|--------|---------|
| `ARCHITECTURE.md` | `docs/architecture/ARCHITECTURE.md` |
| `ARCHITECTURE_ENHANCED.md` | `docs/architecture/ARCHITECTURE_ENHANCED.md` |
| `SKILL_ARCHITECTURE.md` | `docs/architecture/SKILL_ARCHITECTURE.md` |
| `MEMORY_SYSTEM.md` | `docs/architecture/MEMORY_SYSTEM.md` |
| `TECHNICAL_BLUEPRINT.md` | `docs/architecture/TECHNICAL_BLUEPRINT.md` |
| `API_DESIGN.md` | `docs/architecture/API_DESIGN.md` |
| `INTEGRATION_GUIDE.md` | `docs/architecture/INTEGRATION_GUIDE.md` |

### 3.3 移动到 docs/backend/

| 源文件 | 目标文件 |
|--------|---------|
| `BACKEND_DEV_GUIDE.md` | `docs/backend/BACKEND_DEV_GUIDE.md` |
| `BACKEND_DEVELOPMENT.md` | `docs/backend/BACKEND_DEVELOPMENT.md` |
| `BACKEND_SPEC.md` | `docs/backend/BACKEND_SPEC.md` |
| `BACKEND_TASKS.md` | `docs/backend/BACKEND_TASKS.md` |
| `BACKEND_REVIEW.md` | `docs/backend/BACKEND_REVIEW.md` |
| `API_LIMIT_CONFIGURATION.md` | `docs/backend/API_LIMIT_GUIDE.md` |
| `CLAUDE_API_LIMIT_GUIDE.md` | 合并到上述文件 |

### 3.4 移动到 docs/frontend/

| 源文件 | 目标文件 |
|--------|---------|
| `UI_DESIGN_GUIDE.md` | `docs/frontend/UI_DESIGN_GUIDE.md` |

### 3.5 移动到 docs/devops/

| 源文件 | 目标文件 |
|--------|---------|
| `DEPLOYMENT.md` | `docs/devops/DEPLOYMENT.md` |
| `SERVER_DEPLOYMENT.md` | `docs/devops/SERVER_DEPLOYMENT.md` |
| `CICD.md` | `docs/devops/CICD.md` |
| `CI_CD_TROUBLESHOOTING.md` | `docs/devops/CI_CD_TROUBLESHOOTING.md` |
| `MONITORING.md` | `docs/devops/MONITORING.md` |
| `OPERATIONS.md` | `docs/devops/OPERATIONS.md` |
| `PERFORMANCE.md` | `docs/devops/PERFORMANCE.md` |
| `SECURITY.md` | `docs/devops/SECURITY.md` |
| `DOCKER_INSTALL.md` | `docs/devops/DOCKER_INSTALL.md` |
| `GCP_SSH_SETUP.md` | `docs/devops/setup/GCP_SSH_SETUP.md` |
| `GCP_USER_INFO.md` | `docs/devops/setup/GCP_USER_INFO.md` |
| `SSH_KEY_SETUP.md` | `docs/devops/setup/SSH_KEY_SETUP.md` |
| `SSH_KEY_INFO.md` | `docs/devops/setup/SSH_KEY_INFO.md` |
| `GITHUB_SETUP.md` | `docs/devops/setup/GITHUB_SETUP.md` |
| `GITHUB_SECRETS_SETUP.md` | `docs/devops/setup/GITHUB_SECRETS_SETUP.md` |
| `GITHUB_SECRETS_QUICK.md` | `docs/devops/setup/GITHUB_SECRETS_QUICK.md` |
| `AUTO_PUSH_SETUP.md` | `docs/devops/setup/AUTO_PUSH_SETUP.md` |

### 3.6 移动到 docs/management/planning/

| 源文件 | 目标文件 |
|--------|---------|
| `DEVELOPMENT_PLAN.md` | `docs/management/planning/DEVELOPMENT_PLAN.md` |
| `EXECUTION_PLAN.md` | `docs/management/planning/EXECUTION_PLAN.md` |
| `AGILE_AGENT_METHODOLOGY.md` | `docs/management/planning/AGILE_METHODOLOGY.md` |

### 3.7 移动到 docs/testing/

| 源文件 | 目标文件 |
|--------|---------|
| `VERIFICATION_CHECKLIST.md` | `docs/testing/VERIFICATION_CHECKLIST.md` |
| `DESIGN_AND_VALIDATION_README.md` | `docs/testing/DESIGN_VALIDATION.md` |
| `WEEKLY_CHECKLIST.md` | `docs/testing/checklists/WEEKLY_CHECKLIST.md` |

### 3.8 移动到 docs/product/

| 源文件 | 目标文件 |
|--------|---------|
| `USE_CASES.md` | `docs/product/USE_CASES.md` |

---

## 四、新建文档索引

需要创建 `docs/README.md` 作为文档索引，帮助导航。

---

## 五、执行计划

### 5.1 执行步骤

1. **创建目录结构** - 创建缺失的目录
2. **移动文件** - 按清单移动文件
3. **更新引用** - 更新文档内部的相互引用
4. **创建索引** - 创建 docs/README.md
5. **更新 README** - 更新项目主 README
6. **验证** - 检查所有链接有效

### 5.2 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 链接失效 | 中 | 批量搜索替换 |
| AI Agent 找不到文档 | 低 | 更新 CLAUDE.md |
| 开发者困惑 | 低 | 在根目录保留 README 说明 |

---

## 六、CEO 决策

请 CEO 确认：

- [ ] 是否执行文档重组？
- [ ] 是否有需要保留在根目录的文件？
- [ ] 是否有其他建议？

---

## 更新日志

| 日期 | 修改内容 | 修改人 |
|------|---------|--------|
| 2026-01-12 | 创建文档重组方案 | - |
