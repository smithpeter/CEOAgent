# Multi-Agent 协作指南 (完整版)

## 团队概览

```
                         ┌─────────────┐
                         │    CEO      │
                         │   (你)      │
                         └──────┬──────┘
                                │
     ┌──────────────────────────┼──────────────────────────┐
     │                          │                          │
     ▼                          ▼                          ▼
┌─────────┐              ┌─────────────┐             ┌──────────┐
│   PM    │              │   Architect │             │ DevMgr   │
│ 产品经理 │              │    架构师   │             │ 开发经理  │
└────┬────┘              └──────┬──────┘             └────┬─────┘
     │                          │                         │
     │         ┌────────────────┼────────────────┐        │
     │         │                │                │        │
     │         ▼                ▼                ▼        │
     │    ┌─────────┐      ┌─────────┐     ┌─────────┐   │
     │    │   BE    │      │   FE    │     │   QA    │   │
     │    │ 后端开发 │      │ 前端开发 │     │  测试   │   │
     │    └─────────┘      └─────────┘     └─────────┘   │
     │                                                    │
     │                     ┌─────────┐                    │
     │                     │ DevOps  │                    │
     └────────────────────▶│  运维   │◀───────────────────┘
                           └─────────┘
```

---

## 角色职责与产出

| 角色 | 职责 | 核心产出 | 文档位置 | 角色定义 |
|------|------|---------|----------|---------|
| **PM** | 需求分析、用户故事 | PRD、用户故事、验收标准 | `docs/product/` | `.claude/roles/product_manager.md` |
| **Architect** | 架构设计、技术选型 | 架构图、API 规范、ADR | `docs/architecture/` | `.claude/roles/architect.md` |
| **DevMgr** | 任务拆解、进度管理 | 任务拆解、风险登记、进度报告 | `docs/management/` | `.claude/roles/dev_manager.md` |
| **BE** | 后端设计与实现 | API 详设、数据模型、伪代码 | `docs/backend/` | `.claude/roles/backend_dev.md` |
| **FE** | 前端设计与实现 | 页面设计、组件规划、交互流程 | `docs/frontend/` | `.claude/roles/frontend_dev.md` |
| **QA** | 测试计划与执行 | 测试计划、测试用例、缺陷报告 | `docs/testing/` | `.claude/roles/tester.md` |
| **DevOps** | 部署与运维 | 部署架构、CI/CD、运维手册 | `docs/devops/` | `.claude/roles/devops.md` |

---

## 核心文档索引

### 流程与规范

| 文档 | 用途 | 位置 |
|------|------|------|
| 评审流程 | 评审类型、检查清单、评审记录 | `REVIEWS.md` |
| 逻辑验证框架 | 验证层次、验证方法、检查点 | `docs/VALIDATION_LOGIC.md` |
| 需求追踪矩阵 | 需求追踪、文档关联、一致性检查 | `docs/product/REQUIREMENTS_TRACE.md` |
| 目标对齐机制 | 目标检查清单、目标回顾 | `docs/management/GOAL_ALIGNMENT.md` |

---

## 快速启动

### 启动全部团队 (7 终端)

```bash
# 打开 7 个终端窗口，分别执行：

# Terminal 1 - 产品经理
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/product_manager.md，你是产品经理。说'产品经理已就位'"

# Terminal 2 - 架构师
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/architect.md，你是架构师。说'架构师已就位'"

# Terminal 3 - 开发经理
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/dev_manager.md，你是开发经理。说'开发经理已就位'"

# Terminal 4 - 后端开发
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/backend_dev.md，你是后端开发。说'后端开发已就位'"

# Terminal 5 - 前端开发
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/frontend_dev.md，你是前端开发。说'前端开发已就位'"

# Terminal 6 - 测试工程师
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/tester.md，你是测试工程师。说'测试工程师已就位'"

# Terminal 7 - 运维工程师
cd /Users/zouyongming/dev/CEOAgent
claude --prompt "阅读 .claude/roles/devops.md，你是运维工程师。说'运维工程师已就位'"
```

### 按阶段启动

```bash
# 需求阶段 (2 角色)
# PM + Architect

# 设计阶段 (3 角色)
# Architect + BE + FE

# 评审阶段 (4 角色)
# PM + Architect + QA + DevOps

# 完整团队 (7 角色)
# 所有角色
```

---

## 协作文件说明

| 文件 | 用途 | 主要使用者 |
|------|------|-----------|
| `TASKS.md` | 任务看板 | DevMgr 维护，全员使用 |
| `DECISIONS.md` | CEO 决策记录 | CEO 决策，全员查看 |
| `REVIEWS.md` | 文档评审记录 | 全员参与 |
| `ISSUES.md` | 问题/缺陷追踪 | QA 创建，开发修复 |
| `QUESTIONS.md` | 待澄清问题 | 全员提问，CEO/PM 回答 |
| `CHANGELOG.md` | 变更日志 | 全员记录 |

---

## Phase 0 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      Phase 0: 文档验证                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐      │
│  │  需求 │───▶│  设计 │───▶│  评审 │───▶│  修订 │───▶│  确认 │      │
│  └──────┘    └──────┘    └──────┘    └──────┘    └──────┘      │
│     PM         Arch        全员       各角色       CEO          │
│               BE/FE                                              │
│               QA/DevOps                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    所有文档逻辑验证通过
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Phase 1: 代码实现                          │
└─────────────────────────────────────────────────────────────────┘
```

### 逻辑验证层次

```
层次1: 需求逻辑验证 (PM)
层次2: 架构逻辑验证 (Architect)
层次3: 设计逻辑验证 (BE/FE)
层次4: 测试逻辑验证 (QA)
层次5: 部署逻辑验证 (DevOps)
层次6: 端到端验证 (全员)
```

详见 `docs/VALIDATION_LOGIC.md`

---

## 典型协作场景

### 场景 1: 新功能开发

```
1. CEO 向 PM 提出需求
   CEO → PM: "我需要一个投资分析功能"

2. PM 编写 PRD 和用户故事
   PM: 创建 docs/product/PRD_investment_analysis.md
   PM: 完成逻辑验证检查点

3. PM 提交评审
   PM: 在 REVIEWS.md 添加评审请求

4. Architect 评估技术可行性
   Architect: 评审 PRD，提出技术意见

5. CEO 确认需求
   CEO: 在 DECISIONS.md 确认需求

6. Architect 设计架构
   Architect: 创建 docs/architecture/ADD_investment.md
   Architect: 完成逻辑验证检查点

7. DevMgr 拆解任务
   DevMgr: 更新 TASKS.md

8. BE/FE 设计详设
   BE: 创建 docs/backend/api/API_DETAIL_analyze.md
   FE: 创建 docs/frontend/pages/PAGE_dashboard.md
   BE/FE: 完成逻辑验证检查点

9. QA 设计测试用例
   QA: 创建 docs/testing/cases/TC_investment.md
   QA: 完成逻辑验证检查点

10. DevOps 设计部署方案
    DevOps: 更新 docs/devops/DEPLOY_ARCHITECTURE.md
    DevOps: 完成逻辑验证检查点

11. 全员评审
    全员: 在 REVIEWS.md 评审
    全员: 使用评审检查清单

12. 端到端逻辑验证
    全员: 进行端到端场景推演

13. CEO 最终确认
    CEO: 确认进入 Phase 1
```

### 场景 2: 处理阻塞问题

```
1. BE 发现技术问题
   BE: 在 QUESTIONS.md 记录问题

2. Architect 评估
   Architect: 提供技术建议

3. 如需 CEO 决策
   DevMgr: 在 DECISIONS.md 创建决策请求

4. CEO 决策
   CEO: 在 DECISIONS.md 做出决策

5. 继续工作
   BE: 按决策继续设计
```

### 场景 3: 目标偏离处理

```
1. 发现偏离
   任意角色: 在目标对齐检查中发现偏离

2. 记录偏离
   角色: 在 docs/management/GOAL_ALIGNMENT.md 记录

3. 分析影响
   DevMgr: 分析偏离原因和影响

4. CEO 决策
   CEO: 决定调整或保持

5. 执行调整
   相关角色: 按决策调整工作
```

---

## CEO 快速命令

```bash
# 查看所有待处理项
grep -rn "\[PENDING\]\|\[BLOCKED\]\|\[OPEN\]" *.md

# 查看今日变更
git diff --stat

# 查看文档结构
tree docs/ -L 2

# 快速状态检查
cat TASKS.md | head -50

# 查看评审状态
grep -A5 "\[PENDING\]" REVIEWS.md

# 查看目标对齐状态
cat docs/management/GOAL_ALIGNMENT.md | head -100
```

---

## 注意事项

1. **文档优先**: Phase 0 只产出文档，不写代码
2. **异步协作**: 通过文件协调，不需要同时在线
3. **留痕记录**: 所有决策和讨论都记录在文件中
4. **定期同步**: CEO 定期查看各文件状态
5. **质量把控**: 所有文档需要评审才能生效
6. **逻辑验证**: 所有产出物必须通过逻辑验证检查点
7. **目标对齐**: 所有工作必须与项目目标保持一致

---

## 常见问题

**Q: 如何知道谁在等我？**
A: 查看 TASKS.md 中 [BLOCKED] 状态的任务

**Q: 如何让其他角色知道我完成了？**
A: 更新 TASKS.md 中任务状态为 [DONE]

**Q: 有问题不确定找谁？**
A: 在 QUESTIONS.md 中记录，@相关角色

**Q: 如何请求 CEO 决策？**
A: 在 DECISIONS.md 中创建 [PENDING] 记录

**Q: 如何提交文档评审？**
A: 在 REVIEWS.md 中创建评审记录，使用评审模板

**Q: 如何确认工作与目标一致？**
A: 使用 docs/management/GOAL_ALIGNMENT.md 中的检查清单

**Q: 如何进行逻辑验证？**
A: 参考 docs/VALIDATION_LOGIC.md 中的验证方法和检查点
