# CEOAgent 主开发计划

> **本文档是唯一权威的开发计划**，取代以下文档中的冲突内容：
> - DEVELOPMENT_PLAN.md（原详细计划 → 降级为参考）
> - EXECUTION_PLAN.md（原执行计划 → 降级为参考）
> - TECHNICAL_BLUEPRINT.md（原技术蓝图 → 降级为参考）
> - AGILE_AGENT_METHODOLOGY.md（方法论 → 保留为指导原则）

---

## 一、项目定位

**CEOAgent** 是一个 AI 驱动的 CEO 决策支持系统，帮助 CEO 进行投资决策、风险评估和战略规划。

**核心价值**：将 Claude 的分析能力与结构化的决策框架结合，提供可执行的决策建议。

---

## 二、MVP 定义（最小可行产品）

### MVP 包含 ✅

| 功能 | 描述 | 技术实现 |
|------|------|---------|
| 决策分析 | 用户输入问题，获得分析和建议 | Claude API 直接调用 |
| 结构化输出 | 风险评分、方案对比、推荐理由 | Prompt 模板 + 输出解析 |
| 对话历史 | 保存当前会话的对话 | 内存存储 |
| REST API | 标准 HTTP 接口 | FastAPI |

### MVP 不包含 ❌

| 功能 | 推迟到 |
|------|--------|
| Skill 系统 | Phase 2 |
| Tool Calling | Phase 2 |
| 向量数据库/RAG | Phase 3 |
| Redis 缓存 | Phase 2 |
| PostgreSQL | Phase 2 |
| WebSocket | Phase 2 |
| 用户认证 | Phase 2 |
| Multi-Agent | Phase 4 |
| 知识图谱 | Phase 4 |

---

## 三、开发阶段

### 阶段概览

```
Phase 0: 验证 (3天)     Phase 1: MVP (5天)      Phase 2: 增强 (10天)
    │                       │                       │
    ▼                       ▼                       ▼
┌────────┐              ┌────────┐              ┌────────┐
│ 场景验证 │─────────────▶│ 基础版 │─────────────▶│ 标准版 │
│ Prompt │              │ API可用 │              │ Skill  │
└────────┘              └────────┘              └────────┘
```

### Phase 0: 场景验证（3天）

**目标**：验证 Claude 能完成核心任务

**产出**：
- [ ] 3 个场景的 Prompt 模板
- [ ] 10+ 个评估用例
- [ ] 验证报告

**任务**：
| Day | 任务 | 产出 |
|-----|------|------|
| 1 | 定义 3 个场景 | `scenarios/*.md` |
| 2 | 手动验证 + 迭代 Prompt | 验证记录 |
| 3 | 提炼模板 + 评估用例 | `prompts/v1/`, `evaluation/` |

**完成标准**：
- 至少 2 个场景在 Claude 对话中验证通过
- Prompt 输出包含所有必需部分（态势分析、风险评分、方案对比、推荐）

### Phase 1: MVP（5天）

**目标**：可运行的 API，能接受问题并返回分析结果

**架构**：
```
FastAPI
   │
   ▼
┌─────────────────────────┐
│       AgentCore         │
│  ┌───────────────────┐  │
│  │  PromptManager    │  │
│  │  ClaudeClient     │  │
│  │  ResponseParser   │  │
│  │  MemoryStore      │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

**技术选型**：
| 组件 | 选型 | 理由 |
|------|------|------|
| Web 框架 | FastAPI | 异步、自动文档 |
| LLM | Claude 3.5 Sonnet | 性能/成本平衡 |
| 数据验证 | Pydantic v2 | 类型安全 |
| 存储 | 内存 + JSON 文件 | 零配置 |
| 测试 | pytest | 标准 |

**任务**：
| Day | 任务 | 产出 |
|-----|------|------|
| 1 | 项目结构 + 配置 | `src/`, `pyproject.toml` |
| 2 | ClaudeClient + PromptManager | `core/*.py` |
| 3 | AgentCore + ResponseParser | `core/agent.py` |
| 4 | API 路由 | `api/routes.py` |
| 5 | 测试 + 评估 | `tests/`, 评估报告 |

**完成标准**：
| 检查项 | 标准 |
|--------|------|
| API 可访问 | `curl localhost:8000/api/v1/analyze` 返回结果 |
| 单元测试 | `pytest` 全部通过 |
| 响应质量 | 评估脚本得分 > 60% |
| 文档 | `/docs` 可访问 |

### Phase 2: 增强版（10天）

**目标**：Skill 系统 + Tool Calling + 持久化

**新增组件**：
- Skill 系统（BaseSkill, Registry, Executor）
- 4 个核心 Skills
- Tool Calling 集成
- PostgreSQL + Redis
- JWT 认证

**任务**：
| Week | 任务 |
|------|------|
| Week 1 | Skill 系统 + 4 个 Skills |
| Week 2 | Tool Calling + Memory + Auth |

### Phase 3: RAG 增强（10天）

**目标**：向量检索 + ReAct 模式

**新增组件**：
- Weaviate 向量库
- RAG Pipeline
- ReAct Agent

### Phase 4: 完整版（10天）

**目标**：Multi-Agent + 知识图谱

**新增组件**：
- Agent Orchestrator
- Neo4j 知识图谱
- 完整 Memory 系统

---

## 四、项目结构

### Phase 1 结构（MVP）

```
ceoagent/
├── src/
│   └── ceo_agent/
│       ├── __init__.py
│       ├── main.py              # FastAPI 入口
│       ├── config.py            # 配置
│       ├── core/
│       │   ├── __init__.py
│       │   ├── agent.py         # AgentCore
│       │   ├── claude_client.py # Claude API
│       │   ├── prompt_manager.py# Prompt 管理
│       │   ├── response_parser.py# 响应解析
│       │   └── memory.py        # 内存存储
│       └── api/
│           ├── __init__.py
│           ├── routes.py        # API 路由
│           └── schemas.py       # Pydantic 模型
├── prompts/
│   └── v1/
│       ├── system.txt           # 系统 Prompt
│       └── decision_analysis.txt# 决策分析模板
├── tests/
│   ├── __init__.py
│   ├── test_claude_client.py
│   ├── test_agent.py
│   └── test_api.py
├── evaluation/
│   ├── test_cases/
│   │   └── investment_cases.json
│   └── run_eval.py
├── scenarios/                   # 场景验证
├── pyproject.toml
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## 五、技术规范

### 代码规范

```python
# Python 3.11+
# 类型提示必须
# Google-style docstrings
# async/await 用于所有 I/O

from typing import Any
from pydantic import BaseModel

class AnalysisRequest(BaseModel):
    """决策分析请求"""
    query: str
    context: dict[str, Any] | None = None

async def analyze(request: AnalysisRequest) -> AnalysisResponse:
    """执行决策分析

    Args:
        request: 分析请求

    Returns:
        分析结果
    """
    pass
```

### API 规范

```
Base URL: /api/v1

POST /api/v1/analyze     # 决策分析
POST /api/v1/chat        # 对话（可选）
GET  /api/v1/health      # 健康检查
```

### 响应格式

```json
{
  "success": true,
  "data": {
    "analysis_id": "uuid",
    "query": "...",
    "result": {
      "situation_analysis": "...",
      "risk_score": 7,
      "risk_factors": [...],
      "recommendations": [...],
      "final_recommendation": {...}
    }
  },
  "metadata": {
    "model": "claude-3-5-sonnet-20241022",
    "tokens_used": 1234,
    "execution_time_ms": 2500
  }
}
```

---

## 六、验收标准

### Phase 0 验收

| 项目 | 标准 | 验证方法 |
|------|------|---------|
| 场景定义 | 3 个场景文档完成 | 文件存在 |
| 验证通过 | 至少 2 个场景通过 | 验证记录 |
| Prompt 模板 | 可复用模板存在 | 文件存在 |
| 评估用例 | 10+ 用例 | 计数 |

### Phase 1 验收

| 项目 | 标准 | 验证方法 |
|------|------|---------|
| 服务启动 | `uvicorn` 无错误启动 | 命令行 |
| API 可用 | `/analyze` 返回正确格式 | curl 测试 |
| 测试通过 | 所有测试通过 | `pytest` |
| 响应质量 | 评估得分 > 60% | `run_eval.py` |
| 文档 | `/docs` 可访问 | 浏览器 |

### 评估得分计算

```python
def calculate_score(response, expected):
    score = 0
    total = 100

    # 完整性 (40分)
    if response.situation_analysis:
        score += 10
    if response.risk_score is not None:
        score += 10
    if len(response.recommendations) >= 2:
        score += 10
    if response.final_recommendation:
        score += 10

    # 准确性 (30分)
    if expected.risk_score_range[0] <= response.risk_score <= expected.risk_score_range[1]:
        score += 15
    if all(kw in response.text for kw in expected.must_include):
        score += 15

    # 可行性 (30分)
    for rec in response.recommendations:
        if rec.action_steps and len(rec.action_steps) >= 2:
            score += 10
            break
    if response.final_recommendation.reasoning:
        score += 20

    return score / total * 100
```

---

## 七、风险管理

### 技术风险

| 风险 | 可能性 | 影响 | 缓解 |
|------|--------|------|------|
| Claude API 超时 | 中 | 高 | 设置 60s 超时 + 重试 |
| 响应格式不稳定 | 高 | 中 | Prompt 明确格式 + 解析容错 |
| Token 超限 | 低 | 中 | 限制输入长度 |

### 进度风险

| 风险 | 触发条件 | 应对 |
|------|---------|------|
| 延期 | 进度落后 2 天 | 砍功能/加班 |
| 阻塞 | 卡住 1 天 | 寻求帮助/备选方案 |

---

## 八、立即行动

### 今天

1. 创建项目骨架
2. 配置开发环境
3. 开始 Phase 0 场景验证

### 本周

```
Day 1-3: Phase 0 场景验证
Day 4-8: Phase 1 MVP 开发
```

---

## 九、文档导航

| 文档 | 用途 | 状态 |
|------|------|------|
| **MASTER_PLAN.md** | 唯一权威计划 | ✅ 当前 |
| CLAUDE.md | Claude Code 指导 | ✅ 更新 |
| scenarios/*.md | 场景验证 | 🔄 进行中 |
| ARCHITECTURE.md | 架构参考 | 📖 参考 |
| SKILL_ARCHITECTURE.md | Skill 设计参考 | 📖 参考（Phase 2） |
| DEVELOPMENT_PLAN.md | 原计划 | ⚠️ 已废弃 |
| EXECUTION_PLAN.md | 原执行计划 | ⚠️ 已废弃 |
| TECHNICAL_BLUEPRINT.md | 原技术蓝图 | ⚠️ 已废弃 |
