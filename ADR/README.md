# 架构决策记录 (ADR)

## 什么是 ADR？

架构决策记录（Architecture Decision Records）是一种记录架构决策的文档，帮助团队理解为什么做出某个技术选择。

## ADR 格式

每个 ADR 文件命名格式：`ADR-<序号>-<简短描述>.md`

例如：
- `ADR-001-skill-based-architecture.md`
- `ADR-002-vector-database-selection.md`

## ADR 模板

```markdown
# ADR-XXX: [标题]

## 状态
[提议 | 已接受 | 已弃用 | 已替代]

## 上下文
为什么需要这个决策？

## 决策
我们决定做什么？

## 后果
这个决策的积极和消极影响是什么？
```

## ADR 列表

- [ADR-001: Skill-based 架构选择](./ADR-001-skill-based-architecture.md)
- [ADR-002: 向量数据库选择 - Weaviate](./ADR-002-vector-database-selection.md)
- [ADR-003: 后端框架选择 - FastAPI](./ADR-003-backend-framework-selection.md)
- [ADR-004: ReAct vs Plan-and-Execute](./ADR-004-react-vs-plan-and-execute.md)
- [ADR-005: Memory 系统架构](./ADR-005-memory-system-architecture.md)
