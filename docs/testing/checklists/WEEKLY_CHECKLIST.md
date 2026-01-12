# 每周执行检查清单

## Week 0：场景验证（当前周）

### 目标
在写代码之前，用对话验证 Claude 能完成核心任务。

### 每日任务

#### Day 1：定义场景
- [ ] 确定 3 个最核心的业务场景
- [ ] 为每个场景填写验证模板 `scenarios/XX_name.md`
- [ ] 明确每个场景的输入/输出/成功标准

**3 个推荐的初始场景：**
1. 投资决策分析 `scenarios/01_investment_decision.md` ✅ 已创建
2. 风险评估报告 `scenarios/02_risk_assessment.md`
3. 战略规划建议 `scenarios/03_strategy_planning.md`

#### Day 2-3：手动验证
- [ ] 场景1：在 Claude 对话中测试 Prompt
- [ ] 场景1：记录输出，评估质量
- [ ] 场景1：调整 Prompt，重新测试
- [ ] 场景2：重复上述过程
- [ ] 场景3：重复上述过程

**验证标准：**
- 输出结构完整
- 分析有依据
- 建议可执行

#### Day 4：提炼 Prompt
- [ ] 整理每个场景的最佳 Prompt 版本
- [ ] 创建 `prompts/v1/` 目录，保存 Prompt 模板
- [ ] 识别共性模式（系统提示、输出格式等）

#### Day 5：确定 MVP 范围
- [ ] 基于验证结果，确定哪些功能是必需的
- [ ] 更新 MVP 功能列表
- [ ] 创建 Week 1 详细计划

### Week 0 交付物
```
scenarios/
├── SCENARIO_TEMPLATE.md    ✅
├── 01_investment_decision.md  ✅
├── 02_risk_assessment.md
└── 03_strategy_planning.md

prompts/v1/
├── system_prompt.txt
├── investment_analysis.txt
└── risk_assessment.txt
```

### 验收标准
- [ ] 至少 2 个场景验证通过
- [ ] 每个场景有可复用的 Prompt 模板
- [ ] MVP 范围明确定义

---

## Week 1：环境 + 骨架

### 目标
搭建项目骨架，实现 Claude API 封装。

### 每日任务

#### Day 1：项目初始化
- [ ] 创建 Python 项目结构
- [ ] 配置 pyproject.toml / requirements.txt
- [ ] 设置 .env 环境变量
- [ ] 配置 pytest

```bash
# 验证命令
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest --version
```

#### Day 2：Claude Client
- [ ] 实现 `src/ceo_agent/core/claude_client.py`
- [ ] 支持基础消息发送
- [ ] 支持流式响应
- [ ] 添加错误处理和重试
- [ ] 编写单元测试

```bash
# 验证命令
pytest tests/test_claude_client.py -v
```

#### Day 3：Prompt 管理
- [ ] 实现 `src/ceo_agent/prompts/templates.py`
- [ ] 实现 `src/ceo_agent/prompts/builder.py`
- [ ] 支持变量替换
- [ ] 编写测试

#### Day 4：评估框架
- [ ] 创建 `evaluation/test_cases/` 测试用例
- [ ] 实现 `evaluation/run_eval.py`
- [ ] 定义评估指标

#### Day 5：集成验证
- [ ] 端到端测试：Prompt → Claude → 输出
- [ ] 验证响应质量
- [ ] 记录基线指标

### Week 1 交付物
```
src/ceo_agent/
├── __init__.py
├── config.py
└── core/
    └── claude_client.py

tests/
└── test_claude_client.py

evaluation/
├── test_cases/
│   └── investment_cases.json
└── run_eval.py
```

### 验收标准
- [ ] `pytest` 全部通过
- [ ] Claude API 调用成功
- [ ] 评估脚本可运行

---

## Week 2：核心 Agent

### 目标
实现可工作的 AgentCore + API。

### 每日任务

#### Day 1-2：AgentCore
- [ ] 实现 `src/ceo_agent/core/agent.py`
- [ ] 集成 Prompt 模板
- [ ] 实现 `analyze()` 方法
- [ ] 添加响应解析

#### Day 3：简单记忆
- [ ] 实现 `src/ceo_agent/core/memory.py`
- [ ] 支持对话历史（内存）
- [ ] 支持决策日志（SQLite）

#### Day 4：API 路由
- [ ] 实现 `src/ceo_agent/api/routes.py`
- [ ] POST /api/v1/analyze
- [ ] 添加 Pydantic schemas

```bash
# 验证命令
uvicorn src.ceo_agent.main:app --reload
# 访问 http://localhost:8000/docs
```

#### Day 5：评估 + 调优
- [ ] 运行完整评估
- [ ] 分析结果，调整 Prompt
- [ ] 记录改进

### Week 2 交付物
```
src/ceo_agent/
├── main.py
├── core/
│   ├── agent.py
│   └── memory.py
└── api/
    ├── routes.py
    └── schemas.py
```

### 验收标准
- [ ] API 可访问
- [ ] 端到端分析流程工作
- [ ] 评估指标达到基线

---

## Week 3：验证 + 决策

### 目标
验证 MVP，决定下一步方向。

### 任务

#### Day 1-2：完整测试
- [ ] 用所有测试用例测试系统
- [ ] 收集响应质量数据
- [ ] 识别问题和改进点

#### Day 3：性能测试
- [ ] 响应时间测试
- [ ] 并发测试（如适用）
- [ ] 成本估算（Token 使用）

#### Day 4：决策会议
- [ ] 回顾 MVP 效果
- [ ] 决定是否添加 Tool Calling
- [ ] 决定是否添加 RAG
- [ ] 确定 Week 4+ 方向

#### Day 5：规划
- [ ] 创建 Week 4+ 计划
- [ ] 更新技术路线图

### 决策矩阵

| 功能 | 评估结果 | 是否添加 | 优先级 |
|------|---------|---------|--------|
| Tool Calling | | | |
| RAG 检索 | | | |
| Skill 系统 | | | |
| 复杂记忆 | | | |

---

## 每周回顾模板

### 本周回顾 - Week X

**完成情况：**
- 计划任务：X 项
- 完成任务：X 项
- 完成率：X%

**关键成果：**
1. ...
2. ...

**遇到的问题：**
1. 问题：...
   解决：...

**下周调整：**
1. ...

**风险和阻碍：**
1. ...

---

## 进度追踪

| Week | 目标 | 状态 | 关键交付物 |
|------|------|------|-----------|
| 0 | 场景验证 | ⏳ 进行中 | 验证通过的场景 |
| 1 | 环境骨架 | ⏸️ 待开始 | Claude Client |
| 2 | 核心 Agent | ⏸️ 待开始 | 可工作的 API |
| 3 | 验证决策 | ⏸️ 待开始 | 评估报告 |
| 4+ | 增量迭代 | ⏸️ 待开始 | 按需确定 |
