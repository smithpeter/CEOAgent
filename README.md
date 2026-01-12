# CEOAgent - CEO 决策智能体项目

## 项目简介

CEOAgent 是一个基于 AI 的 CEO 决策智能体系统，旨在帮助 CEO 进行高效、智能的决策支持。

## 需求来源

参考文档：[创建 CEO 决策智能体](https://www.doubao.com/thread/w7f3a3232a1fad0d4)

## Claude Code 与 Cursor 集成指南

### 方式一：在 Cursor 中使用 Claude Code 扩展

1. **安装 Claude Code 扩展**
   - 打开 Cursor 编辑器
   - 使用快捷键 `Cmd+Shift+X` 打开扩展面板
   - 搜索 "Claude Code" 或 "Anthropic"
   - 安装官方扩展

2. **配置 API 密钥**
   - 进入设置（`Cmd+,`）
   - 找到 "AI" 或 "Claude Configuration" 部分
   - 输入您的 Claude API 密钥
   - 选择模型版本（推荐 Claude 3.5 Sonnet 或 Opus）

3. **使用方式**
   - 在编辑器中输入自然语言描述，Claude Code 会自动提供代码建议
   - 使用 `Cmd+K` 打开 AI 命令面板
   - 选中代码后，使用 `Cmd+L` 进行代码重构或优化

### 方式二：使用命令行 claude-code 工具

已在系统中安装 `@anthropic-ai/claude-code@2.1.4`，可通过以下方式使用：

```bash
# 通过 npx 运行
npx @anthropic-ai/claude-code --help

# 在项目目录中使用
cd /Users/zouyongming/dev/CEOAgent
npx @anthropic-ai/claude-code <command>
```

### 方式三：在项目中集成 claude-code

可以在项目中使用 claude-code 进行：
- 代码生成
- 代码审查
- 文档生成
- 需求分析

## 快速开始

### 🚀 5 分钟快速上手

请查看 **[快速开始指南](./QUICK_START.md)**，包含：
- 环境设置步骤
- 使用 Claude Code + Cursor 生成项目结构
- 开发第一个 Skill 的完整流程
- 常用快捷键和技巧

### 📚 文档导航

1. **需求文档** ([REQUIREMENTS.md](./REQUIREMENTS.md)) - 了解业务需求
2. **开发计划** ([DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md)) - 详细技术实现计划
3. **Skill 架构** ([SKILL_ARCHITECTURE.md](./SKILL_ARCHITECTURE.md)) - Skill-based 架构设计
4. **集成指南** ([INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)) - Cursor 使用技巧

### 💡 快速命令

在 Cursor 中开始开发：

```bash
# 1. 打开项目
cd /Users/zouyongming/dev/CEOAgent

# 2. 在 Cursor 中按 Cmd+L，输入：
"请按照 DEVELOPMENT_PLAN.md 生成项目初始结构"
```

## 项目结构

```
CEOAgent/
├── README.md                    # 项目说明（本文件）
├── REQUIREMENTS.md              # 需求文档
├── DEVELOPMENT_PLAN.md          # 详细开发计划（含 Skill 架构和 AI Agent 技术）
├── ARCHITECTURE.md              # 系统架构详细设计（含架构图）⭐ 新增
├── MEMORY_SYSTEM.md             # Memory 系统设计文档 ⭐ 新增
├── SECURITY.md                  # 安全架构与最佳实践 ⭐ 新增
├── PERFORMANCE.md               # 性能优化指南 ⭐ 新增
├── API_DESIGN.md                # API 设计规范 ⭐ 新增
├── DEPLOYMENT.md                # 部署架构与运维指南 ⭐ 新增
├── MONITORING.md                # 监控与可观测性指南 ⭐ 新增
├── UI_DESIGN_GUIDE.md           # UI 设计指南 ⭐ 新增
├── USE_CASES.md                 # 用例定义与验证文档 ⭐ 新增
├── VERIFICATION_CHECKLIST.md    # 目标验证检查清单 ⭐ 新增
├── SKILL_ARCHITECTURE.md        # Skill-based 架构详细设计
├── INTEGRATION_GUIDE.md         # Claude Code 与 Cursor 集成详细指南
├── QUICK_START.md               # 快速开始指南
├── UPDATE_CLAUDE_CODE.md        # Claude Code 更新指南
├── ADR/                         # 架构决策记录目录 ⭐ 新增
│   ├── README.md
│   ├── ADR-001-skill-based-architecture.md
│   ├── ADR-002-vector-database-selection.md
│   ├── ADR-003-backend-framework-selection.md
│   ├── ADR-004-react-vs-plan-and-execute.md
│   └── ADR-005-memory-system-architecture.md
├── .cursorrules                 # Cursor AI 项目配置规则（Skill 架构规范）
└── ...                          # 其他项目文件
```

## 技术架构亮点

### Skill-based Agent 架构
- 🎯 **模块化 Skills**：每个功能作为独立 Skill，易于扩展和维护
- 🔧 **Skill 组合**：支持多 Skill 组合执行复杂任务
- 📚 **Skill 注册中心**：统一的 Skill 管理和发现机制
- 🧠 **Skill 学习**：从历史决策中学习优化

### 最新 AI Agent 技术
- 🧩 **ReAct 模式**：推理-行动循环，动态决策
- 📋 **Plan-and-Execute**：复杂任务分解和执行
- 🔨 **Tool Calling**：Claude API 函数调用集成
- 🔍 **RAG 系统**：检索增强生成，知识库集成
- 💾 **向量数据库**：语义检索和知识管理

## 相关文档

### 快速开始
- 🚀 [快速开始](./QUICK_START.md) - 5分钟快速上手指南

### 核心文档
- 📋 [需求文档](./REQUIREMENTS.md) - 详细的业务需求和技术需求
- 🚀 [开发计划](./DEVELOPMENT_PLAN.md) - 详细开发计划，包含 Skill 架构和 AI Agent 技术实现
- 🏗️ [系统架构](./ARCHITECTURE.md) - **系统架构详细设计（含架构图）** ⭐
- 🎯 [架构优化方案](./ARCHITECTURE_ENHANCED.md) - **基于最新需求的优化架构方案（推荐）** ⭐ 新增
- 🧠 [Memory 系统](./MEMORY_SYSTEM.md) - **Memory 系统设计文档** ⭐
- 🏛️ [Skill 架构](./SKILL_ARCHITECTURE.md) - Skill-based AI Agent 架构详细设计

### 技术文档
- 🔒 [安全架构](./SECURITY.md) - **安全架构与最佳实践** ⭐
- ⚡ [性能优化](./PERFORMANCE.md) - **性能优化指南** ⭐
- 📡 [API 设计](./API_DESIGN.md) - **API 设计规范** ⭐
- 🚢 [部署指南](./DEPLOYMENT.md) - **部署架构与运维指南** ⭐
- 📊 [监控指南](./MONITORING.md) - **监控与可观测性指南** ⭐
- 🔄 [CI/CD 指南](./CICD.md) - **CI/CD 自动化流程与运维** ⭐ 新增
- 🛠️ [运维手册](./OPERATIONS.md) - **日常运维与故障排查** ⭐ 新增

### 设计文档
- 🎨 [UI 设计指南](./UI_DESIGN_GUIDE.md) - **UI/UX 设计方法论与规范** ⭐ 新增
- 📝 [用例定义](./USE_CASES.md) - **用例详细定义与验证标准** ⭐ 新增
- ✅ [验证检查清单](./VERIFICATION_CHECKLIST.md) - **目标验证方法与实践** ⭐ 新增

### 开发工具
- 🔧 [集成指南](./INTEGRATION_GUIDE.md) - Claude Code 与 Cursor 完整使用指南
- 🔄 [更新指南](./UPDATE_CLAUDE_CODE.md) - 如何更新 Claude Code 版本

### 架构决策
- 📝 [架构决策记录](./ADR/) - 关键技术决策文档 ⭐
