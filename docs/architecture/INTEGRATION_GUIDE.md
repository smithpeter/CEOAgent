# Claude Code 与 Cursor 集成完整指南

## 概述

本指南说明如何在 CEOAgent 项目中有效结合使用 Claude Code 和 Cursor 编辑器。

## 三种使用方式

### 方式一：Cursor 内置 AI 功能（推荐）

Cursor 已经内置了强大的 AI 功能，类似于 Claude Code。

**使用方法：**
1. **AI 对话**：按 `Cmd+L` 打开 AI 对话面板
2. **代码生成**：选中代码后按 `Cmd+K` 进行代码编辑
3. **快速命令**：按 `Cmd+Shift+L` 打开命令面板

**示例操作：**
- 在编辑器中输入注释：`// 生成一个决策分析类`
- 选中注释，按 `Cmd+K`，AI 会自动生成代码
- 按 `Cmd+L` 可以询问："如何优化这个函数的性能？"

### 方式二：Cursor 扩展市场安装 Claude Code 扩展

1. **安装扩展**
   ```
   Cursor → 扩展图标 (Cmd+Shift+X) → 搜索 "Claude" → 安装
   ```

2. **配置 API**
   - 如果有独立的 Claude API 密钥，可以在设置中配置
   - Cursor 通常使用自己的 API 集成

### 方式三：命令行使用 claude-code 工具

已安装 `@anthropic-ai/claude-code@2.1.4`

**基本用法：**
```bash
# 查看帮助
npx @anthropic-ai/claude-code --help

# 分析代码文件
npx @anthropic-ai/claude-code analyze src/main.py

# 生成代码
npx @anthropic-ai/claude-code generate --prompt "创建一个决策分析类"
```

**在项目中使用：**
```bash
# 在项目根目录运行
cd /Users/zouyongming/dev/CEOAgent

# 分析需求文档
npx @anthropic-ai/claude-code analyze REQUIREMENTS.md

# 生成项目结构建议
npx @anthropic-ai/claude-code suggest --type=architecture
```

## 实际工作流程

### 1. 需求分析阶段

在 Cursor 中：
- 打开 `REQUIREMENTS.md`
- 按 `Cmd+L` 询问："基于这个需求文档，生成一个技术架构方案"
- 让 AI 帮你补充需求细节

### 2. 代码开发阶段

**场景 A：生成新功能**
```
1. 创建新文件：src/decision_engine.py
2. 输入注释：# CEO 决策引擎核心类
3. 按 Cmd+K，让 AI 生成基础代码结构
4. 逐步完善功能，持续使用 Cmd+L 获取建议
```

**场景 B：重构现有代码**
```
1. 选中需要重构的代码
2. 按 Cmd+K，输入："重构这段代码，提高可读性和性能"
3. AI 会提供重构建议
```

**场景 C：调试代码**
```
1. 选中有问题的代码
2. 按 Cmd+L，描述问题："这段代码在处理空值时出错"
3. AI 会分析并提供修复方案
```

### 3. 文档编写阶段

```
1. 按 Cmd+L 打开对话
2. 输入："根据 src/decision_engine.py 生成 API 文档"
3. AI 会生成 Markdown 格式的文档
```

## 最佳实践

### 1. 利用上下文
- 在 Cursor 中打开多个相关文件
- AI 可以同时理解整个项目的上下文
- 在对话中引用具体文件：`请查看 src/models.py 中的 User 类`

### 2. 迭代式开发
- 先生成基础框架，再逐步完善
- 每次只让 AI 做一件事，避免一次性要求太多
- 持续测试和反馈

### 3. 代码审查
- 让 AI 审查生成的代码："这段代码有什么潜在问题？"
- 要求优化："如何提高这段代码的性能？"

### 4. 学习模式
- 遇到不理解的概念，直接问 AI："解释一下策略模式"
- 让 AI 提供代码示例和最佳实践

## 快捷键速查

| 快捷键 | 功能 |
|--------|------|
| `Cmd+L` | 打开 AI 对话面板 |
| `Cmd+K` | 对选中代码进行编辑 |
| `Cmd+Shift+L` | 打开命令面板 |
| `Cmd+I` | 内联编辑（在代码中直接编辑）|
| `Tab` | 接受 AI 建议 |
| `Esc` | 取消当前操作 |

## 项目特定配置

### .cursorrules 文件

项目根目录已创建 `.cursorrules` 文件，用于指导 AI：
- 项目特定的代码风格
- 技术栈偏好
- 业务规则约束

### 使用示例

在对话中可以这样提问：
```
基于 .cursorrules 中的规则，生成一个决策分析模块
```

AI 会自动遵循项目配置规则。

## 命令行工具补充

虽然 Cursor 内置功能很强大，但在某些场景下，命令行工具也有其价值：

```bash
# 批量处理多个文件
npx @anthropic-ai/claude-code batch-process src/**/*.py

# 生成测试用例
npx @anthropic-ai/claude-code generate-tests src/decision_engine.py

# 代码审查报告
npx @anthropic-ai/claude-code review src/ --output review.md
```

## 故障排除

### 问题 1：AI 建议不准确
- 提供更多上下文信息
- 在对话中明确说明需求
- 分步骤进行，不要一次要求太多

### 问题 2：命令不可用
- 确保使用的是 `npx @anthropic-ai/claude-code`
- 检查 npm 全局安装路径是否在 PATH 中

### 问题 3：Cursor AI 功能异常
- 检查网络连接
- 查看 Cursor 设置中的 AI 配置
- 重启 Cursor 编辑器

## 下一步

1. 打开 Cursor，加载 CEOAgent 项目
2. 阅读 `REQUIREMENTS.md` 了解需求
3. 开始使用 `Cmd+L` 和 `Cmd+K` 进行开发
4. 根据需要查阅本指南

## 相关资源

- [Cursor 官方文档](https://cursor.sh/docs)
- [Claude Code 文档](https://claude.ai/code)
- 项目需求：`REQUIREMENTS.md`
- 更新指南：`UPDATE_CLAUDE_CODE.md`
