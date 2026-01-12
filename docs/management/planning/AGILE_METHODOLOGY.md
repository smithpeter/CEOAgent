# AI Agent 敏捷开发方法论

## 核心问题诊断

当前项目存在典型的 "AI Agent 开发陷阱"：

| 症状 | 当前项目表现 | 根因 |
|------|-------------|------|
| 架构先行 | 11层架构、4个数据库、12+ Skills | 过早优化，未验证需求 |
| 需求模糊 | "支持多源数据整合" 无具体定义 | 缺少真实用例驱动 |
| 范围蔓延 | 14周计划涵盖所有功能 | 没有 MVP 思维 |
| 无法推进 | 100% 文档，0% 代码 | 没有验证反馈循环 |

## 新方法论：VIPER 框架

```
V - Validate (验证场景)    → 先用对话验证 AI 能完成任务
I - Iterate (增量迭代)     → 每周交付可运行的增量
P - Prompt First (提示优先) → 代码之前，先验证 Prompt
E - Evaluate (持续评估)    → 建立评估数据集，量化效果
R - Refine (精炼优化)      → 基于数据，持续改进
```

---

## 第一阶段：场景验证 (Week 0) - 不写代码

### 目标
在写任何代码之前，用纯对话方式验证 Claude 能否完成核心任务。

### 步骤 1.1：定义具体场景

**不要这样写需求：**
```
❌ "支持多源数据整合，提供决策建议"
```

**而要这样写：**
```
✅ 场景：季度投资决策

   输入：
   - 公司财务数据（Q1-Q3 收入、利润、现金流）
   - 行业对标数据（3家竞品的相同指标）
   - 市场趋势报告（一段文本摘要）

   预期输出：
   - 风险评分（1-10）及理由
   - 3个投资方案对比表
   - 推荐方案及依据

   成功标准：
   - CEO 认为分析有价值（主观）
   - 推荐方案包含可执行的具体步骤
```

### 步骤 1.2：手动对话验证

在 Claude 对话界面中，直接测试：

```
你是一个 CEO 决策顾问。我现在需要做一个季度投资决策。

以下是输入数据：

## 财务数据
- Q1 收入：1200万，利润：180万
- Q2 收入：1350万，利润：210万
- Q3 收入：1100万，利润：95万（下滑）

## 竞品数据
- 竞品A：Q3收入增长12%
- 竞品B：Q3收入增长8%
- 竞品C：Q3收入下滑3%

## 市场趋势
行业整体增速放缓，但 AI 领域投资热度上升...

请给出：
1. 当前态势分析（150字以内）
2. 风险评分（1-10）及理由
3. 三个投资方案对比
4. 你的推荐及依据
```

### 步骤 1.3：记录验证结果

创建 `scenarios/investment_decision.md`：

```markdown
# 场景：季度投资决策

## 验证状态：✅ 通过 / ❌ 失败 / ⚠️ 需调整

## 测试记录

### 测试 1 - 2024-01-XX
- 输入：[粘贴输入]
- 输出：[粘贴 Claude 回复]
- 评估：
  - 分析质量：8/10
  - 方案可行性：7/10
  - 需要改进：风险评分需要更量化的依据

### 测试 2 - 调整 Prompt 后
- 修改：增加了"请用具体数据支撑风险评分"
- 输出：[粘贴回复]
- 评估：9/10，明显改善

## 最终 Prompt 模板
[经过多轮验证的最佳 Prompt]

## 技术需求推导
- 需要结构化财务数据输入 → DataFetchSkill
- 需要竞品对比能力 → CompetitorAnalysisSkill
- 需要风险量化 → RiskScoringSkill
```

---

## 第二阶段：核心 Prompt 工程 (Week 1)

### 目标
将验证通过的场景转化为可复用的 Prompt 模板。

### 2.1 Prompt 模板结构

```python
# prompts/decision_analysis.py

SYSTEM_PROMPT = """
你是一个专业的 CEO 决策顾问，具备以下能力：
- 财务分析：解读财务数据，识别趋势和异常
- 风险评估：量化评估决策风险
- 方案设计：提供可执行的具体方案

## 输出规范
- 分析简洁，控制在200字以内
- 风险评分必须基于具体数据点
- 每个方案必须包含：预期收益、风险、实施步骤
"""

DECISION_TEMPLATE = """
## 决策场景：{scenario_type}

## 输入数据
### 财务数据
{financial_data}

### 市场数据
{market_data}

### 其他上下文
{context}

## 请完成以下分析

### 1. 态势分析
[150字以内的现状总结]

### 2. 风险评估
- 风险评分：[1-10]
- 主要风险点：
  - 风险1：[描述] - 影响程度：[高/中/低]
  - 风险2：...

### 3. 方案对比
| 方案 | 预期收益 | 风险等级 | 实施周期 | 关键步骤 |
|------|---------|---------|---------|---------|
| A    |         |         |         |         |
| B    |         |         |         |         |
| C    |         |         |         |         |

### 4. 推荐方案
[你的推荐及理由]
"""
```

### 2.2 Prompt 版本管理

```
prompts/
├── v1/
│   ├── decision_analysis.py
│   └── risk_assessment.py
├── v2/  # 优化后的版本
│   └── ...
└── evaluation/
    ├── test_cases.json      # 测试用例
    └── results/             # 评估结果
```

---

## 第三阶段：极简 MVP (Week 2-3)

### 架构：单体 + 3个核心组件

```
┌─────────────────────────────────────┐
│            FastAPI App              │
├─────────────────────────────────────┤
│  POST /api/v1/analyze               │
│  POST /api/v1/chat                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         AgentCore                   │
│  - prompt_manager                   │
│  - claude_client                    │
│  - response_parser                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         SimpleMemory                │
│  - conversation_history (in-memory) │
│  - decision_log (SQLite)            │
└─────────────────────────────────────┘
```

### 核心代码结构

```
src/
├── ceo_agent/
│   ├── __init__.py
│   ├── main.py              # FastAPI 入口
│   ├── config.py            # 配置管理
│   │
│   ├── core/
│   │   ├── agent.py         # AgentCore 主类
│   │   ├── claude_client.py # Claude API 封装
│   │   └── memory.py        # 简单记忆系统
│   │
│   ├── prompts/
│   │   ├── templates.py     # Prompt 模板
│   │   └── builder.py       # Prompt 构建器
│   │
│   └── api/
│       ├── routes.py        # API 路由
│       └── schemas.py       # Pydantic 模型
│
├── tests/
│   ├── test_agent.py
│   └── test_prompts.py
│
└── evaluation/
    ├── test_cases/          # 评估用例
    └── run_eval.py          # 评估脚本
```

### 不要在 MVP 中包含

```
❌ Skill 系统（MVP 直接调用 Claude）
❌ Tool Calling（等验证后再加）
❌ 向量数据库（用简单关键词搜索）
❌ 多 Agent 协作
❌ 复杂记忆系统
❌ WebSocket 实时通信
❌ 前端界面（用 Swagger UI）
```

---

## 第四阶段：评估驱动开发 (持续)

### 4.1 建立评估数据集

```json
// evaluation/test_cases/investment_decisions.json
{
  "test_cases": [
    {
      "id": "inv_001",
      "scenario": "季度投资决策",
      "input": {
        "financial_data": "Q1: 1200万, Q2: 1350万, Q3: 1100万",
        "market_data": "行业增速放缓5%",
        "context": "现金储备充足"
      },
      "expected": {
        "risk_score_range": [6, 8],
        "must_include": ["现金流下滑", "行业放缓"],
        "recommendations_count": 3
      }
    },
    {
      "id": "inv_002",
      "scenario": "危机决策",
      "input": {...},
      "expected": {...}
    }
  ]
}
```

### 4.2 自动化评估脚本

```python
# evaluation/run_eval.py

async def evaluate_agent(test_cases: List[TestCase]) -> EvalReport:
    results = []

    for case in test_cases:
        # 调用 Agent
        response = await agent.analyze(case.input)

        # 评估结果
        score = evaluate_response(response, case.expected)

        results.append({
            "case_id": case.id,
            "score": score,
            "response": response,
            "issues": identify_issues(response, case.expected)
        })

    return generate_report(results)
```

### 4.3 评估指标

| 指标 | 计算方式 | 目标 |
|------|---------|------|
| 完整性 | 是否包含所有必需部分 | >95% |
| 准确性 | 风险评分是否在合理范围 | >80% |
| 可行性 | 方案是否具体可执行 | >70% |
| 一致性 | 相同输入是否产出相似结果 | >85% |

---

## 第五阶段：增量添加能力 (Week 4+)

### 能力添加顺序（按验证优先级）

```
Week 4: Tool Calling
  └─ 验证：Claude 能否正确调用 Tool
  └─ 实现：2-3 个基础 Tool（数据查询、计算）

Week 5: RAG 检索
  └─ 验证：检索是否提升回答质量
  └─ 实现：简单向量检索（可用 Chroma/FAISS）

Week 6: Skill 系统
  └─ 验证：Skill 组合是否比单 Prompt 更好
  └─ 实现：重构为 Skill 架构

Week 7: 记忆系统
  └─ 验证：记忆是否提升连续对话质量
  └─ 实现：Redis + PostgreSQL

Week 8+: 高级功能
  └─ Multi-Agent、知识图谱、前端...
```

### 每周验证检查点

```markdown
## Week X 检查点

### 本周目标
- [ ] 功能：XXX
- [ ] 评估指标提升：从 X% 到 Y%

### 验证问题
1. 这个功能是否真的需要？
2. 实现后评估指标是否提升？
3. 复杂度增加是否值得？

### 决策
- [ ] 继续开发
- [ ] 调整方向
- [ ] 回滚/简化
```

---

## 项目管理：可视化进度控制

### 使用 GitHub Projects 或简单 Markdown

```markdown
# CEOAgent 进度看板

## 📋 Backlog
- [ ] 多 Agent 协作
- [ ] 知识图谱集成
- [ ] 实时 WebSocket

## 🔄 本周 Sprint (Week 3)
- [x] 完成 claude_client.py
- [ ] 实现 AgentCore.analyze()
- [ ] 添加 3 个测试用例

## ✅ 已完成
- [x] 场景验证：投资决策 (Week 0)
- [x] Prompt 模板 v1 (Week 1)
- [x] FastAPI 骨架 (Week 2)

## 🚫 已放弃/推迟
- [x] ~~Neo4j 知识图谱~~ → 推迟到 Week 8+
- [x] ~~4层记忆系统~~ → 简化为 2层
```

---

## 具体执行计划

### Week 0（本周）：场景验证

| 天 | 任务 | 产出 |
|----|-----|------|
| Day 1 | 定义 3 个具体场景 | `scenarios/*.md` |
| Day 2-3 | 手动对话验证 | 验证记录 |
| Day 4 | 提炼 Prompt 模板 | `prompts/v1/` |
| Day 5 | 确定 MVP 范围 | 更新开发计划 |

### Week 1：环境 + 骨架

| 天 | 任务 | 产出 |
|----|-----|------|
| Day 1 | 项目初始化 | pyproject.toml, 目录结构 |
| Day 2 | Claude Client 封装 | claude_client.py + 测试 |
| Day 3 | Prompt 管理模块 | prompts/ 模块 |
| Day 4 | 评估框架 | evaluation/ 脚本 |
| Day 5 | 集成测试 | 端到端验证 |

### Week 2：核心 Agent

| 天 | 任务 | 产出 |
|----|-----|------|
| Day 1-2 | AgentCore 实现 | agent.py |
| Day 3 | 简单记忆 | memory.py |
| Day 4 | API 路由 | routes.py |
| Day 5 | 评估 + 调优 | 评估报告 |

### Week 3：验证 + 决策

| 天 | 任务 | 产出 |
|----|-----|------|
| Day 1-2 | 完整场景测试 | 测试报告 |
| Day 3 | 性能评估 | 性能数据 |
| Day 4 | 决策：继续/调整 | 决策文档 |
| Day 5 | 下阶段规划 | Week 4+ 计划 |

---

## 关键原则

### 1. 先验证，后实现
```
❌ 错误：设计 12 个 Skills → 全部实现 → 发现不需要
✅ 正确：设计 1 个场景 → 手动验证 → 确认需要 → 实现
```

### 2. 每周可运行
```
❌ 错误：第 8 周才能看到第一个可运行版本
✅ 正确：第 2 周就有 MVP，每周迭代
```

### 3. 数据驱动决策
```
❌ 错误："我觉得需要向量数据库"
✅ 正确："评估显示检索准确率只有 60%，需要向量数据库"
```

### 4. 复杂度预算
```
每个 Sprint 的复杂度预算：
- 新组件：最多 1 个
- 新依赖：最多 2 个
- 代码行数：最多 500 行新增
```

### 5. 可回滚设计
```
每个功能都要问：
- 如果这个功能失败了，能否快速回滚？
- 回滚成本是多少？
```
