# CEOAgent 技术蓝图

> 从开发经理视角出发，整合现有架构设计，形成可执行的分阶段技术方案。

## 一、架构总览

### 1.1 目标架构（终态）

```
┌─────────────────────────────────────────────────────────────────┐
│                        客户端层                                  │
│  Web (React) │ Mobile (可选) │ CLI (可选)                       │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                        网关层                                    │
│  FastAPI │ WebSocket │ JWT Auth │ Rate Limit                    │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                     Agent 编排层                                 │
│  Orchestrator │ ReAct Agent │ Plan-Execute │ Multi-Agent        │
└─────────────────────────────┬───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                       核心层                                     │
│  Skill Registry │ Skill Executor │ Skill Composer │ Middleware  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Skill 层      │  │   Memory 层     │  │   LLM 层        │
│ Data/Decision/  │  │ STM/WM/LTM/SM   │  │ Claude Client   │
│ Knowledge/Integ │  │ Redis/PG/Vector │  │ Cache/Fallback  │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        数据层                                    │
│  PostgreSQL │ Weaviate │ Redis │ Neo4j (可选)                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 架构演进路线

| 阶段 | 架构复杂度 | 核心组件 | 数据库 |
|------|-----------|---------|--------|
| P0 基础版 | 极简 | AgentCore + Claude | SQLite |
| P1 标准版 | 中等 | Skill + Registry + Executor | PostgreSQL + Redis |
| P2 增强版 | 较高 | ReAct + Tool Calling + RAG | + Weaviate |
| P3 完整版 | 完整 | Multi-Agent + 知识图谱 | + Neo4j |

---

## 二、分阶段架构设计

### 2.1 P0 阶段：基础版（Week 1-2）

**目标**：验证核心 AI 能力，最小可行产品

```
┌─────────────────────────────────────┐
│            FastAPI                  │
│  POST /api/v1/analyze               │
│  POST /api/v1/chat                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          AgentCore                  │
│  ┌─────────────────────────────┐   │
│  │ PromptManager               │   │
│  │ - 模板加载                   │   │
│  │ - 变量替换                   │   │
│  │ - 版本管理                   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ ClaudeClient                │   │
│  │ - 消息发送                   │   │
│  │ - 流式响应                   │   │
│  │ - 错误重试                   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ ResponseParser              │   │
│  │ - 结构化输出解析             │   │
│  │ - 格式验证                   │   │
│  └─────────────────────────────┘   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         SimpleMemory                │
│  - conversation_history (内存)      │
│  - decision_log (SQLite)            │
└─────────────────────────────────────┘
```

**核心模块：**

```python
# P0 阶段的核心类结构

class AgentCore:
    """P0 核心 Agent"""
    prompt_manager: PromptManager
    claude_client: ClaudeClient
    response_parser: ResponseParser
    memory: SimpleMemory

    async def analyze(self, query: str, context: dict) -> AnalysisResult:
        """执行决策分析"""
        # 1. 加载对话历史
        history = self.memory.get_history(context.get("conversation_id"))

        # 2. 构建 Prompt
        prompt = self.prompt_manager.build(
            template="decision_analysis",
            query=query,
            context=context,
            history=history
        )

        # 3. 调用 Claude
        response = await self.claude_client.send(prompt)

        # 4. 解析响应
        result = self.response_parser.parse(response)

        # 5. 保存到记忆
        self.memory.save_decision(result)

        return result
```

**技术选型：**

| 组件 | 选型 | 理由 |
|------|------|------|
| Web框架 | FastAPI | 异步、自动文档、类型提示 |
| LLM | Claude 3.5 Sonnet | 性能/成本平衡 |
| 数据验证 | Pydantic v2 | 性能优化、原生支持 |
| 存储 | SQLite | 零配置、开发便捷 |
| 测试 | pytest + pytest-asyncio | Python 异步测试标准 |

**P0 不包含：**
- ❌ Skill 系统
- ❌ Tool Calling
- ❌ 向量数据库
- ❌ Redis 缓存
- ❌ WebSocket
- ❌ 用户认证

---

### 2.2 P1 阶段：标准版（Week 3-5）

**目标**：引入 Skill 架构，支持 Tool Calling

```
┌─────────────────────────────────────┐
│            FastAPI                  │
│  + WebSocket /ws/chat               │
│  + JWT 认证                          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          AgentCore                  │
│  + SkillRouter (选择执行策略)        │
└──────────────┬──────────────────────┘
               │
     ┌─────────┴─────────┐
     ▼                   ▼
┌─────────────┐   ┌─────────────────────┐
│ DirectMode  │   │ SkillMode           │
│ (简单问答)   │   │ (复杂任务)           │
└─────────────┘   └──────────┬──────────┘
                             │
               ┌─────────────┴─────────────┐
               ▼                           ▼
┌──────────────────────┐    ┌──────────────────────┐
│    Skill Registry    │    │    Skill Executor    │
│  - 注册 Skills        │    │  - 执行 Skills       │
│  - 查找 Skills        │    │  - 参数验证          │
│  - 生成 Tool Schema   │    │  - 错误处理          │
└──────────────────────┘    └──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Skills                    │
│  ┌──────────┐ ┌──────────┐         │
│  │DataFetch │ │DataAnalyze│         │
│  └──────────┘ └──────────┘         │
│  ┌──────────┐ ┌──────────┐         │
│  │RiskAssess│ │DecisionGen│         │
│  └──────────┘ └──────────┘         │
└─────────────────────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Memory System              │
│  ShortTerm (Redis) + LongTerm (PG)  │
└─────────────────────────────────────┘
```

**Skill 架构设计：**

```python
# BaseSkill 定义
from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Any, Dict

class SkillResult(BaseModel):
    """Skill 执行结果"""
    success: bool
    data: Any = None
    error: str | None = None
    metadata: Dict[str, Any] = {}

class BaseSkill(ABC):
    """Skill 基类"""

    # 元信息
    name: str           # 唯一标识
    description: str    # 描述（用于 Tool Calling）
    version: str = "1.0.0"
    category: str       # data | decision | knowledge | integration

    # 参数定义（Pydantic 模型）
    params_class: type[BaseModel]

    @abstractmethod
    async def execute(self, params: BaseModel) -> SkillResult:
        """执行 Skill"""
        pass

    def get_tool_schema(self) -> Dict[str, Any]:
        """生成 Claude Tool Calling schema"""
        return {
            "name": self.name,
            "description": self.description,
            "input_schema": self.params_class.model_json_schema()
        }

    def validate_params(self, params: Dict) -> BaseModel:
        """验证并转换参数"""
        return self.params_class(**params)
```

**P1 核心 Skills（4个）：**

| Skill | 功能 | 优先级 |
|-------|------|--------|
| DataFetchSkill | 模拟数据获取（JSON/CSV） | P0 |
| DataAnalysisSkill | 基础数据分析（pandas） | P0 |
| RiskAssessmentSkill | 风险评分计算 | P1 |
| DecisionGeneratorSkill | 决策建议生成 | P1 |

**Tool Calling 集成：**

```python
class ToolCallingAgent:
    """Tool Calling Agent"""

    def __init__(self, registry: SkillRegistry, executor: SkillExecutor):
        self.registry = registry
        self.executor = executor
        self.client = Anthropic()

    async def process(self, query: str) -> str:
        # 1. 获取所有 Tool schemas
        tools = self.registry.get_all_tool_schemas()

        # 2. 调用 Claude with Tools
        response = await self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=4096,
            messages=[{"role": "user", "content": query}],
            tools=tools
        )

        # 3. 处理 Tool Calls
        while response.stop_reason == "tool_use":
            tool_results = []

            for content in response.content:
                if content.type == "tool_use":
                    # 执行对应的 Skill
                    result = await self.executor.execute(
                        skill_name=content.name,
                        params=content.input
                    )
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": content.id,
                        "content": result.model_dump_json()
                    })

            # 4. 继续对话
            response = await self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4096,
                messages=[
                    {"role": "user", "content": query},
                    {"role": "assistant", "content": response.content},
                    {"role": "user", "content": tool_results}
                ],
                tools=tools
            )

        return response.content[0].text
```

**技术选型更新：**

| 组件 | 选型 | 新增/变更 |
|------|------|----------|
| 缓存 | Redis 7+ | 新增 |
| 关系库 | PostgreSQL 15+ | 替换 SQLite |
| 认证 | JWT + python-jose | 新增 |
| WebSocket | FastAPI WebSocket | 新增 |

---

### 2.3 P2 阶段：增强版（Week 6-8）

**目标**：引入 ReAct 模式和 RAG 检索

```
┌─────────────────────────────────────────────────────────────────┐
│                         Agent Router                            │
│   根据任务类型选择：DirectMode | ToolMode | ReActMode            │
└──────────────────────────────┬──────────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
   ┌────────────┐      ┌────────────┐      ┌────────────┐
   │ DirectMode │      │ ToolMode   │      │ ReActMode  │
   │ 简单问答    │      │ 单次Tool   │      │ 多步推理   │
   └────────────┘      └────────────┘      └─────┬──────┘
                                                 │
                               ┌─────────────────┴─────────────────┐
                               ▼                                   ▼
                        ┌─────────────┐                     ┌─────────────┐
                        │  Reasoning  │────────────────────▶│   Acting    │
                        │  推理阶段   │                     │  行动阶段   │
                        └─────────────┘                     └──────┬──────┘
                               ▲                                   │
                               │                                   ▼
                        ┌──────┴──────┐                     ┌─────────────┐
                        │ Observation │◀────────────────────│ Skill 执行  │
                        │  观察结果   │                     └─────────────┘
                        └─────────────┘
```

**ReAct Agent 实现：**

```python
class ReActAgent:
    """ReAct Agent：推理-行动-观察循环"""

    def __init__(
        self,
        claude_client: ClaudeClient,
        skill_executor: SkillExecutor,
        memory: MemorySystem,
        max_iterations: int = 10
    ):
        self.client = claude_client
        self.executor = skill_executor
        self.memory = memory
        self.max_iterations = max_iterations

    async def process(self, query: str, context: Dict) -> AgentResult:
        """ReAct 主循环"""
        observations = []
        thoughts = []

        for i in range(self.max_iterations):
            # 1. Reasoning: 分析当前状态，决定下一步
            thought = await self._reason(query, observations, context)
            thoughts.append(thought)

            # 2. 判断是否完成
            if thought.action_type == "final_answer":
                return AgentResult(
                    answer=thought.answer,
                    thoughts=thoughts,
                    observations=observations
                )

            # 3. Acting: 执行选定的 Skill
            if thought.action_type == "skill":
                result = await self.executor.execute(
                    skill_name=thought.skill_name,
                    params=thought.skill_params
                )

                # 4. Observation: 记录结果
                observations.append({
                    "step": i,
                    "skill": thought.skill_name,
                    "result": result
                })

                # 保存到工作记忆
                await self.memory.working.record(thought, result)

        # 超过最大迭代，合成答案
        return await self._synthesize_answer(query, thoughts, observations)

    async def _reason(
        self,
        query: str,
        observations: List,
        context: Dict
    ) -> Thought:
        """推理阶段"""
        prompt = f"""
        你是一个决策分析专家。请分析当前任务并决定下一步行动。

        ## 原始问题
        {query}

        ## 上下文
        {json.dumps(context, ensure_ascii=False)}

        ## 已执行的步骤和观察结果
        {json.dumps(observations, ensure_ascii=False)}

        ## 可用的 Skills
        {self.executor.get_available_skills_description()}

        ## 请输出
        1. 思考：分析当前状态
        2. 行动：选择下一步
           - 如果需要执行 Skill，输出 skill_name 和参数
           - 如果已完成分析，输出最终答案
        """

        response = await self.client.send(prompt)
        return self._parse_thought(response)
```

**RAG 系统集成：**

```python
class RAGPipeline:
    """检索增强生成"""

    def __init__(
        self,
        weaviate_client: WeaviateClient,
        embedding_client: EmbeddingClient,
        claude_client: ClaudeClient
    ):
        self.vector_db = weaviate_client
        self.embedder = embedding_client
        self.llm = claude_client

    async def query(
        self,
        question: str,
        collection: str = "decisions",
        top_k: int = 5
    ) -> RAGResult:
        """RAG 查询流程"""

        # 1. Query 向量化
        query_embedding = await self.embedder.embed(question)

        # 2. 向量检索
        similar_docs = await self.vector_db.search(
            collection=collection,
            vector=query_embedding,
            limit=top_k
        )

        # 3. 构建增强 Prompt
        context = self._format_context(similar_docs)
        prompt = f"""
        基于以下参考信息回答问题。

        ## 参考信息
        {context}

        ## 问题
        {question}

        ## 要求
        - 基于参考信息回答
        - 如果参考信息不足，明确说明
        - 引用相关的参考来源
        """

        # 4. 生成回答
        answer = await self.llm.send(prompt)

        return RAGResult(
            answer=answer,
            sources=similar_docs,
            query_embedding=query_embedding
        )
```

**技术选型更新：**

| 组件 | 选型 | 说明 |
|------|------|------|
| 向量库 | Weaviate | 开源、支持混合搜索 |
| Embedding | Voyage AI / OpenAI | 高质量向量 |
| 文档处理 | LangChain 文档加载器 | 多格式支持 |

---

### 2.4 P3 阶段：完整版（Week 9-12）

**目标**：Multi-Agent、知识图谱、完整记忆系统

```
┌─────────────────────────────────────────────────────────────────┐
│                      Agent Orchestrator                         │
│  管理多个专门化 Agent 的协作                                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  DataAnalyst    │  │  RiskExpert     │  │  StrategyAdvisor│
│  Agent          │  │  Agent          │  │  Agent          │
│  专注数据分析    │  │  专注风险评估    │  │  专注战略建议    │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Shared Memory & Knowledge                    │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐              │
│  │   STM   │ │   WM    │ │   LTM   │ │   SM    │              │
│  │ Redis   │ │ Redis   │ │ PG+Vec  │ │ Neo4j   │              │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

**Multi-Agent 协作：**

```python
class AgentOrchestrator:
    """多 Agent 编排器"""

    def __init__(self):
        self.agents = {
            "data_analyst": DataAnalystAgent(),
            "risk_expert": RiskExpertAgent(),
            "strategy_advisor": StrategyAdvisorAgent()
        }
        self.shared_memory = SharedMemory()

    async def process_complex_task(self, task: ComplexTask) -> OrchestratedResult:
        """处理复杂任务"""

        # 1. 任务分解
        subtasks = await self._decompose_task(task)

        # 2. 分配给专门 Agent
        assignments = self._assign_subtasks(subtasks)

        # 3. 并行执行独立任务
        independent_results = await asyncio.gather(*[
            self.agents[agent].process(subtask)
            for agent, subtask in assignments["parallel"]
        ])

        # 4. 顺序执行依赖任务
        for agent, subtask in assignments["sequential"]:
            result = await self.agents[agent].process(
                subtask,
                context=self.shared_memory.get_context()
            )
            self.shared_memory.update(result)

        # 5. 综合结果
        return await self._synthesize_results(
            independent_results,
            self.shared_memory
        )
```

**知识图谱集成：**

```python
class KnowledgeGraph:
    """知识图谱（Neo4j）"""

    async def add_decision(self, decision: Decision) -> None:
        """添加决策到知识图谱"""
        await self.driver.run("""
            MERGE (d:Decision {id: $id})
            SET d.query = $query, d.result = $result

            WITH d
            UNWIND $skills as skill_name
            MERGE (s:Skill {name: skill_name})
            MERGE (d)-[:USED_SKILL]->(s)

            WITH d
            UNWIND $entities as entity
            MERGE (e:Entity {name: entity.name, type: entity.type})
            MERGE (d)-[:INVOLVES]->(e)
        """, id=decision.id, query=decision.query, ...)

    async def find_similar_patterns(self, context: Dict) -> List[Pattern]:
        """查找相似决策模式"""
        return await self.driver.run("""
            MATCH (d:Decision)-[:INVOLVES]->(e:Entity)
            WHERE e.type = $entity_type
            MATCH (d)-[:USED_SKILL]->(s:Skill)
            RETURN d, collect(s) as skills, count(*) as frequency
            ORDER BY frequency DESC
            LIMIT 10
        """, entity_type=context.get("entity_type"))
```

---

## 三、技术选型决策

### 3.1 核心技术栈

| 层级 | 技术选型 | 备选方案 | 决策理由 |
|------|---------|---------|---------|
| **语言** | Python 3.11+ | - | 生态丰富、AI友好 |
| **Web框架** | FastAPI | Flask, Django | 异步、自动文档、类型提示 |
| **LLM** | Claude 3.5 Sonnet | GPT-4, Gemini | 性能/成本平衡、Tool Calling |
| **向量库** | Weaviate | Pinecone, Milvus | 开源、混合搜索、自托管 |
| **关系库** | PostgreSQL 15+ | MySQL | 功能丰富、JSON支持 |
| **缓存** | Redis 7+ | Memcached | 数据结构丰富、Pub/Sub |
| **图数据库** | Neo4j | ArangoDB | 成熟、Cypher查询 |
| **前端** | React + TypeScript | Vue | 生态、TypeScript支持 |

### 3.2 ADR 决策摘要

| ADR | 决策 | 关键考量 |
|-----|------|---------|
| ADR-001 | Skill-based 架构 | 模块化、可组合、AI友好 |
| ADR-002 | Weaviate 向量库 | 开源、混合搜索、自托管 |
| ADR-003 | FastAPI 框架 | 异步、自动文档、类型提示 |
| ADR-004 | ReAct + Plan-Execute | 根据任务类型选择 |
| ADR-005 | 四层 Memory 架构 | STM/WM/LTM/SM 分层 |

---

## 四、项目结构

### 4.1 目录结构

```
ceoagent/
├── src/
│   └── ceo_agent/
│       ├── __init__.py
│       ├── main.py                 # FastAPI 入口
│       ├── config.py               # 配置管理
│       │
│       ├── core/                   # 核心模块
│       │   ├── agent.py            # AgentCore
│       │   ├── router.py           # Agent 路由
│       │   ├── claude_client.py    # Claude API 客户端
│       │   └── prompt_manager.py   # Prompt 管理
│       │
│       ├── skills/                 # Skill 系统
│       │   ├── base.py             # BaseSkill
│       │   ├── registry.py         # Skill 注册中心
│       │   ├── executor.py         # Skill 执行器
│       │   ├── data/               # 数据类 Skills
│       │   │   ├── fetch.py
│       │   │   └── analyze.py
│       │   ├── decision/           # 决策类 Skills
│       │   │   ├── risk.py
│       │   │   └── recommend.py
│       │   └── knowledge/          # 知识类 Skills
│       │       └── retrieval.py
│       │
│       ├── agents/                 # Agent 模式
│       │   ├── react.py            # ReAct Agent
│       │   ├── plan_execute.py     # Plan-Execute Agent
│       │   └── orchestrator.py     # Multi-Agent 编排
│       │
│       ├── memory/                 # Memory 系统
│       │   ├── short_term.py       # 短期记忆
│       │   ├── working.py          # 工作记忆
│       │   ├── long_term.py        # 长期记忆
│       │   └── semantic.py         # 语义记忆
│       │
│       ├── rag/                    # RAG 系统
│       │   ├── pipeline.py         # RAG Pipeline
│       │   ├── embedder.py         # 向量化
│       │   └── retriever.py        # 检索器
│       │
│       ├── api/                    # API 层
│       │   ├── routes/
│       │   │   ├── decision.py
│       │   │   ├── data.py
│       │   │   └── knowledge.py
│       │   ├── schemas.py          # Pydantic 模型
│       │   ├── dependencies.py     # 依赖注入
│       │   └── middleware.py       # 中间件
│       │
│       └── utils/                  # 工具模块
│           ├── logging.py
│           └── errors.py
│
├── tests/                          # 测试
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── prompts/                        # Prompt 模板
│   └── v1/
│
├── evaluation/                     # 评估
│   ├── test_cases/
│   └── scripts/
│
├── docker/                         # Docker 配置
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── docs/                           # 文档
│
├── pyproject.toml                  # 项目配置
├── requirements.txt
└── .env.example
```

---

## 五、开发里程碑

### 5.1 里程碑定义

```
┌─────────────────────────────────────────────────────────────────┐
│  M0: 场景验证        │  M1: P0 基础版     │  M2: P1 标准版     │
│  Week 0              │  Week 1-2          │  Week 3-5          │
│  ─────────────────── │ ────────────────── │ ────────────────── │
│  ✓ 3个场景验证通过    │ ✓ AgentCore 可用   │ ✓ Skill 系统运行   │
│  ✓ Prompt 模板 v1    │ ✓ API 端点工作     │ ✓ Tool Calling 集成│
│  ✓ 评估数据集建立    │ ✓ 评估指标达标     │ ✓ Redis+PG 集成   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  M3: P2 增强版       │  M4: P3 完整版     │  M5: 生产就绪      │
│  Week 6-8            │  Week 9-11         │  Week 12           │
│  ─────────────────── │ ────────────────── │ ────────────────── │
│  ✓ ReAct 模式可用    │ ✓ Multi-Agent 协作 │ ✓ 性能优化完成     │
│  ✓ RAG 检索集成      │ ✓ 知识图谱集成     │ ✓ 安全加固         │
│  ✓ Weaviate 集成     │ ✓ 完整 Memory      │ ✓ 部署配置完成     │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 每阶段检查点

#### M0 检查点（Week 0 结束）

| 检查项 | 验收标准 | 负责人 |
|--------|---------|--------|
| 场景定义 | 3个具体场景文档 | - |
| 手动验证 | 每个场景测试 3+ 轮 | - |
| Prompt 模板 | 验证通过的模板 v1 | - |
| 评估数据集 | 10+ 测试用例 | - |
| MVP 范围 | 明确的功能列表 | - |

**M0 通过标准**：至少 2 个场景验证通过，Prompt 输出质量达到预期

#### M1 检查点（Week 2 结束）

| 检查项 | 验收标准 | 负责人 |
|--------|---------|--------|
| 项目结构 | 代码可运行 | - |
| Claude Client | 单元测试通过 | - |
| AgentCore | analyze() 方法工作 | - |
| API 端点 | /analyze 返回正确结果 | - |
| 评估运行 | 自动评估脚本可用 | - |

**M1 通过标准**：API 端点可访问，评估指标达到基线（60%+）

#### M2 检查点（Week 5 结束）

| 检查项 | 验收标准 | 负责人 |
|--------|---------|--------|
| Skill 系统 | 4个 Skills 实现 | - |
| Tool Calling | 集成测试通过 | - |
| Memory | STM + LTM 工作 | - |
| 认证 | JWT 认证可用 | - |
| 评估指标 | 提升至 75%+ | - |

**M2 通过标准**：Tool Calling 集成完成，复杂场景可处理

---

## 六、风险管理

### 6.1 技术风险

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|---------|
| Claude API 不稳定 | 中 | 高 | 重试机制、降级方案 |
| Tool Calling 效果差 | 中 | 高 | 提前验证、备选方案 |
| 向量检索质量低 | 中 | 中 | 多向量模型对比测试 |
| 复杂任务超时 | 高 | 中 | 流式响应、任务拆分 |

### 6.2 项目风险

| 风险 | 可能性 | 影响 | 缓解措施 |
|------|--------|------|---------|
| 需求范围蔓延 | 高 | 高 | 严格 MVP 边界 |
| 架构过度设计 | 高 | 中 | 分阶段实现 |
| 验证不充分 | 中 | 高 | 每阶段评估检查点 |

### 6.3 决策点

每个阶段结束时的决策点：

```
阶段结束 → 评估结果 → 决策
              │
              ├── 达标 → 继续下一阶段
              │
              ├── 部分达标 → 调整后继续
              │
              └── 未达标 → 回滚/重新设计
```

---

## 七、下一步行动

### 立即执行（本周）

1. **完成 M0 场景验证**
   - 补充剩余 2 个场景文档
   - 执行手动验证测试
   - 提炼 Prompt 模板

2. **准备开发环境**
   - 创建项目骨架
   - 配置开发工具（pre-commit、pytest）
   - 准备 Docker 开发环境

3. **确认技术选型**
   - 验证 Claude API 访问
   - 测试 Tool Calling 基础功能
   - 确认团队技术栈熟悉度

### 本文档维护

- 每个阶段结束后更新进度
- 发现问题时更新风险表
- 技术决策变更时更新 ADR
