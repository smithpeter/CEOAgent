# ADR-004: ReAct vs Plan-and-Execute

## 状态
已接受

## 上下文

AI Agent 需要选择推理和执行模式。主流方案：
1. **ReAct (Reasoning + Acting)**：推理-行动循环，动态决策
2. **Plan-and-Execute**：先规划再执行，结构化流程
3. **Reflexion**：执行后反思，自我修正
4. **单一模式**：只使用一种模式

## 决策

我们决定**同时支持 ReAct 和 Plan-and-Execute**，根据任务类型选择合适模式。

## 理由

### ReAct 模式

**适用场景**：
- 开放式、探索性任务
- 需要动态调整策略
- 不确定的任务步骤
- 需要多次迭代和试错

**优势**：
- 灵活性强，可以动态调整
- 适合复杂推理任务
- Agent 可以学习并改进策略

**劣势**：
- 可能产生不必要的迭代
- 执行时间可能较长

### Plan-and-Execute 模式

**适用场景**：
- 有明确步骤的任务
- 可以预见的任务流程
- 需要高效执行
- 可以并行执行的任务

**优势**：
- 执行效率高
- 可以并行执行独立任务
- 任务步骤清晰

**劣势**：
- 需要预先规划，不适合探索性任务
- 规划可能不准确

### 混合策略

我们实现一个**智能路由**，根据任务特征选择合适的模式：

```python
class AgentRouter:
    """Agent 路由，选择合适的执行模式"""
    
    def select_mode(self, task: Task) -> str:
        """根据任务特征选择模式"""
        
        # 如果任务有明确的步骤，使用 Plan-and-Execute
        if task.has_clear_steps:
            return "plan_and_execute"
        
        # 如果任务需要探索，使用 ReAct
        if task.is_exploratory:
            return "react"
        
        # 默认使用 ReAct（更灵活）
        return "react"
```

## 后果

### 积极影响

1. **灵活性**：可以根据任务选择合适的模式
2. **性能优化**：Plan-and-Execute 提升执行效率
3. **适应性**：ReAct 支持复杂推理
4. **可扩展**：未来可以添加更多模式（如 Reflexion）

### 消极影响

1. **实现复杂度**：需要实现两种模式
2. **选择逻辑**：需要智能的路由逻辑

### 缓解措施

- 提供清晰的模式选择指南
- 默认使用 ReAct（更通用）
- 提供配置选项让用户指定模式

## 实施建议

### 第一阶段
- 实现 ReAct 模式（更通用）

### 第二阶段
- 实现 Plan-and-Execute 模式
- 实现智能路由

### 第三阶段
- 添加 Reflexion 模式
- 优化模式选择逻辑

## 参考

- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [DEVELOPMENT_PLAN.md](../DEVELOPMENT_PLAN.md)
