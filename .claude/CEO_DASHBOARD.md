# CEO 工作台

作为 CEO，你的职责是**制定规则、评审产出、确认关键决策**。

---

## 项目目标 (永远记住)

> **CEOAgent: AI 驱动的 CEO 决策支持系统**
> - 帮助 CEO 进行投资决策
> - 风险评估
> - 战略规划

---

## 当前阶段

```
██████████░░░░░░░░░░░░░░░░░░░░ Phase 0: 文档验证

目标: 通过文档验证所有逻辑，确保方向正确后再写代码
```

---

## 快速状态检查

```bash
# 查看待办任务
grep -E "^\- \[TODO\]" TASKS.md

# 查看阻塞任务
grep -E "^\- \[BLOCKED\]" TASKS.md

# 查看待决策项
grep -E "^\#\#\# \[PENDING\]" DECISIONS.md

# 查看待评审项
grep -E "^\#\#\# \[PENDING\]" REVIEWS.md

# 查看开放问题
grep -E "^\#\#\# \[OPEN\]" ISSUES.md

# 查看问题统计
grep -c "\[PENDING\]\|\[OPEN\]\|\[BLOCKED\]" TASKS.md DECISIONS.md ISSUES.md
```

---

## 团队启动命令

### 方式一: 多终端 (推荐)

打开 7 个终端，分别启动：

```bash
# Terminal 1: 产品经理
claude --prompt "阅读 .claude/roles/product_manager.md 并说'产品经理已就位'"

# Terminal 2: 架构师
claude --prompt "阅读 .claude/roles/architect.md 并说'架构师已就位'"

# Terminal 3: 开发经理
claude --prompt "阅读 .claude/roles/dev_manager.md 并说'开发经理已就位'"

# Terminal 4: 后端开发
claude --prompt "阅读 .claude/roles/backend_dev.md 并说'后端开发已就位'"

# Terminal 5: 前端开发
claude --prompt "阅读 .claude/roles/frontend_dev.md 并说'前端开发已就位'"

# Terminal 6: 测试工程师
claude --prompt "阅读 .claude/roles/tester.md 并说'测试工程师已就位'"

# Terminal 7: 运维工程师
claude --prompt "阅读 .claude/roles/devops.md 并说'运维工程师已就位'"
```

### 方式二: 按需启动

根据当前工作阶段启动相关角色：

```
需求阶段: PM + Arch
设计阶段: Arch + BE + FE
开发阶段: DM + BE + FE
测试阶段: QA + BE + FE
部署阶段: DevOps + DM
```

---

## CEO 每日工作流程

### 早晨 (15分钟)
```
1. 查看 TASKS.md 了解进度
2. 查看 DECISIONS.md 处理待决策
3. 查看 ISSUES.md 了解问题
```

### 工作中 (按需)
```
1. 评审 REVIEWS.md 中的文档
2. 在 DECISIONS.md 中做出决策
3. 在 QUESTIONS.md 中回答问题
4. 与相关 Agent 沟通指导
```

### 结束前 (10分钟)
```
1. 确认当天任务状态
2. 识别阻塞问题
3. 规划明天重点
```

---

## 常用决策模板

### 需求确认
```
我确认这个需求：
- 范围: [明确边界]
- 优先级: P0/P1/P2
- 额外要求: [如有]
```

### 技术决策
```
我选择选项 [X]：
- 理由: [为什么]
- 风险: [需要注意什么]
- 后续: [下一步做什么]
```

### 评审反馈
```
评审意见：
- 总体: 通过/需修改
- 问题: [具体问题]
- 建议: [改进建议]
```

---

## 文档目录速查

```
/
├── TASKS.md              # 任务看板 ⭐
├── DECISIONS.md          # CEO 决策 ⭐
├── REVIEWS.md            # 评审记录 ⭐
├── ISSUES.md             # 问题追踪
├── QUESTIONS.md          # 待澄清问题
├── CHANGELOG.md          # 变更日志
│
├── .claude/
│   ├── CEO_DASHBOARD.md  # 本文档
│   ├── TEAM_STRUCTURE.md # 团队结构
│   ├── MULTI_AGENT_GUIDE.md
│   └── roles/            # 角色定义
│
├── docs/
│   ├── product/          # PM 产出
│   │   ├── PRD_*.md
│   │   ├── stories/
│   │   └── acceptance/
│   │
│   ├── architecture/     # 架构师产出
│   │   ├── ADD_*.md
│   │   ├── api/
│   │   ├── models/
│   │   ├── adr/
│   │   └── diagrams/
│   │
│   ├── management/       # 开发经理产出
│   │   ├── tasks/
│   │   ├── iterations/
│   │   ├── reports/
│   │   └── RISKS.md
│   │
│   ├── backend/          # 后端产出
│   │   ├── api/
│   │   ├── models/
│   │   └── modules/
│   │
│   ├── frontend/         # 前端产出
│   │   ├── pages/
│   │   ├── components/
│   │   ├── flows/
│   │   └── STYLE_GUIDE.md
│   │
│   ├── testing/          # 测试产出
│   │   ├── plans/
│   │   ├── cases/
│   │   ├── checklists/
│   │   └── reports/
│   │
│   └── devops/           # 运维产出
│       ├── DEPLOY_ARCHITECTURE.md
│       ├── CICD_DESIGN.md
│       ├── DOCKER_DESIGN.md
│       ├── MONITORING.md
│       └── RUNBOOK.md
│
└── scenarios/            # 场景验证
    ├── 01_investment_decision.md
    ├── 02_risk_assessment.md
    └── 03_strategy_planning.md
```

---

## 关键提醒

1. **不要忘记项目目标** - 每次评审都要问：这是否帮助 CEO 做更好的决策？

2. **Phase 0 不写代码** - 所有设计都通过文档验证，逻辑完整后再进入 Phase 1

3. **快速决策** - 80% 信息时做决策，避免完美主义

4. **记录一切** - 所有决策和变更都要留痕

5. **定期同步** - 确保团队方向一致

---

## 项目成功标准

Phase 0 完成标准：
- [ ] 核心场景的 PRD 完成并评审通过
- [ ] 系统架构设计完成并评审通过
- [ ] API 规范定义完成
- [ ] 测试用例覆盖所有验收标准
- [ ] 部署方案设计完成
- [ ] 所有文档逻辑一致，无矛盾

Phase 1 进入条件：
- [ ] Phase 0 所有检查项通过
- [ ] CEO 确认可以开始编码
