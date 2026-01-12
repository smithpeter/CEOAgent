# CEOAgent 执行计划

> 详细的任务分解、依赖关系和验收标准

## 一、总体时间线

```
Week 0      Week 1-2      Week 3-5      Week 6-8      Week 9-11     Week 12
  │            │             │             │             │             │
  ▼            ▼             ▼             ▼             ▼             ▼
┌────┐     ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────┐
│ M0 │────▶│   M1   │───▶│   M2   │───▶│   M3   │───▶│   M4   │───▶│ M5 │
│场景 │     │ P0基础 │    │ P1标准 │    │ P2增强 │    │ P3完整 │    │生产 │
│验证 │     │  版本  │    │  版本  │    │  版本  │    │  版本  │    │就绪 │
└────┘     └────────┘    └────────┘    └────────┘    └────────┘    └────┘
```

---

## 二、M0 阶段：场景验证（Week 0）

### 目标
在写代码前，验证 Claude 能完成核心任务。

### 任务分解

```
M0.1 定义核心场景
├── M0.1.1 投资决策场景 ✅
├── M0.1.2 风险评估场景
└── M0.1.3 战略规划场景

M0.2 手动验证
├── M0.2.1 场景1验证（3轮迭代）
├── M0.2.2 场景2验证（3轮迭代）
└── M0.2.3 场景3验证（3轮迭代）

M0.3 Prompt 工程
├── M0.3.1 提炼系统 Prompt
├── M0.3.2 提炼任务 Prompt 模板
└── M0.3.3 定义输出格式规范

M0.4 评估准备
├── M0.4.1 创建评估用例（10+）
├── M0.4.2 定义评估指标
└── M0.4.3 建立评估基线
```

### 详细任务

#### M0.1 定义核心场景

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M0.1.1 | 定义投资决策场景 | `scenarios/01_investment_decision.md` | - | 2h |
| M0.1.2 | 定义风险评估场景 | `scenarios/02_risk_assessment.md` | - | 2h |
| M0.1.3 | 定义战略规划场景 | `scenarios/03_strategy_planning.md` | - | 2h |

**场景文档模板**：
```markdown
# 场景：[名称]

## 场景描述
[一句话描述]

## 输入定义
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|

## 预期输出
[结构化输出格式]

## 成功标准
- [ ] 标准1
- [ ] 标准2

## 验证记录
### 测试1 - 日期
输入：...
输出：...
评估：...
```

#### M0.2 手动验证

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M0.2.1 | 验证投资决策场景 | 验证记录 | M0.1.1 | 4h |
| M0.2.2 | 验证风险评估场景 | 验证记录 | M0.1.2 | 4h |
| M0.2.3 | 验证战略规划场景 | 验证记录 | M0.1.3 | 4h |

**验证流程**：
```
1. 复制测试 Prompt 到 Claude 对话界面
2. 发送并获取响应
3. 评估响应质量（完整性/准确性/可行性）
4. 记录问题和改进点
5. 调整 Prompt
6. 重复步骤1-5，直到满意
7. 记录最终 Prompt 版本
```

#### M0.3 Prompt 工程

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M0.3.1 | 提炼系统 Prompt | `prompts/v1/system.txt` | M0.2.* | 2h |
| M0.3.2 | 提炼任务模板 | `prompts/v1/templates/*.txt` | M0.2.* | 3h |
| M0.3.3 | 定义输出规范 | `prompts/v1/output_schema.json` | M0.3.2 | 2h |

**系统 Prompt 结构**：
```
你是 CEOAgent，一个专业的 CEO 决策顾问。

## 你的能力
- ...

## 你的限制
- ...

## 输出规范
- ...
```

#### M0.4 评估准备

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M0.4.1 | 创建评估用例 | `evaluation/test_cases/*.json` | M0.2.* | 3h |
| M0.4.2 | 定义评估指标 | `evaluation/metrics.md` | M0.4.1 | 1h |
| M0.4.3 | 建立基线 | `evaluation/baseline.md` | M0.4.2 | 2h |

**评估用例格式**：
```json
{
  "id": "case_001",
  "scenario": "investment_decision",
  "input": {
    "query": "...",
    "context": {...}
  },
  "expected": {
    "must_include": ["关键词1", "关键词2"],
    "risk_score_range": [5, 8],
    "recommendations_count": 3
  }
}
```

### M0 验收标准

| 验收项 | 标准 | 检验方法 |
|--------|------|---------|
| 场景定义 | 3个场景文档完成 | 文档审查 |
| 验证通过 | 至少2个场景验证通过 | 验证记录审查 |
| Prompt 模板 | 可复用的模板v1 | 测试验证 |
| 评估用例 | 10个以上测试用例 | 计数检查 |

---

## 三、M1 阶段：P0 基础版（Week 1-2）

### 目标
实现最小可行产品，验证核心 AI 能力。

### 任务分解

```
M1.1 项目初始化
├── M1.1.1 创建项目结构
├── M1.1.2 配置依赖管理
├── M1.1.3 配置开发工具
└── M1.1.4 创建 Docker 环境

M1.2 Claude Client
├── M1.2.1 实现基础消息发送
├── M1.2.2 实现流式响应
├── M1.2.3 实现错误重试
└── M1.2.4 编写单元测试

M1.3 Prompt 管理
├── M1.3.1 实现模板加载
├── M1.3.2 实现变量替换
├── M1.3.3 实现版本管理
└── M1.3.4 编写单元测试

M1.4 AgentCore
├── M1.4.1 实现 analyze() 方法
├── M1.4.2 实现响应解析
├── M1.4.3 集成 Memory
└── M1.4.4 编写集成测试

M1.5 API 层
├── M1.5.1 创建 FastAPI 应用
├── M1.5.2 实现 /analyze 端点
├── M1.5.3 实现 /chat 端点
└── M1.5.4 编写 API 测试

M1.6 评估验证
├── M1.6.1 实现评估脚本
├── M1.6.2 运行评估
└── M1.6.3 分析结果
```

### 详细任务

#### Week 1: 基础设施

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M1.1.1 | 创建项目结构 | 目录结构 | - | 2h |
| M1.1.2 | 配置 pyproject.toml | pyproject.toml | M1.1.1 | 1h |
| M1.1.3 | 配置 pre-commit | .pre-commit-config.yaml | M1.1.2 | 1h |
| M1.1.4 | 创建 Docker 环境 | docker-compose.yml | M1.1.1 | 2h |
| M1.2.1 | 实现消息发送 | claude_client.py | M1.1.2 | 3h |
| M1.2.2 | 实现流式响应 | claude_client.py | M1.2.1 | 2h |
| M1.2.3 | 实现错误重试 | claude_client.py | M1.2.1 | 2h |
| M1.2.4 | Claude 单元测试 | test_claude_client.py | M1.2.3 | 2h |
| M1.3.1 | 实现模板加载 | prompt_manager.py | M1.1.2 | 2h |
| M1.3.2 | 实现变量替换 | prompt_manager.py | M1.3.1 | 1h |
| M1.3.3 | 实现版本管理 | prompt_manager.py | M1.3.1 | 1h |
| M1.3.4 | Prompt 单元测试 | test_prompt_manager.py | M1.3.3 | 2h |

#### Week 2: AgentCore + API

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M1.4.1 | 实现 analyze() | agent.py | M1.2.4, M1.3.4 | 4h |
| M1.4.2 | 实现响应解析 | response_parser.py | M1.4.1 | 2h |
| M1.4.3 | 集成 SimpleMemory | memory.py | M1.4.1 | 2h |
| M1.4.4 | Agent 集成测试 | test_agent.py | M1.4.3 | 3h |
| M1.5.1 | 创建 FastAPI 应用 | main.py | M1.4.4 | 1h |
| M1.5.2 | 实现 /analyze | routes/decision.py | M1.5.1 | 2h |
| M1.5.3 | 实现 /chat | routes/chat.py | M1.5.1 | 2h |
| M1.5.4 | API 测试 | test_api.py | M1.5.3 | 2h |
| M1.6.1 | 实现评估脚本 | run_eval.py | M1.5.4 | 2h |
| M1.6.2 | 运行评估 | evaluation_report.md | M1.6.1 | 2h |
| M1.6.3 | 分析结果 | M1_review.md | M1.6.2 | 2h |

### 依赖关系图

```
M1.1.1 ─┬─▶ M1.1.2 ─▶ M1.1.3
        │      │
        │      └─▶ M1.2.1 ─▶ M1.2.2
        │             │
        │             └─▶ M1.2.3 ─▶ M1.2.4 ─┐
        │                                    │
        └─▶ M1.1.4                           │
                                             ▼
        M1.3.1 ─▶ M1.3.2 ─▶ M1.3.3 ─▶ M1.3.4 ─┬─▶ M1.4.1 ─▶ M1.4.2
                                              │      │
                                              │      └─▶ M1.4.3 ─▶ M1.4.4
                                              │                      │
                                              └──────────────────────┼─▶ M1.5.1
                                                                     │      │
                                                                     │      ▼
                                                                     │   M1.5.2 ─┐
                                                                     │      │     │
                                                                     │   M1.5.3 ─┤
                                                                     │           │
                                                                     └───────────┴─▶ M1.5.4 ─▶ M1.6.1 ─▶ M1.6.2 ─▶ M1.6.3
```

### M1 验收标准

| 验收项 | 标准 | 检验方法 |
|--------|------|---------|
| 代码质量 | pre-commit 检查通过 | CI 运行 |
| 单元测试 | 覆盖率 > 80% | pytest --cov |
| API 可用 | /analyze 返回正确结果 | curl 测试 |
| 评估指标 | 质量评分 > 60% | 评估脚本 |
| 文档 | API 文档可访问 | /docs 页面 |

---

## 四、M2 阶段：P1 标准版（Week 3-5）

### 目标
引入 Skill 架构，支持 Tool Calling。

### 任务分解

```
M2.1 Skill 系统
├── M2.1.1 实现 BaseSkill
├── M2.1.2 实现 SkillRegistry
├── M2.1.3 实现 SkillExecutor
└── M2.1.4 编写 Skill 系统测试

M2.2 核心 Skills
├── M2.2.1 DataFetchSkill
├── M2.2.2 DataAnalysisSkill
├── M2.2.3 RiskAssessmentSkill
└── M2.2.4 DecisionGeneratorSkill

M2.3 Tool Calling 集成
├── M2.3.1 实现 Tool Schema 生成
├── M2.3.2 实现 Tool Calling 处理
├── M2.3.3 实现多轮 Tool 调用
└── M2.3.4 Tool Calling 测试

M2.4 Memory 升级
├── M2.4.1 Redis 集成
├── M2.4.2 PostgreSQL 集成
├── M2.4.3 ShortTermMemory 实现
├── M2.4.4 LongTermMemory 实现
└── M2.4.5 Memory 测试

M2.5 认证授权
├── M2.5.1 JWT 认证实现
├── M2.5.2 用户管理 API
└── M2.5.3 认证测试

M2.6 WebSocket
├── M2.6.1 WebSocket 端点
├── M2.6.2 流式响应实现
└── M2.6.3 WebSocket 测试
```

### 详细任务（Week 3-5）

#### Week 3: Skill 系统

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M2.1.1 | 实现 BaseSkill | skills/base.py | M1 完成 | 3h |
| M2.1.2 | 实现 SkillRegistry | skills/registry.py | M2.1.1 | 3h |
| M2.1.3 | 实现 SkillExecutor | skills/executor.py | M2.1.2 | 3h |
| M2.1.4 | Skill 系统测试 | tests/test_skills.py | M2.1.3 | 2h |
| M2.2.1 | DataFetchSkill | skills/data/fetch.py | M2.1.4 | 3h |
| M2.2.2 | DataAnalysisSkill | skills/data/analyze.py | M2.1.4 | 4h |
| M2.2.3 | RiskAssessmentSkill | skills/decision/risk.py | M2.1.4 | 4h |
| M2.2.4 | DecisionGeneratorSkill | skills/decision/recommend.py | M2.1.4 | 4h |

#### Week 4: Tool Calling + Memory

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M2.3.1 | Tool Schema 生成 | skills/base.py | M2.2.* | 2h |
| M2.3.2 | Tool Calling 处理 | agents/tool_agent.py | M2.3.1 | 4h |
| M2.3.3 | 多轮 Tool 调用 | agents/tool_agent.py | M2.3.2 | 3h |
| M2.3.4 | Tool Calling 测试 | tests/test_tool_calling.py | M2.3.3 | 3h |
| M2.4.1 | Redis 集成 | config.py, docker | M1 完成 | 2h |
| M2.4.2 | PostgreSQL 集成 | config.py, docker | M1 完成 | 2h |
| M2.4.3 | ShortTermMemory | memory/short_term.py | M2.4.1 | 3h |
| M2.4.4 | LongTermMemory | memory/long_term.py | M2.4.2 | 4h |
| M2.4.5 | Memory 测试 | tests/test_memory.py | M2.4.4 | 2h |

#### Week 5: 认证 + WebSocket + 集成

| 任务ID | 任务 | 产出 | 依赖 | 时间 |
|--------|------|------|------|------|
| M2.5.1 | JWT 认证 | api/auth.py | M2.4.2 | 4h |
| M2.5.2 | 用户管理 API | api/routes/user.py | M2.5.1 | 3h |
| M2.5.3 | 认证测试 | tests/test_auth.py | M2.5.2 | 2h |
| M2.6.1 | WebSocket 端点 | api/websocket.py | M2.3.4 | 3h |
| M2.6.2 | 流式响应 | api/websocket.py | M2.6.1 | 2h |
| M2.6.3 | WebSocket 测试 | tests/test_ws.py | M2.6.2 | 2h |
| M2.7.1 | 集成测试 | tests/integration/ | M2.6.3 | 4h |
| M2.7.2 | 评估运行 | evaluation/ | M2.7.1 | 2h |
| M2.7.3 | M2 回顾 | M2_review.md | M2.7.2 | 2h |

### M2 验收标准

| 验收项 | 标准 | 检验方法 |
|--------|------|---------|
| Skill 系统 | 4个 Skills 可用 | 单元测试 |
| Tool Calling | 多轮调用成功 | 集成测试 |
| Memory | STM + LTM 工作 | 集成测试 |
| 认证 | JWT 登录成功 | API 测试 |
| WebSocket | 流式响应工作 | 手动测试 |
| 评估指标 | 质量评分 > 75% | 评估脚本 |

---

## 五、M3 阶段：P2 增强版（Week 6-8）

### 任务分解

```
M3.1 ReAct Agent
├── M3.1.1 ReAct 循环实现
├── M3.1.2 推理阶段实现
├── M3.1.3 观察阶段实现
└── M3.1.4 ReAct 测试

M3.2 Agent 路由
├── M3.2.1 任务分类器
├── M3.2.2 模式选择逻辑
└── M3.2.3 路由测试

M3.3 RAG 系统
├── M3.3.1 Weaviate 集成
├── M3.3.2 向量化实现
├── M3.3.3 检索器实现
├── M3.3.4 RAG Pipeline
└── M3.3.5 RAG 测试

M3.4 知识库
├── M3.4.1 文档上传 API
├── M3.4.2 文档处理器
├── M3.4.3 知识检索 Skill
└── M3.4.4 知识库测试
```

---

## 六、M4 阶段：P3 完整版（Week 9-11）

### 任务分解

```
M4.1 Multi-Agent
├── M4.1.1 Agent Orchestrator
├── M4.1.2 DataAnalyst Agent
├── M4.1.3 RiskExpert Agent
├── M4.1.4 StrategyAdvisor Agent
└── M4.1.5 Multi-Agent 测试

M4.2 知识图谱
├── M4.2.1 Neo4j 集成
├── M4.2.2 实体提取
├── M4.2.3 关系建立
├── M4.2.4 图查询实现
└── M4.2.5 知识图谱测试

M4.3 完整 Memory
├── M4.3.1 WorkingMemory 实现
├── M4.3.2 SemanticMemory 实现
├── M4.3.3 Memory 协调器
└── M4.3.4 Memory 集成测试

M4.4 Plan-Execute Agent
├── M4.4.1 任务分解器
├── M4.4.2 执行器
├── M4.4.3 结果合成器
└── M4.4.4 Plan-Execute 测试
```

---

## 七、M5 阶段：生产就绪（Week 12）

### 任务分解

```
M5.1 性能优化
├── M5.1.1 性能测试
├── M5.1.2 瓶颈识别
├── M5.1.3 优化实施
└── M5.1.4 优化验证

M5.2 安全加固
├── M5.2.1 安全审计
├── M5.2.2 漏洞修复
├── M5.2.3 安全测试
└── M5.2.4 安全文档

M5.3 部署准备
├── M5.3.1 生产 Docker 配置
├── M5.3.2 K8s 配置（可选）
├── M5.3.3 监控配置
├── M5.3.4 日志配置
└── M5.3.5 部署文档

M5.4 文档完善
├── M5.4.1 API 文档
├── M5.4.2 部署文档
├── M5.4.3 运维文档
└── M5.4.4 用户手册
```

---

## 八、风险缓解计划

### 技术风险应对

| 风险 | 触发条件 | 应对措施 |
|------|---------|---------|
| Claude API 超时 | 响应 > 30s | 流式响应 + 超时处理 |
| Tool Calling 失败 | 成功率 < 80% | 回退到 DirectMode |
| 向量检索差 | 准确率 < 60% | 切换向量模型/调优 |
| 任务超时 | 复杂任务 > 2min | 任务拆分 + 异步处理 |

### 进度风险应对

| 风险 | 触发条件 | 应对措施 |
|------|---------|---------|
| 任务延期 | 进度落后 > 2天 | 加班/砍功能/求助 |
| 需求变更 | 新需求提出 | 评估影响/推迟到下阶段 |
| 技术障碍 | 卡住 > 1天 | 寻求帮助/备选方案 |

---

## 九、每日站会模板

```markdown
## 站会 - YYYY-MM-DD

### 昨日完成
- [x] 任务1
- [x] 任务2

### 今日计划
- [ ] 任务3
- [ ] 任务4

### 阻碍问题
- 问题1：...
  - 解决方案：...

### 风险预警
- 风险1：...
```

---

## 十、阶段回顾模板

```markdown
## M[X] 阶段回顾 - YYYY-MM-DD

### 完成情况

| 任务 | 状态 | 备注 |
|------|------|------|
| 任务1 | ✅ 完成 | |
| 任务2 | ⚠️ 部分 | 缺少... |
| 任务3 | ❌ 未完成 | 原因... |

### 关键成果
1. ...
2. ...

### 问题和教训
1. 问题：...
   教训：...

### 评估结果

| 指标 | 目标 | 实际 | 差距 |
|------|------|------|------|
| 质量评分 | 75% | 72% | -3% |
| 测试覆盖 | 80% | 85% | +5% |

### 下阶段调整
1. ...
2. ...
```
