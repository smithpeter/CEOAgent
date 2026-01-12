# CEOAgent 快速开始指南

## 5 分钟快速开始

### 第一步：环境准备

```bash
# 确保 Python 3.11+ 已安装
python --version

# 克隆或进入项目目录
cd /Users/zouyongming/dev/CEOAgent

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # macOS/Linux
# 或
venv\Scripts\activate  # Windows

# 安装基础依赖（待创建 requirements.txt 后）
pip install fastapi uvicorn anthropic pydantic
```

### 第二步：在 Cursor 中打开项目

1. 打开 Cursor 编辑器
2. 打开 `/Users/zouyongming/dev/CEOAgent` 目录
3. 确认 `.cursorrules` 文件已加载

### 第三步：使用 Claude Code 生成项目结构

在 Cursor 中：

1. **按 `Cmd+L` 打开 AI 对话**

2. **输入以下提示**：
```
请按照 DEVELOPMENT_PLAN.md 中的第一阶段任务，帮我生成项目初始结构：
1. 创建标准的 Python 项目结构
2. 设置 FastAPI 基础框架
3. 创建 Skill 系统的基础类（BaseSkill, SkillRegistry, SkillExecutor）
4. 添加基础的配置文件
5. 创建 requirements.txt 和 Dockerfile
```

3. **AI 会生成代码**，你只需要：
   - 审查生成的代码
   - 接受建议的修改
   - 运行测试验证

### 第四步：开发第一个 Skill

在 Cursor 中创建 `src/ceo_agent/skills/data_collection_skill.py`：

1. **输入注释**：
```python
# TODO: 实现 DataCollectionSkill
# 功能：从多个数据源收集数据
```

2. **选中注释，按 `Cmd+K`**

3. **输入提示**：
```
基于 Skill 基类实现 DataCollectionSkill：
- 继承 BaseSkill
- 定义参数：data_source, query_params, date_range
- 实现 execute 方法
- 添加错误处理
```

4. **AI 生成代码后，按 `Cmd+L` 询问**：
```
为这个 Skill 生成单元测试
```

### 第五步：运行和测试

```bash
# 运行 FastAPI 开发服务器
uvicorn src.ceo_agent.main:app --reload

# 运行测试
pytest tests/

# 查看 API 文档
# 浏览器打开 http://localhost:8000/docs
```

## 开发工作流速查

### 日常开发流程

```
1. 理解需求
   └─> Cmd+L: "解释这个需求，设计实现方案"

2. 生成代码框架
   └─> Cmd+K: 选中 TODO，生成代码

3. 完善功能
   └─> Cmd+L: "如何优化这段代码？"

4. 生成测试
   └─> Cmd+L: "为这段代码生成测试"

5. 生成文档
   └─> Cmd+L: "生成 API 文档"
```

### 常用 Cursor 快捷键

| 快捷键 | 功能 | 使用场景 |
|--------|------|----------|
| `Cmd+L` | AI 对话 | 需求分析、代码审查、问题咨询 |
| `Cmd+K` | 代码编辑 | 生成代码、重构代码 |
| `Cmd+I` | 内联编辑 | 在代码中直接编辑 |
| `Cmd+Shift+L` | 命令面板 | 快速命令执行 |
| `Tab` | 接受建议 | 接受 AI 生成的代码 |
| `Esc` | 取消 | 取消当前操作 |

## Skill 开发模板

### 创建新 Skill 的标准流程

1. **创建文件**：`src/ceo_agent/skills/your_skill.py`

2. **在 Cursor 中输入模板**：
```python
from typing import Any, Dict
from pydantic import BaseModel, Field
from ceo_agent.core.skill import BaseSkill

class YourSkillParams(BaseModel):
    """Your Skill 参数定义"""
    param1: str = Field(..., description="参数1说明")
    param2: int = Field(default=10, description="参数2说明")

class YourSkill(BaseSkill):
    """Your Skill 描述"""
    
    name: str = "your_skill"
    description: str = "Skill 功能描述"
    
    async def execute(self, params: YourSkillParams) -> Dict[str, Any]:
        """执行 Skill"""
        # TODO: 实现具体逻辑
        pass
```

3. **选中 TODO，按 `Cmd+K`**：
```
实现 execute 方法的具体逻辑，包含错误处理和日志
```

4. **注册 Skill**：
```python
# 在 src/ceo_agent/core/registry.py 中注册
registry.register_skill(YourSkill())
```

## 使用 Claude Code 的技巧

### 技巧 1：利用上下文

在 Cursor 中打开多个相关文件，AI 能理解整个项目的上下文：

```
打开的文件：
- src/ceo_agent/core/skill.py
- src/ceo_agent/skills/base.py

然后问："基于这两个文件的代码风格，生成新的 Skill"
```

### 技巧 2：迭代式开发

不要一次要求太多，分步骤进行：

```
第一步：生成基础框架
第二步：添加核心功能
第三步：添加错误处理
第四步：优化性能
```

### 技巧 3：学习新技术

遇到不熟悉的技术，直接问 AI：

```
Cmd+L: "解释 ReAct 模式，并给出 Python 实现示例"
Cmd+L: "如何使用 Anthropic SDK 实现 Tool Calling？"
Cmd+L: "如何在 FastAPI 中实现 WebSocket？"
```

## 常见问题

### Q: 如何查看开发进度？

A: 查看 `DEVELOPMENT_PLAN.md` 中的里程碑检查点。

### Q: 如何添加新的 Skill？

A: 参考 `DEVELOPMENT_PLAN.md` 中的 Skill 开发清单，按照模板创建。

### Q: 如何调试代码？

A: 使用 Cursor 的调试功能，或按 `Cmd+L` 描述问题，让 AI 帮你分析。

### Q: 如何部署项目？

A: 查看 `DEVELOPMENT_PLAN.md` 第七阶段的部署指南。

## 下一步

1. ✅ 完成环境设置
2. 📖 阅读 `DEVELOPMENT_PLAN.md` 了解详细计划
3. 🚀 开始第一阶段开发
4. 💬 使用 Cursor + Claude Code 进行开发
5. 🧪 持续测试和迭代

## 获取帮助

- 📚 查看 `INTEGRATION_GUIDE.md` 了解 Cursor 使用技巧
- 📋 查看 `REQUIREMENTS.md` 了解业务需求
- 🚀 查看 `DEVELOPMENT_PLAN.md` 了解技术实现

---

**Happy Coding with Claude Code & Cursor! 🎉**
