# CEOAgent 后端开发任务拆分

> **关联文档**：BACKEND_SPEC.md (详细规范)
> **开发周期**：5 天

---

## 任务总览

```
┌─────────────────────────────────────────────────────────────────┐
│  Day 1          Day 2          Day 3          Day 4          Day 5   │
│    │              │              │              │              │     │
│    ▼              ▼              ▼              ▼              ▼     │
│ ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐  │
│ │项目结构│ ──▶ │核心组件│ ──▶ │业务逻辑│ ──▶ │ API层 │ ──▶ │测试评估│  │
│ │ 配置  │      │ 1/2  │      │ 2/2  │      │      │      │      │  │
│ └──────┘      └──────┘      └──────┘      └──────┘      └──────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Day 1: 项目结构与配置

### 任务 1.1: 创建目录结构

**目标**：建立标准的 Python 项目结构

```bash
# 执行命令
mkdir -p src/ceo_agent/{core,api,utils}
mkdir -p tests/{unit,integration,e2e}
mkdir -p prompts/v1
mkdir -p evaluation/test_cases
```

**产出文件**：
```
src/ceo_agent/
├── __init__.py
├── core/
│   └── __init__.py
├── api/
│   └── __init__.py
└── utils/
    └── __init__.py
```

**验收标准**：
- [ ] 所有 `__init__.py` 文件已创建
- [ ] 目录结构与 BACKEND_SPEC.md 一致

---

### 任务 1.2: 配置 pyproject.toml

**目标**：完善项目配置

**修改文件**：`pyproject.toml`

**需要确认的配置项**：
- [x] 项目元数据
- [x] 依赖版本
- [x] pytest 配置
- [x] ruff 配置
- [x] mypy 配置

**验收标准**：
- [ ] `pip install -e ".[dev]"` 成功
- [ ] `pytest` 可运行
- [ ] `ruff check .` 可运行
- [ ] `mypy src/ceo_agent` 可运行

---

### 任务 1.3: 实现 config.py

**目标**：使用 pydantic-settings 管理配置

**创建文件**：`src/ceo_agent/config.py`

```python
# 核心实现要点
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Anthropic 配置
    anthropic_api_key: str
    claude_model: str = "claude-3-5-sonnet-20241022"
    claude_max_tokens: int = 4096
    claude_timeout: int = 60

    # 应用配置
    app_name: str = "CEOAgent"
    app_version: str = "0.1.0"
    debug: bool = False

    # Prompt 配置
    prompt_version: str = "v1"
    prompt_dir: str = "prompts"

    class Config:
        env_file = ".env"

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**验收标准**：
- [ ] 从 `.env` 正确加载配置
- [ ] 缺少必需配置时抛出明确错误
- [ ] 单元测试通过

**测试用例**：
```python
# tests/unit/test_config.py
def test_settings_from_env(monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")
    settings = Settings()
    assert settings.anthropic_api_key == "test-key"

def test_settings_default_values(monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")
    settings = Settings()
    assert settings.claude_model == "claude-3-5-sonnet-20241022"

def test_settings_missing_required():
    with pytest.raises(ValidationError):
        Settings()  # 缺少 ANTHROPIC_API_KEY
```

---

### 任务 1.4: 实现 exceptions.py

**目标**：定义项目自定义异常

**创建文件**：`src/ceo_agent/exceptions.py`

```python
# 异常层级
CEOAgentError (基类)
├── ClaudeAPIError       # Claude API 调用失败
│   └── ClaudeTimeoutError  # 超时
├── ParseError           # 响应解析失败
├── ValidationError      # 输入验证失败
└── SessionNotFoundError # 会话不存在
```

**验收标准**：
- [ ] 所有异常类包含 `code` 和 `message` 属性
- [ ] 可被 JSON 序列化
- [ ] 单元测试通过

---

### 任务 1.5: 创建 Prompt 模板

**目标**：创建初始 Prompt 模板文件

**创建文件**：
- `prompts/v1/system.txt`
- `prompts/v1/investment.txt`
- `prompts/v1/risk.txt`
- `prompts/v1/strategy.txt`

**验收标准**：
- [ ] 模板格式正确，包含 `${query}` 和 `${context}` 占位符
- [ ] 系统 Prompt 包含输出格式要求

---

### Day 1 总验收

```bash
# 验收脚本
cd /Users/zouyongming/dev/CEOAgent

# 1. 目录结构检查
test -d src/ceo_agent/core && echo "✅ core 目录" || echo "❌ core 目录"
test -d src/ceo_agent/api && echo "✅ api 目录" || echo "❌ api 目录"

# 2. 安装检查
pip install -e ".[dev]" && echo "✅ 安装成功" || echo "❌ 安装失败"

# 3. 配置加载检查
python -c "from ceo_agent.config import get_settings; print('✅ 配置模块')"

# 4. 异常模块检查
python -c "from ceo_agent.exceptions import CEOAgentError; print('✅ 异常模块')"

# 5. Prompt 模板检查
test -f prompts/v1/system.txt && echo "✅ Prompt 模板" || echo "❌ Prompt 模板"
```

---

## Day 2: 核心组件 (上)

### 任务 2.1: 实现 ClaudeClient

**目标**：封装 Anthropic SDK，提供异步调用接口

**创建文件**：`src/ceo_agent/core/claude_client.py`

**核心方法**：
```python
class ClaudeClient:
    async def complete(
        self,
        system_prompt: str,
        messages: list[dict[str, str]],
        temperature: float = 0.7
    ) -> ClaudeResponse:
        """同步完成消息"""

    async def close(self) -> None:
        """关闭连接"""
```

**实现要点**：
1. 使用 `AsyncAnthropic` 异步客户端
2. 正确处理超时（转换为 `ClaudeTimeoutError`）
3. 正确处理 API 错误（转换为 `ClaudeAPIError`）
4. 提取 token 使用量

**验收标准**：
- [ ] 可以调用 Claude API 获取响应
- [ ] 超时时抛出正确异常
- [ ] API 错误时抛出正确异常
- [ ] 单元测试 100% 通过（使用 Mock）

**测试用例数量**：至少 5 个
- `test_complete_success`
- `test_complete_api_error`
- `test_complete_timeout`
- `test_complete_with_temperature`
- `test_close`

---

### 任务 2.2: 实现 PromptManager

**目标**：管理 Prompt 模板的加载和渲染

**创建文件**：`src/ceo_agent/core/prompt_manager.py`

**核心方法**：
```python
class PromptManager:
    def get_system_prompt(self) -> str:
        """获取系统 Prompt"""

    def get_analysis_prompt(
        self,
        decision_type: str,
        query: str,
        context: dict | None = None
    ) -> str:
        """获取分析 Prompt（已渲染）"""

    def reload_templates(self) -> None:
        """重新加载模板"""
```

**实现要点**：
1. 使用 `string.Template` 渲染变量
2. 实现模板缓存
3. 支持按决策类型选择模板

**验收标准**：
- [ ] 正确加载模板文件
- [ ] 正确替换模板变量
- [ ] 缓存生效
- [ ] 单元测试 100% 通过

**测试用例数量**：至少 5 个

---

### Day 2 总验收

```bash
# 单元测试
pytest tests/unit/test_claude_client.py -v
pytest tests/unit/test_prompt_manager.py -v

# 检查点
python -c "from ceo_agent.core.claude_client import ClaudeClient; print('✅ ClaudeClient')"
python -c "from ceo_agent.core.prompt_manager import PromptManager; print('✅ PromptManager')"
```

---

## Day 3: 核心组件 (下)

### 任务 3.1: 实现 ResponseParser

**目标**：解析 Claude 响应为结构化数据

**创建文件**：`src/ceo_agent/core/response_parser.py`

**核心方法**：
```python
class ResponseParser:
    def parse(self, raw_response: str) -> AnalysisResult:
        """解析原始响应"""

    def _extract_json(self, text: str) -> dict:
        """提取 JSON 块"""

    def _extract_risk_score(self, text: str) -> int:
        """提取风险评分（容错）"""

    def _validate_result(self, result: dict) -> bool:
        """验证结果完整性"""
```

**实现要点**：
1. 支持多种 JSON 格式（Markdown 包裹、纯 JSON）
2. 容错解析（部分字段缺失时的处理）
3. 风险评分多格式支持

**验收标准**：
- [ ] 正确解析标准格式响应
- [ ] 正确解析 Markdown 包裹的 JSON
- [ ] 缺少字段时抛出明确错误
- [ ] 单元测试 100% 通过

**测试用例数量**：至少 6 个

---

### 任务 3.2: 实现 MemoryStore

**目标**：管理会话对话历史

**创建文件**：`src/ceo_agent/core/memory.py`

**核心方法**：
```python
class MemoryStore:
    def create_session(self) -> str:
        """创建会话"""

    def get_session(self, session_id: str) -> AnalysisContext | None:
        """获取会话"""

    def add_message(self, session_id: str, role: str, content: str) -> None:
        """添加消息"""

    def delete_session(self, session_id: str) -> None:
        """删除会话"""
```

**实现要点**：
1. 使用 `OrderedDict` 实现 LRU 淘汰
2. 实现会话过期检查
3. 限制最大会话数

**验收标准**：
- [ ] 会话 CRUD 正常
- [ ] 超过最大数量时自动淘汰
- [ ] 过期会话自动清理
- [ ] 单元测试 100% 通过

**测试用例数量**：至少 5 个

---

### 任务 3.3: 实现 AgentCore

**目标**：核心业务编排器

**创建文件**：`src/ceo_agent/core/agent.py`

**核心方法**：
```python
class AgentCore:
    async def analyze(
        self,
        query: str,
        decision_type: str = "investment",
        context: dict | None = None,
        session_id: str | None = None
    ) -> tuple[AnalysisResult, AnalysisMetadata]:
        """执行决策分析"""
```

**实现要点**：
1. 组合调用各组件
2. 管理会话上下文
3. 记录执行时间和 token 消耗
4. 正确传播异常

**验收标准**：
- [ ] 完整分析流程可执行
- [ ] 正确生成元数据
- [ ] 会话消息正确存储
- [ ] 单元测试 100% 通过

**测试用例数量**：至少 5 个

---

### Day 3 总验收

```bash
# 所有核心模块测试
pytest tests/unit/ -v

# 检查点
python -c "from ceo_agent.core.agent import AgentCore; print('✅ AgentCore')"
python -c "from ceo_agent.core.response_parser import ResponseParser; print('✅ ResponseParser')"
python -c "from ceo_agent.core.memory import MemoryStore; print('✅ MemoryStore')"
```

---

## Day 4: API 层

### 任务 4.1: 定义 Pydantic Schemas

**目标**：定义请求/响应数据模型

**创建文件**：`src/ceo_agent/api/schemas.py`

**模型列表**：
```python
# 请求模型
- AnalysisRequest
- FeedbackRequest

# 响应模型
- RiskFactor
- Recommendation
- FinalRecommendation
- AnalysisResult
- AnalysisMetadata
- AnalysisResponse
- ErrorDetail
- ErrorResponse
- HealthResponse
```

**验收标准**：
- [ ] 所有字段有类型提示
- [ ] 所有字段有 Field 描述
- [ ] 包含示例值
- [ ] 验证规则正确（min_length, ge, le 等）

---

### 任务 4.2: 实现依赖注入

**目标**：配置 FastAPI 依赖

**创建文件**：`src/ceo_agent/api/dependencies.py`

```python
def get_settings() -> Settings:
    """获取配置"""

def get_agent(request: Request) -> AgentCore:
    """获取 AgentCore 实例"""
```

**验收标准**：
- [ ] 依赖注入正常工作
- [ ] 可在测试中 override

---

### 任务 4.3: 实现 API 路由

**目标**：实现所有 API 端点

**创建文件**：`src/ceo_agent/api/routes.py`

**端点列表**：
| 方法 | 路径 | 功能 |
|------|------|------|
| POST | /api/v1/analyze | 决策分析 |
| GET | /api/v1/health | 健康检查 |
| POST | /api/v1/decisions/{id}/feedback | 提交反馈 |

**验收标准**：
- [ ] 所有端点返回正确格式
- [ ] 错误处理正确
- [ ] OpenAPI 文档完整

---

### 任务 4.4: 实现 main.py

**目标**：FastAPI 应用入口

**创建文件**：`src/ceo_agent/main.py`

**实现要点**：
1. 使用 `lifespan` 管理生命周期
2. 配置 CORS
3. 注册路由
4. 注册异常处理器

**验收标准**：
- [ ] `uvicorn src.ceo_agent.main:app` 启动成功
- [ ] `/docs` 可访问
- [ ] `/api/v1/health` 返回正确

---

### 任务 4.5: 编写集成测试

**目标**：测试 API 端点

**创建文件**：`tests/integration/test_api.py`

**测试用例**：
- `test_analyze_success`
- `test_analyze_validation_error`
- `test_analyze_missing_query`
- `test_health_check`
- `test_submit_feedback`

**验收标准**：
- [ ] 所有集成测试通过
- [ ] 覆盖正常和异常场景

---

### Day 4 总验收

```bash
# 启动服务
uvicorn src.ceo_agent.main:app --reload &
sleep 3

# 健康检查
curl -s http://localhost:8000/api/v1/health | jq

# 分析接口测试
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "我们应该投资这家AI创业公司吗？估值5000万，年收入500万。"}' | jq

# 关闭服务
pkill -f uvicorn

# 集成测试
pytest tests/integration/ -v
```

---

## Day 5: 测试与评估

### 任务 5.1: 补充单元测试

**目标**：确保测试覆盖率 > 80%

**检查命令**：
```bash
pytest --cov=src/ceo_agent --cov-report=term-missing
```

**需要补充的模块**：
- [ ] config.py 边界情况
- [ ] 各组件错误处理路径

---

### 任务 5.2: 创建评估用例

**目标**：准备评估数据

**创建文件**：
- `evaluation/test_cases/investment_cases.json`
- `evaluation/test_cases/risk_cases.json`
- `evaluation/test_cases/strategy_cases.json`

**每个文件包含**：
- 至少 3 个测试用例
- 每个用例有明确的期望值

---

### 任务 5.3: 实现评估脚本

**目标**：自动化评估

**创建文件**：`evaluation/run_eval.py`

**功能**：
1. 加载所有测试用例
2. 调用 API 获取结果
3. 计算得分
4. 输出报告

**验收标准**：
- [ ] 脚本可独立运行
- [ ] 输出清晰的评估报告
- [ ] 平均得分 > 60%

---

### 任务 5.4: E2E 测试（可选）

**目标**：真实 API 调用测试

**创建文件**：`tests/e2e/test_scenarios.py`

**前提**：需要设置 `ANTHROPIC_API_KEY`

**运行**：
```bash
ANTHROPIC_API_KEY=xxx pytest tests/e2e/ -v --run-slow
```

---

### 任务 5.5: 发布前检查

**执行完整检查脚本**：

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "CEOAgent Phase 1 MVP 发布前检查"
echo "=========================================="

echo ""
echo "1. 代码质量检查"
echo "----------------"

echo "  [1.1] 类型检查..."
mypy src/ceo_agent --strict
echo "  ✅ mypy 通过"

echo "  [1.2] 代码风格检查..."
ruff check .
echo "  ✅ ruff 通过"

echo "  [1.3] 代码格式检查..."
ruff format --check .
echo "  ✅ 格式正确"

echo ""
echo "2. 测试检查"
echo "----------------"

echo "  [2.1] 单元测试..."
pytest tests/unit/ -q
echo "  ✅ 单元测试通过"

echo "  [2.2] 集成测试..."
pytest tests/integration/ -q
echo "  ✅ 集成测试通过"

echo "  [2.3] 覆盖率检查..."
pytest --cov=src/ceo_agent --cov-fail-under=80 -q
echo "  ✅ 覆盖率 > 80%"

echo ""
echo "3. 服务检查"
echo "----------------"

echo "  [3.1] 启动服务..."
uvicorn src.ceo_agent.main:app &
PID=$!
sleep 3

echo "  [3.2] 健康检查..."
curl -sf http://localhost:8000/api/v1/health > /dev/null
echo "  ✅ 健康检查通过"

echo "  [3.3] API 文档检查..."
curl -sf http://localhost:8000/docs > /dev/null
echo "  ✅ API 文档可访问"

echo "  [3.4] 关闭服务..."
kill $PID 2>/dev/null || true
echo "  ✅ 服务已关闭"

echo ""
echo "=========================================="
echo "🎉 所有检查通过！可以发布。"
echo "=========================================="
```

---

### Day 5 总验收

| 检查项 | 命令 | 期望结果 |
|--------|------|----------|
| 类型检查 | `mypy src/ceo_agent --strict` | 无错误 |
| 代码风格 | `ruff check .` | 无警告 |
| 单元测试 | `pytest tests/unit/` | 全部通过 |
| 集成测试 | `pytest tests/integration/` | 全部通过 |
| 覆盖率 | `pytest --cov --cov-fail-under=80` | > 80% |
| 服务启动 | `uvicorn ...` | 无错误 |
| 健康检查 | `curl .../health` | 200 OK |
| 评估得分 | `python evaluation/run_eval.py` | 平均 > 60% |

---

## 风险与应对

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|----------|
| Claude API 响应格式变化 | 中 | 高 | ResponseParser 多格式兼容 |
| API 调用超时 | 中 | 中 | 60s 超时 + 友好错误提示 |
| 测试覆盖率不足 | 低 | 中 | 优先覆盖核心路径 |
| Prompt 效果不佳 | 中 | 高 | 迭代优化 Prompt 模板 |

---

## 每日站会检查点

### Day 1 检查点
- [ ] 目录结构已创建
- [ ] 配置模块可用
- [ ] 异常模块可用
- [ ] Prompt 模板就位

### Day 2 检查点
- [ ] ClaudeClient 测试通过
- [ ] PromptManager 测试通过
- [ ] 可以调用 Claude API

### Day 3 检查点
- [ ] ResponseParser 测试通过
- [ ] MemoryStore 测试通过
- [ ] AgentCore 测试通过

### Day 4 检查点
- [ ] API 可以启动
- [ ] /analyze 端点工作正常
- [ ] 集成测试通过

### Day 5 检查点
- [ ] 覆盖率 > 80%
- [ ] 评估得分 > 60%
- [ ] 发布检查全部通过

---

## 附录：文件清单

### 需要创建的文件

```
src/ceo_agent/
├── __init__.py                  # Day 1
├── main.py                      # Day 4
├── config.py                    # Day 1
├── exceptions.py                # Day 1
├── core/
│   ├── __init__.py              # Day 1
│   ├── agent.py                 # Day 3
│   ├── claude_client.py         # Day 2
│   ├── prompt_manager.py        # Day 2
│   ├── response_parser.py       # Day 3
│   └── memory.py                # Day 3
├── api/
│   ├── __init__.py              # Day 1
│   ├── routes.py                # Day 4
│   ├── schemas.py               # Day 4
│   └── dependencies.py          # Day 4
└── utils/
    ├── __init__.py              # Day 1
    └── logging.py               # Day 1 (可选)

prompts/v1/
├── system.txt                   # Day 1
├── investment.txt               # Day 1
├── risk.txt                     # Day 1
└── strategy.txt                 # Day 1

tests/
├── conftest.py                  # Day 2
├── unit/
│   ├── test_config.py           # Day 1
│   ├── test_claude_client.py    # Day 2
│   ├── test_prompt_manager.py   # Day 2
│   ├── test_response_parser.py  # Day 3
│   ├── test_memory.py           # Day 3
│   └── test_agent.py            # Day 3
├── integration/
│   └── test_api.py              # Day 4
└── e2e/
    └── test_scenarios.py        # Day 5 (可选)

evaluation/
├── test_cases/
│   ├── investment_cases.json    # Day 5
│   ├── risk_cases.json          # Day 5
│   └── strategy_cases.json      # Day 5
└── run_eval.py                  # Day 5
```

### 文件数量统计

| 类型 | 数量 |
|------|------|
| 源代码文件 | 14 |
| Prompt 模板 | 4 |
| 测试文件 | 9 |
| 评估文件 | 4 |
| **总计** | **31** |
