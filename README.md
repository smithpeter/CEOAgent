# CEOAgent - CEO 决策智能体项目

## 项目简介

CEOAgent 是一个基于 AI 的 CEO 决策智能体系统，旨在帮助 CEO 进行高效、智能的决策支持。

> **核心价值**：将 Claude 的分析能力与结构化的决策框架结合，提供可执行的决策建议。

## 快速开始

### 🚀 5 分钟快速上手

请查看 **[快速开始指南](docs/guides/QUICK_START.md)**

### 📚 文档导航

所有文档已整理到 `docs/` 目录，查看 **[文档索引](docs/README.md)** 获取完整导航。

| 需求 | 文档 |
|------|------|
| 🚀 新手入门 | [docs/guides/START_HERE.md](docs/guides/START_HERE.md) |
| 📋 了解需求 | [docs/product/PRD_decision_analysis.md](docs/product/PRD_decision_analysis.md) |
| 🏗️ 了解架构 | [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) |
| 💻 后端开发 | [docs/backend/BACKEND_DEV_GUIDE.md](docs/backend/BACKEND_DEV_GUIDE.md) |
| 🎨 前端开发 | [docs/frontend/UI_DESIGN_GUIDE.md](docs/frontend/UI_DESIGN_GUIDE.md) |
| 🚢 部署运维 | [docs/devops/DEPLOYMENT.md](docs/devops/DEPLOYMENT.md) |

---

## 项目结构

```
CEOAgent/
├── README.md                 # 项目说明（本文件）
├── CLAUDE.md                 # AI Agent 指令
├── MASTER_PLAN.md            # 主开发计划（权威）
├── REQUIREMENTS.md           # 需求概述
│
├── # 协作文件
├── TASKS.md                  # 任务看板
├── DECISIONS.md              # CEO 决策
├── REVIEWS.md                # 评审记录
├── QUESTIONS.md              # 待澄清问题
├── ISSUES.md                 # 问题追踪
├── CHANGELOG.md              # 变更日志
│
├── # 文档目录
├── docs/
│   ├── README.md             # 文档索引 ⭐
│   ├── guides/               # 快速指南
│   ├── product/              # 产品文档
│   ├── architecture/         # 架构文档
│   ├── backend/              # 后端文档
│   ├── frontend/             # 前端文档
│   ├── devops/               # 运维文档
│   ├── management/           # 项目管理
│   ├── testing/              # 测试文档
│   └── validation/           # 验证记录
│
├── # 其他目录
├── .claude/                  # 多角色协作配置
├── ADR/                      # 架构决策记录
├── scenarios/                # 场景验证
├── prompts/                  # Prompt 模板
├── scripts/                  # 脚本工具
├── tests/                    # 测试代码
├── evaluation/               # 评估数据
├── k8s/                      # K8s 配置
└── monitoring/               # 监控配置
```

---

## 技术架构亮点

### Skill-based Agent 架构
- 🎯 **模块化 Skills**：每个功能作为独立 Skill，易于扩展和维护
- 🔧 **Skill 组合**：支持多 Skill 组合执行复杂任务
- 📚 **Skill 注册中心**：统一的 Skill 管理和发现机制

### 最新 AI Agent 技术
- 🧩 **ReAct 模式**：推理-行动循环，动态决策
- 📋 **Plan-and-Execute**：复杂任务分解和执行
- 🔨 **Tool Calling**：Claude API 函数调用集成
- 🔍 **RAG 系统**：检索增强生成，知识库集成

---

## 多角色协作

本项目支持多角色 AI Agent 协作开发，查看 [.claude/MULTI_AGENT_GUIDE.md](.claude/MULTI_AGENT_GUIDE.md)

| 角色 | 职责 |
|------|------|
| 产品经理 | 需求分析、用户故事 |
| 架构师 | 架构设计、技术选型 |
| 开发经理 | 任务拆解、进度管理 |
| 后端开发 | API 设计、数据模型 |
| 前端开发 | UI 设计、交互流程 |
| 测试工程师 | 测试计划、测试用例 |
| 运维工程师 | 部署、CI/CD、监控 |

---

## 核心文档快速链接

### 计划与规划
- [MASTER_PLAN.md](MASTER_PLAN.md) - 主开发计划（权威）
- [docs/management/planning/](docs/management/planning/) - 详细计划

### 架构设计
- [docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - 系统架构
- [docs/architecture/API_DESIGN.md](docs/architecture/API_DESIGN.md) - API 设计
- [ADR/](ADR/) - 架构决策记录

### 开发指南
- [docs/backend/BACKEND_DEV_GUIDE.md](docs/backend/BACKEND_DEV_GUIDE.md) - 后端开发
- [docs/frontend/UI_DESIGN_GUIDE.md](docs/frontend/UI_DESIGN_GUIDE.md) - 前端开发

### 运维部署
- [docs/devops/DEPLOYMENT.md](docs/devops/DEPLOYMENT.md) - 部署指南
- [docs/devops/CICD.md](docs/devops/CICD.md) - CI/CD

---

## 相关链接

- 需求来源：[创建 CEO 决策智能体](https://www.doubao.com/thread/w7f3a3232a1fad0d4)
