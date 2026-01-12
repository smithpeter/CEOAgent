# Skill-based AI Agent 架构设计

## 架构概述

CEOAgent 采用 **Skill-based AI Agent** 架构，将每个功能模块设计为独立的、可组合的 Skill。这种架构具有高度的模块化、可扩展性和可维护性。

## 核心概念

### 什么是 Skill？

Skill 是一个自包含的功能单元，具有以下特征：

- **独立执行**：可以独立完成任务
- **定义明确**：有明确的输入参数和输出格式
- **可组合**：可以与其他 Skill 组合执行复杂任务
- **可复用**：可以被多个 Agent 或场景复用
- **可测试**：易于编写单元测试

### Skill vs Function vs Tool

| 特性 | Skill | Function | Tool |
|------|-------|----------|------|
| 抽象级别 | 高 | 中 | 低 |
| 业务语义 | 强 | 中 | 弱 |
| 可组合性 | 高 | 中 | 低 |
| 上下文理解 | 是 | 部分 | 否 |
| AI 集成 | 原生 | 需适配 | 需适配 |

## 架构层次

```
┌─────────────────────────────────────────┐
│         Application Layer               │
│  (FastAPI Routes, WebSocket, CLI)      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Agent Orchestration            │
│  (ReAct, Plan-and-Execute, Multi-Agent)│
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Skill Execution Layer           │
│  (SkillExecutor, SkillComposer)        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Skill Registry                 │
│  (Skill Discovery, Metadata)           │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            Individual Skills            │
│  (DataCollection, Analysis, Decision...)│
└─────────────────────────────────────────┘
```

## Skill 基类设计

### BaseSkill 接口

```python
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field

class SkillParams(BaseModel):
    """Skill 参数的基类"""
    pass

class SkillResult(BaseModel):
    """Skill 执行结果的基类"""
    success: bool = Field(..., description="执行是否成功")
    data: Any = Field(default=None, description="返回数据")
    error: Optional[str] = Field(default=None, description="错误信息")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="元数据")

class BaseSkill(ABC):
    """Skill 基类"""
    
    name: str  # Skill 唯一标识
    description: str  # Skill 描述
    version: str = "1.0.0"  # Skill 版本
    category: str  # Skill 分类（data, decision, knowledge等）
    
    @abstractmethod
    async def execute(self, params: SkillParams) -> SkillResult:
        """执行 Skill"""
        pass
    
    @abstractmethod
    def get_schema(self) -> Dict[str, Any]:
        """获取 Skill 的 schema（用于 Tool Calling）"""
        pass
    
    def validate(self, params: SkillParams) -> bool:
        """验证参数"""
        return True
    
    def get_required_skills(self) -> list[str]:
        """获取依赖的 Skills"""
        return []
```

### 示例：DataCollectionSkill

```python
from typing import Literal
from pydantic import BaseModel, Field
from ceo_agent.core.skill import BaseSkill, SkillParams, SkillResult

class DataCollectionParams(SkillParams):
    """数据收集参数"""
    data_source: Literal["financial", "market", "operations"] = Field(
        ..., description="数据源类型"
    )
    query: str = Field(..., description="查询条件")
    date_range: tuple[str, str] = Field(..., description="日期范围")
    format: Literal["json", "csv"] = Field(default="json", description="返回格式")

class DataCollectionSkill(BaseSkill):
    """数据收集 Skill"""
    
    name = "data_collection"
    description = "从多个数据源收集数据（财务、市场、运营）"
    category = "data"
    
    async def execute(self, params: DataCollectionParams) -> SkillResult:
        """执行数据收集"""
        try:
            # 实现数据收集逻辑
            data = await self._collect_data(
                params.data_source,
                params.query,
                params.date_range
            )
            
            return SkillResult(
                success=True,
                data=data,
                metadata={
                    "source": params.data_source,
                    "record_count": len(data)
                }
            )
        except Exception as e:
            return SkillResult(
                success=False,
                error=str(e)
            )
    
    def get_schema(self) -> Dict[str, Any]:
        """获取 Tool Calling schema"""
        return {
            "name": self.name,
            "description": self.description,
            "input_schema": DataCollectionParams.model_json_schema()
        }
    
    async def _collect_data(self, source: str, query: str, date_range: tuple):
        """内部数据收集方法"""
        # 具体实现
        pass
```

## Skill Registry（技能注册中心）

### 功能

- **注册 Skills**：管理所有可用 Skills
- **发现 Skills**：根据需求查找合适的 Skills
- **元数据管理**：维护 Skill 的元数据信息
- **版本控制**：支持 Skill 版本管理

### 实现

```python
from typing import Dict, List, Optional
from ceo_agent.core.skill import BaseSkill

class SkillRegistry:
    """Skill 注册中心"""
    
    def __init__(self):
        self._skills: Dict[str, BaseSkill] = {}
        self._skills_by_category: Dict[str, List[str]] = {}
    
    def register(self, skill: BaseSkill) -> None:
        """注册 Skill"""
        self._skills[skill.name] = skill
        category = skill.category
        if category not in self._skills_by_category:
            self._skills_by_category[category] = []
        self._skills_by_category[category].append(skill.name)
    
    def get(self, name: str) -> Optional[BaseSkill]:
        """获取 Skill"""
        return self._skills.get(name)
    
    def list_by_category(self, category: str) -> List[BaseSkill]:
        """按分类列出 Skills"""
        skill_names = self._skills_by_category.get(category, [])
        return [self._skills[name] for name in skill_names]
    
    def get_all_tools(self) -> List[Dict[str, Any]]:
        """获取所有 Skills 的 Tool schema（用于 Claude API）"""
        return [skill.get_schema() for skill in self._skills.values()]
```

## Skill Executor（技能执行器）

### 功能

- **执行 Skill**：调用 Skill 的 execute 方法
- **参数验证**：在执行前验证参数
- **错误处理**：统一的错误处理机制
- **结果处理**：标准化返回结果

### 实现

```python
from typing import Any, Dict
from ceo_agent.core.skill import BaseSkill, SkillParams, SkillResult
from ceo_agent.core.registry import SkillRegistry
import logging

logger = logging.getLogger(__name__)

class SkillExecutor:
    """Skill 执行器"""
    
    def __init__(self, registry: SkillRegistry):
        self.registry = registry
    
    async def execute(
        self, 
        skill_name: str, 
        params: Dict[str, Any]
    ) -> SkillResult:
        """执行 Skill"""
        skill = self.registry.get(skill_name)
        if not skill:
            return SkillResult(
                success=False,
                error=f"Skill '{skill_name}' not found"
            )
        
        try:
            # 验证参数
            skill_params = skill.get_params_class()(**params)
            if not skill.validate(skill_params):
                return SkillResult(
                    success=False,
                    error="Parameter validation failed"
                )
            
            # 执行 Skill
            result = await skill.execute(skill_params)
            
            logger.info(
                f"Skill '{skill_name}' executed: "
                f"success={result.success}"
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error executing skill '{skill_name}': {e}")
            return SkillResult(
                success=False,
                error=str(e)
            )
```

## Skill Composition（技能组合）

### 功能

- **组合执行**：将多个 Skills 组合执行
- **依赖管理**：处理 Skill 之间的依赖关系
- **并行执行**：支持独立 Skills 的并行执行
- **流水线处理**：支持数据在 Skills 之间传递

### 实现

```python
from typing import List, Dict, Any
from ceo_agent.core.executor import SkillExecutor
import asyncio

class SkillComposer:
    """Skill 组合器"""
    
    def __init__(self, executor: SkillExecutor):
        self.executor = executor
    
    async def execute_sequence(
        self, 
        skill_chain: List[Dict[str, Any]]
    ) -> List[Any]:
        """顺序执行 Skill 链"""
        results = []
        previous_output = None
        
        for step in skill_chain:
            skill_name = step["skill"]
            params = step.get("params", {})
            
            # 如果前一步有输出，将其作为输入
            if previous_output:
                params.update(previous_output)
            
            result = await self.executor.execute(skill_name, params)
            results.append(result)
            
            if not result.success:
                break
            
            previous_output = result.data
        
        return results
    
    async def execute_parallel(
        self,
        skills: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """并行执行多个独立的 Skills"""
        tasks = [
            self.executor.execute(skill["skill"], skill.get("params", {}))
            for skill in skills
        ]
        
        results = await asyncio.gather(*tasks)
        
        return {
            skill["skill"]: result
            for skill, result in zip(skills, results)
        }
```

## AI Agent 集成

### Tool Calling 集成

将 Skills 转换为 Claude API 的 Tool：

```python
from anthropic import Anthropic

class AgentWithSkills:
    """集成 Skills 的 AI Agent"""
    
    def __init__(self, registry: SkillRegistry, executor: SkillExecutor):
        self.registry = registry
        self.executor = executor
        self.client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    
    async def process_request(self, user_input: str) -> str:
        """处理用户请求"""
        # 获取所有 Skills 的 Tool schema
        tools = self.registry.get_all_tools()
        
        # 调用 Claude API
        response = self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{"role": "user", "content": user_input}],
            tools=tools
        )
        
        # 处理 Tool Calling
        for content in response.content:
            if content.type == "tool_use":
                # 执行对应的 Skill
                result = await self.executor.execute(
                    content.name,
                    content.input
                )
                
                # 将结果返回给 Claude
                # ...继续对话
        
        return response.content[0].text
```

### ReAct 模式集成

```python
class ReActAgent:
    """ReAct Agent"""
    
    def __init__(self, executor: SkillExecutor):
        self.executor = executor
        self.max_iterations = 10
    
    async def reason_and_act(self, query: str) -> str:
        """推理-行动循环"""
        observations = []
        
        for i in range(self.max_iterations):
            # 推理阶段：分析当前状态，决定下一步行动
            reasoning = await self._reason(query, observations)
            
            # 行动阶段：执行 Skill
            action = await self._plan_action(reasoning)
            
            if action["type"] == "skill":
                result = await self.executor.execute(
                    action["skill"],
                    action["params"]
                )
                observations.append(result)
                
                if action["done"]:
                    break
            
            elif action["type"] == "final_answer":
                return action["answer"]
        
        return self._synthesize_answer(observations)
```

## Skill 分类体系

### Data Skills（数据类）

- `DataCollectionSkill` - 数据收集
- `DataAnalysisSkill` - 数据分析
- `DataVisualizationSkill` - 数据可视化
- `DataCleaningSkill` - 数据清洗

### Decision Skills（决策类）

- `ScenarioAnalysisSkill` - 场景分析
- `RiskAssessmentSkill` - 风险评估
- `DecisionRecommendationSkill` - 决策建议
- `OptimizationSkill` - 优化分析

### Knowledge Skills（知识类）

- `KnowledgeRetrievalSkill` - 知识检索
- `KnowledgeStorageSkill` - 知识存储
- `LearningSkill` - 学习能力
- `KnowledgeGraphSkill` - 知识图谱

### Integration Skills（集成类）

- `APIIntegrationSkill` - API 集成
- `DatabaseQuerySkill` - 数据库查询
- `FileProcessingSkill` - 文件处理

## 开发新 Skill 的流程

### 1. 定义 Skill 类

```python
class MyNewSkill(BaseSkill):
    name = "my_new_skill"
    description = "我的新 Skill 描述"
    category = "custom"
    
    async def execute(self, params: MyParams) -> SkillResult:
        # 实现逻辑
        pass
```

### 2. 注册 Skill

```python
from ceo_agent.core.registry import SkillRegistry

registry = SkillRegistry()
registry.register(MyNewSkill())
```

### 3. 编写测试

```python
@pytest.mark.asyncio
async def test_my_new_skill():
    skill = MyNewSkill()
    params = MyParams(...)
    result = await skill.execute(params)
    assert result.success
```

### 4. 添加到 Agent

```python
# Skills 会自动被 Agent 发现和使用
agent = AgentWithSkills(registry, executor)
```

## 最佳实践

1. **单一职责**：每个 Skill 只做一件事
2. **参数验证**：使用 Pydantic 严格验证参数
3. **错误处理**：完善的错误处理和日志
4. **文档完整**：清晰的文档字符串
5. **测试覆盖**：高测试覆盖率
6. **异步优先**：使用 async/await 提高性能
7. **无状态设计**：Skill 应该是无状态的
8. **版本管理**：支持 Skill 版本控制

## 中间件集成

### Skill 中间件

```python
from typing import Callable, Awaitable
from ceo_agent.core.skill import SkillResult, SkillParams

class SkillMiddleware:
    """Skill 中间件基类"""
    
    async def before_execute(
        self,
        skill_name: str,
        params: SkillParams
    ) -> SkillParams:
        """执行前的处理"""
        return params
    
    async def after_execute(
        self,
        skill_name: str,
        params: SkillParams,
        result: SkillResult
    ) -> SkillResult:
        """执行后的处理"""
        return result

class CacheMiddleware(SkillMiddleware):
    """缓存中间件"""
    
    async def before_execute(self, skill_name: str, params: SkillParams):
        # 检查缓存
        cached = await cache.get(skill_name, params.dict())
        if cached:
            return cached
        return params
    
    async def after_execute(self, skill_name: str, params: SkillParams, result: SkillResult):
        # 缓存结果
        if result.success:
            await cache.set(skill_name, params.dict(), result.dict())
        return result

class RateLimitMiddleware(SkillMiddleware):
    """限流中间件"""
    
    async def before_execute(self, skill_name: str, params: SkillParams):
        if not await rate_limiter.acquire(f"skill:{skill_name}"):
            raise RateLimitError(f"Rate limit exceeded for skill: {skill_name}")
        return params

class LoggingMiddleware(SkillMiddleware):
    """日志中间件"""
    
    async def before_execute(self, skill_name: str, params: SkillParams):
        logger.info(f"Executing skill: {skill_name}", params=params.dict())
        return params
    
    async def after_execute(self, skill_name: str, params: SkillParams, result: SkillResult):
        logger.info(
            f"Skill execution completed: {skill_name}",
            success=result.success,
            execution_time_ms=getattr(result, 'execution_time_ms', None)
        )
        return result

class MetricsMiddleware(SkillMiddleware):
    """指标中间件"""
    
    async def before_execute(self, skill_name: str, params: SkillParams):
        skill_executions_total.labels(skill_name=skill_name).inc()
        return params
    
    async def after_execute(self, skill_name: str, params: SkillParams, result: SkillResult):
        skill_execution_duration_seconds.labels(skill_name=skill_name).observe(
            getattr(result, 'execution_time_ms', 0) / 1000
        )
        return result
```

### 中间件链

```python
class MiddlewareChain:
    """中间件链"""
    
    def __init__(self, middlewares: List[SkillMiddleware]):
        self.middlewares = middlewares
    
    async def execute_with_middleware(
        self,
        skill: BaseSkill,
        params: SkillParams
    ) -> SkillResult:
        """通过中间件链执行 Skill"""
        
        # 执行前置中间件
        for middleware in self.middlewares:
            params = await middleware.before_execute(skill.name, params)
        
        # 执行 Skill
        start_time = time.time()
        result = await skill.execute(params)
        execution_time = time.time() - start_time
        result.execution_time_ms = execution_time * 1000
        
        # 执行后置中间件（逆序）
        for middleware in reversed(self.middlewares):
            result = await middleware.after_execute(skill.name, params, result)
        
        return result
```

## Self-Correction 集成

### Validation Skills

```python
class ValidationSkill(BaseSkill):
    """结果验证 Skill"""
    
    name = "result_validation"
    description = "验证 Skill 执行结果的正确性"
    category = "system"
    
    async def execute(self, params: ValidationParams) -> SkillResult:
        """验证结果"""
        original_skill = params.original_skill
        original_result = params.original_result
        
        # 验证逻辑
        validation_result = await self._validate_result(
            original_skill,
            original_result
        )
        
        if not validation_result.is_valid:
            # 返回修正建议
            return SkillResult(
                success=False,
                error="Validation failed",
                metadata={
                    "corrections": validation_result.corrections,
                    "suggestions": validation_result.suggestions
                }
            )
        
        return SkillResult(success=True, data=validation_result)
```

### Reflexion 模式

```python
class ReflexionAgent:
    """Reflexion Agent - 自我反思和修正"""
    
    async def execute_with_reflection(
        self,
        skill_name: str,
        params: Dict
    ) -> SkillResult:
        """执行后反思"""
        max_iterations = 3
        
        for iteration in range(max_iterations):
            # 执行 Skill
            result = await skill_executor.execute(skill_name, params)
            
            # 反思结果质量
            reflection = await self._reflect(result, iteration)
            
            if reflection.should_retry:
                # 修正参数
                params = reflection.corrected_params
                continue
            else:
                return result
        
        return result
```

## 总结

Skill-based 架构为 CEOAgent 提供了：

- ✅ **模块化**：功能清晰分离
- ✅ **可扩展**：易于添加新功能
- ✅ **可组合**：灵活组合完成任务
- ✅ **可测试**：易于编写和维护测试
- ✅ **AI 友好**：完美集成 Claude API Tool Calling
- ✅ **中间件支持**：灵活的扩展机制
- ✅ **自我修正**：支持 Reflexion 和结果验证

这个架构使得 CEOAgent 能够灵活应对各种决策场景，同时保持代码的清晰和可维护性。

## 参考文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构
- [MEMORY_SYSTEM.md](./MEMORY_SYSTEM.md) - Memory 系统
- [PERFORMANCE.md](./PERFORMANCE.md) - 性能优化
- [SECURITY.md](./SECURITY.md) - 安全架构
