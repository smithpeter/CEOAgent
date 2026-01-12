# 后端开发指南

> 后端开发经理编写，供开发团队参考

---

## 一、开发环境规范

### 1.1 必需工具

| 工具 | 版本 | 用途 |
|------|------|------|
| Python | 3.11+ | 运行时 |
| uv / pip | 最新 | 包管理 |
| Git | 2.40+ | 版本控制 |
| Docker | 24+ | 容器化（Phase 2+） |
| VS Code / Cursor | 最新 | IDE |

### 1.2 推荐 VS Code 扩展

```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff",
    "tamasfe.even-better-toml",
    "redhat.vscode-yaml"
  ]
}
```

### 1.3 本地开发设置

```bash
# 1. 克隆项目
git clone <repo>
cd ceoagent

# 2. 创建虚拟环境
python3.11 -m venv venv
source venv/bin/activate

# 3. 安装依赖（包含开发依赖）
pip install -e ".[dev]"

# 4. 安装 pre-commit hooks
pre-commit install

# 5. 复制环境配置
cp .env.example .env
# 编辑 .env，填入 ANTHROPIC_API_KEY

# 6. 验证安装
pytest --version
ruff --version
```

---

## 二、代码规范

### 2.1 项目结构规范

```
src/ceo_agent/
├── __init__.py          # 版本号、公共导出
├── main.py              # FastAPI 应用入口
├── config.py            # 配置管理（pydantic-settings）
├── exceptions.py        # 自定义异常
├── core/                # 核心业务逻辑
│   ├── __init__.py
│   ├── agent.py         # AgentCore 主类
│   ├── claude_client.py # Claude API 封装
│   ├── prompt_manager.py# Prompt 模板管理
│   ├── response_parser.py # 响应解析
│   └── memory.py        # 记忆管理
├── api/                 # API 层
│   ├── __init__.py
│   ├── routes.py        # 路由定义
│   ├── schemas.py       # 请求/响应模型
│   ├── dependencies.py  # 依赖注入
│   └── middleware.py    # 中间件
├── services/            # 业务服务（Phase 2+）
└── utils/               # 工具函数
    ├── __init__.py
    └── logging.py       # 日志配置
```

### 2.2 命名规范

```python
# 文件名：小写 + 下划线
claude_client.py
prompt_manager.py

# 类名：PascalCase
class AgentCore:
class ClaudeClient:
class AnalysisRequest:

# 函数/方法：小写 + 下划线
async def analyze_decision():
def parse_response():

# 常量：大写 + 下划线
MAX_TOKENS = 4096
DEFAULT_TIMEOUT = 60

# 私有方法/属性：单下划线前缀
def _validate_input():
self._client = None
```

### 2.3 类型提示规范

```python
from typing import Any
from collections.abc import Sequence

# ✅ 正确：使用内置泛型（Python 3.9+）
def process(items: list[str]) -> dict[str, Any]:
    pass

# ✅ 正确：可选参数
def analyze(query: str, context: dict[str, Any] | None = None) -> AnalysisResult:
    pass

# ✅ 正确：使用 Sequence 而非 list（只读场景）
def process_items(items: Sequence[str]) -> None:
    pass

# ❌ 错误：不要使用 typing.List, typing.Dict（已废弃）
from typing import List, Dict  # 不要这样
```

### 2.4 文档字符串规范（Google Style）

```python
async def analyze_decision(
    query: str,
    context: dict[str, Any] | None = None,
    options: list[str] | None = None,
) -> AnalysisResult:
    """分析决策并生成建议。

    基于用户查询和上下文，调用 Claude API 进行决策分析，
    返回结构化的分析结果。

    Args:
        query: 用户的决策问题，如"是否应该扩大投资？"
        context: 可选的上下文信息，包含财务数据、市场信息等
        options: 可选的决策选项列表

    Returns:
        包含分析结果的 AnalysisResult 对象，包括：
        - situation_analysis: 态势分析
        - risk_score: 风险评分 (1-10)
        - recommendations: 建议列表

    Raises:
        ClaudeAPIError: Claude API 调用失败
        ValidationError: 输入参数验证失败
        TimeoutError: API 调用超时

    Example:
        >>> result = await analyze_decision(
        ...     query="是否应该进入新市场？",
        ...     context={"budget": 1000000}
        ... )
        >>> print(result.risk_score)
        7
    """
    pass
```

---

## 三、Claude API 集成规范

### 3.1 客户端封装

```python
# src/ceo_agent/core/claude_client.py

import asyncio
from typing import Any
import httpx
from anthropic import AsyncAnthropic, APIError, RateLimitError
from pydantic import BaseModel

from ceo_agent.config import settings
from ceo_agent.exceptions import ClaudeAPIError, ClaudeTimeoutError, ClaudeRateLimitError


class ClaudeMessage(BaseModel):
    """Claude 消息"""
    role: str  # "user" | "assistant"
    content: str


class ClaudeResponse(BaseModel):
    """Claude 响应"""
    content: str
    model: str
    input_tokens: int
    output_tokens: int
    stop_reason: str


class ClaudeClient:
    """Claude API 客户端封装

    提供以下能力：
    - 异步调用
    - 自动重试（指数退避）
    - 超时处理
    - Token 统计
    - 错误分类
    """

    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
        timeout: float = 60.0,
        max_retries: int = 3,
    ):
        self._api_key = api_key or settings.anthropic_api_key
        self._model = model or settings.claude_model
        self._timeout = timeout
        self._max_retries = max_retries
        self._client: AsyncAnthropic | None = None

    async def _get_client(self) -> AsyncAnthropic:
        """延迟初始化客户端"""
        if self._client is None:
            self._client = AsyncAnthropic(
                api_key=self._api_key,
                timeout=httpx.Timeout(self._timeout),
            )
        return self._client

    async def send_message(
        self,
        messages: list[ClaudeMessage],
        system: str | None = None,
        max_tokens: int = 4096,
        temperature: float = 0.7,
    ) -> ClaudeResponse:
        """发送消息到 Claude

        Args:
            messages: 消息列表
            system: 系统提示
            max_tokens: 最大输出 token 数
            temperature: 温度参数

        Returns:
            Claude 响应

        Raises:
            ClaudeAPIError: API 调用失败
            ClaudeTimeoutError: 调用超时
            ClaudeRateLimitError: 触发限流
        """
        client = await self._get_client()

        for attempt in range(self._max_retries):
            try:
                response = await client.messages.create(
                    model=self._model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system or "",
                    messages=[{"role": m.role, "content": m.content} for m in messages],
                )

                return ClaudeResponse(
                    content=response.content[0].text,
                    model=response.model,
                    input_tokens=response.usage.input_tokens,
                    output_tokens=response.usage.output_tokens,
                    stop_reason=response.stop_reason,
                )

            except RateLimitError as e:
                if attempt < self._max_retries - 1:
                    wait_time = 2 ** attempt  # 1, 2, 4 秒
                    await asyncio.sleep(wait_time)
                    continue
                raise ClaudeRateLimitError(f"Rate limit exceeded: {e}") from e

            except httpx.TimeoutException as e:
                raise ClaudeTimeoutError(f"Request timeout after {self._timeout}s") from e

            except APIError as e:
                raise ClaudeAPIError(f"API error: {e.message}") from e

            except Exception as e:
                raise ClaudeAPIError(f"Unexpected error: {e}") from e

    async def close(self) -> None:
        """关闭客户端"""
        if self._client:
            await self._client.close()
            self._client = None
```

### 3.2 常见问题和解决方案

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 超时 | 响应太长/网络慢 | 设置合理超时（60s），使用流式响应 |
| 限流 | 请求太频繁 | 指数退避重试，设置请求间隔 |
| 输出截断 | max_tokens 不够 | 增加 max_tokens，或分段处理 |
| 格式不稳定 | Prompt 不够明确 | 强化格式要求，添加示例 |
| 中文乱码 | 编码问题 | 确保 UTF-8 编码 |

### 3.3 流式响应（可选）

```python
async def stream_message(
    self,
    messages: list[ClaudeMessage],
    system: str | None = None,
) -> AsyncIterator[str]:
    """流式发送消息

    Yields:
        响应文本片段
    """
    client = await self._get_client()

    async with client.messages.stream(
        model=self._model,
        max_tokens=4096,
        system=system or "",
        messages=[{"role": m.role, "content": m.content} for m in messages],
    ) as stream:
        async for text in stream.text_stream:
            yield text
```

---

## 四、错误处理规范

### 4.1 异常层次结构

```python
# src/ceo_agent/exceptions.py

class CEOAgentError(Exception):
    """CEOAgent 基础异常"""

    def __init__(self, message: str, code: str | None = None):
        self.message = message
        self.code = code or "INTERNAL_ERROR"
        super().__init__(self.message)


# Claude API 相关
class ClaudeAPIError(CEOAgentError):
    """Claude API 错误"""

    def __init__(self, message: str):
        super().__init__(message, "CLAUDE_API_ERROR")


class ClaudeTimeoutError(ClaudeAPIError):
    """Claude API 超时"""

    def __init__(self, message: str):
        super().__init__(message)
        self.code = "CLAUDE_TIMEOUT"


class ClaudeRateLimitError(ClaudeAPIError):
    """Claude API 限流"""

    def __init__(self, message: str):
        super().__init__(message)
        self.code = "CLAUDE_RATE_LIMIT"


# 业务相关
class ValidationError(CEOAgentError):
    """验证错误"""

    def __init__(self, message: str, field: str | None = None):
        super().__init__(message, "VALIDATION_ERROR")
        self.field = field


class AnalysisError(CEOAgentError):
    """分析错误"""

    def __init__(self, message: str):
        super().__init__(message, "ANALYSIS_ERROR")


class PromptError(CEOAgentError):
    """Prompt 相关错误"""

    def __init__(self, message: str):
        super().__init__(message, "PROMPT_ERROR")
```

### 4.2 API 错误响应

```python
# src/ceo_agent/api/middleware.py

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from ceo_agent.exceptions import (
    CEOAgentError,
    ClaudeTimeoutError,
    ClaudeRateLimitError,
    ValidationError,
)


class ErrorHandlerMiddleware(BaseHTTPMiddleware):
    """全局错误处理中间件"""

    async def dispatch(self, request: Request, call_next):
        try:
            return await call_next(request)

        except ValidationError as e:
            return JSONResponse(
                status_code=422,
                content={
                    "success": False,
                    "error": {
                        "code": e.code,
                        "message": e.message,
                        "field": e.field,
                    },
                },
            )

        except ClaudeTimeoutError as e:
            return JSONResponse(
                status_code=504,
                content={
                    "success": False,
                    "error": {
                        "code": e.code,
                        "message": "Analysis timeout. Please try again.",
                    },
                },
            )

        except ClaudeRateLimitError as e:
            return JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "error": {
                        "code": e.code,
                        "message": "Too many requests. Please wait and try again.",
                    },
                },
            )

        except CEOAgentError as e:
            return JSONResponse(
                status_code=500,
                content={
                    "success": False,
                    "error": {
                        "code": e.code,
                        "message": e.message,
                    },
                },
            )

        except Exception as e:
            # 记录未知错误
            logger.exception("Unexpected error")
            return JSONResponse(
                status_code=500,
                content={
                    "success": False,
                    "error": {
                        "code": "INTERNAL_ERROR",
                        "message": "An unexpected error occurred.",
                    },
                },
            )
```

---

## 五、日志规范

### 5.1 日志配置

```python
# src/ceo_agent/utils/logging.py

import logging
import sys
from typing import Any

from ceo_agent.config import settings


def setup_logging() -> None:
    """配置日志"""
    log_level = getattr(logging, settings.log_level.upper(), logging.INFO)

    # 日志格式
    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)s:%(lineno)d | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # 控制台处理器
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)

    # 根日志器
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)
    root_logger.addHandler(console_handler)

    # 降低第三方库日志级别
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("anthropic").setLevel(logging.WARNING)
    logging.getLogger("uvicorn").setLevel(logging.INFO)


def get_logger(name: str) -> logging.Logger:
    """获取日志器"""
    return logging.getLogger(name)
```

### 5.2 日志使用规范

```python
from ceo_agent.utils.logging import get_logger

logger = get_logger(__name__)


async def analyze_decision(query: str) -> AnalysisResult:
    """分析决策"""
    logger.info("Starting analysis", extra={"query_length": len(query)})

    try:
        # 调用 Claude
        logger.debug("Calling Claude API")
        response = await self._client.send_message(messages)
        logger.info(
            "Claude response received",
            extra={
                "input_tokens": response.input_tokens,
                "output_tokens": response.output_tokens,
            },
        )

        # 解析响应
        result = self._parse_response(response)
        logger.info("Analysis completed", extra={"risk_score": result.risk_score})

        return result

    except ClaudeTimeoutError:
        logger.warning("Claude API timeout", extra={"query": query[:100]})
        raise

    except Exception as e:
        logger.exception("Analysis failed")
        raise
```

### 5.3 日志级别使用指南

| 级别 | 使用场景 |
|------|---------|
| DEBUG | 调试信息，如详细的请求/响应内容 |
| INFO | 正常业务流程，如请求开始/结束 |
| WARNING | 可恢复的问题，如重试、超时 |
| ERROR | 业务错误，如验证失败 |
| CRITICAL | 系统级故障，如数据库连接失败 |

---

## 六、测试规范

### 6.1 测试目录结构

```
tests/
├── __init__.py
├── conftest.py          # pytest fixtures
├── unit/                # 单元测试
│   ├── __init__.py
│   ├── test_claude_client.py
│   ├── test_prompt_manager.py
│   ├── test_response_parser.py
│   └── test_agent.py
├── integration/         # 集成测试
│   ├── __init__.py
│   └── test_api.py
└── fixtures/            # 测试数据
    ├── prompts/
    └── responses/
```

### 6.2 Mock Claude API

```python
# tests/conftest.py

import pytest
from unittest.mock import AsyncMock, MagicMock

from ceo_agent.core.claude_client import ClaudeClient, ClaudeResponse


@pytest.fixture
def mock_claude_response() -> ClaudeResponse:
    """模拟 Claude 响应"""
    return ClaudeResponse(
        content="""
        ## 态势分析
        当前市场环境复杂...

        ## 风险评分
        7/10

        ## 建议
        1. 方案A：保守策略
        2. 方案B：激进策略

        ## 推荐
        建议采用方案A
        """,
        model="claude-3-5-sonnet-20241022",
        input_tokens=500,
        output_tokens=300,
        stop_reason="end_turn",
    )


@pytest.fixture
def mock_claude_client(mock_claude_response) -> ClaudeClient:
    """模拟 Claude 客户端"""
    client = MagicMock(spec=ClaudeClient)
    client.send_message = AsyncMock(return_value=mock_claude_response)
    return client


@pytest.fixture
def mock_claude_timeout() -> ClaudeClient:
    """模拟超时的 Claude 客户端"""
    from ceo_agent.exceptions import ClaudeTimeoutError

    client = MagicMock(spec=ClaudeClient)
    client.send_message = AsyncMock(side_effect=ClaudeTimeoutError("Timeout"))
    return client
```

### 6.3 测试示例

```python
# tests/unit/test_agent.py

import pytest
from ceo_agent.core.agent import AgentCore
from ceo_agent.exceptions import ClaudeTimeoutError


class TestAgentCore:
    """AgentCore 测试"""

    @pytest.mark.asyncio
    async def test_analyze_success(self, mock_claude_client):
        """测试正常分析流程"""
        agent = AgentCore(claude_client=mock_claude_client)

        result = await agent.analyze("是否应该扩大投资？")

        assert result is not None
        assert result.risk_score is not None
        assert 1 <= result.risk_score <= 10
        assert len(result.recommendations) >= 1

    @pytest.mark.asyncio
    async def test_analyze_timeout(self, mock_claude_timeout):
        """测试超时处理"""
        agent = AgentCore(claude_client=mock_claude_timeout)

        with pytest.raises(ClaudeTimeoutError):
            await agent.analyze("测试查询")

    @pytest.mark.asyncio
    async def test_analyze_empty_query(self, mock_claude_client):
        """测试空查询"""
        agent = AgentCore(claude_client=mock_claude_client)

        with pytest.raises(ValidationError):
            await agent.analyze("")

    @pytest.mark.asyncio
    async def test_analyze_with_context(self, mock_claude_client):
        """测试带上下文的分析"""
        agent = AgentCore(claude_client=mock_claude_client)

        result = await agent.analyze(
            query="是否应该扩大投资？",
            context={"budget": 1000000, "risk_tolerance": "medium"},
        )

        assert result is not None
        # 验证上下文被正确使用
        call_args = mock_claude_client.send_message.call_args
        assert "1000000" in str(call_args)
```

### 6.4 集成测试

```python
# tests/integration/test_api.py

import pytest
from httpx import AsyncClient
from ceo_agent.main import app


@pytest.fixture
async def client():
    """异步测试客户端"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client


class TestAnalyzeAPI:
    """分析 API 测试"""

    @pytest.mark.asyncio
    async def test_analyze_endpoint(self, client, monkeypatch):
        """测试分析端点"""
        # Mock Claude 调用
        # ...

        response = await client.post(
            "/api/v1/analyze",
            json={"query": "是否应该扩大投资？"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "result" in data["data"]

    @pytest.mark.asyncio
    async def test_analyze_validation_error(self, client):
        """测试验证错误"""
        response = await client.post(
            "/api/v1/analyze",
            json={"query": ""},  # 空查询
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_health_check(self, client):
        """测试健康检查"""
        response = await client.get("/api/v1/health")

        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
```

### 6.5 运行测试

```bash
# 运行所有测试
pytest

# 运行并显示覆盖率
pytest --cov=src/ceo_agent --cov-report=term-missing

# 只运行单元测试
pytest tests/unit/

# 运行特定测试
pytest tests/unit/test_agent.py::TestAgentCore::test_analyze_success -v

# 运行并在失败时进入调试
pytest --pdb
```

---

## 七、Git 工作流

### 7.1 分支策略

```
main          # 生产分支，始终可部署
  │
  ├── develop # 开发分支，集成测试
  │     │
  │     ├── feature/xxx  # 功能分支
  │     ├── fix/xxx      # 修复分支
  │     └── refactor/xxx # 重构分支
  │
  └── release/x.x.x  # 发布分支
```

### 7.2 提交规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型：**
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式（不影响代码运行）
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

**示例：**
```
feat(agent): add decision analysis method

Implement the analyze_decision method in AgentCore:
- Call Claude API with structured prompt
- Parse response into AnalysisResult
- Handle timeout and rate limit errors

Closes #123
```

### 7.3 代码审查清单

```markdown
## Code Review Checklist

### 功能性
- [ ] 代码实现了预期功能
- [ ] 边界情况已处理
- [ ] 错误处理完善

### 代码质量
- [ ] 符合代码规范
- [ ] 类型提示完整
- [ ] 文档字符串完整
- [ ] 无重复代码

### 测试
- [ ] 有单元测试
- [ ] 测试覆盖关键路径
- [ ] 测试通过

### 安全
- [ ] 无硬编码密钥
- [ ] 输入已验证
- [ ] 无敏感信息泄露

### 性能
- [ ] 无明显性能问题
- [ ] 异步操作正确使用
```

---

## 八、常见问题排查

### 8.1 Claude API 问题

| 症状 | 可能原因 | 排查步骤 |
|------|---------|---------|
| 401 Unauthorized | API Key 无效 | 检查 .env 中的 ANTHROPIC_API_KEY |
| 429 Too Many Requests | 请求过频 | 检查限流配置，增加重试间隔 |
| 504 Timeout | 响应太慢 | 增加 timeout，考虑流式响应 |
| 输出格式不对 | Prompt 不明确 | 检查 Prompt 模板，添加格式示例 |

### 8.2 异步编程陷阱

```python
# ❌ 错误：在同步上下文中调用异步函数
def bad_example():
    result = await async_function()  # SyntaxError

# ✅ 正确：使用 asyncio.run 或在异步上下文中调用
async def good_example():
    result = await async_function()

# 或
import asyncio
result = asyncio.run(async_function())


# ❌ 错误：忘记 await
async def bad_example():
    result = async_function()  # 返回 coroutine，不是结果
    print(result)  # <coroutine object ...>

# ✅ 正确：始终 await 异步调用
async def good_example():
    result = await async_function()
    print(result)


# ❌ 错误：在异步函数中使用阻塞调用
async def bad_example():
    time.sleep(1)  # 阻塞整个事件循环

# ✅ 正确：使用异步版本
async def good_example():
    await asyncio.sleep(1)
```

### 8.3 Pydantic 常见问题

```python
# ❌ 错误：模型字段默认值是可变对象
class BadModel(BaseModel):
    items: list = []  # 所有实例共享同一个列表

# ✅ 正确：使用 Field(default_factory=...)
class GoodModel(BaseModel):
    items: list = Field(default_factory=list)


# ❌ 错误：忘记处理可选字段
class BadRequest(BaseModel):
    query: str
    context: dict  # 如果不传会报错

# ✅ 正确：明确可选
class GoodRequest(BaseModel):
    query: str
    context: dict | None = None
```

---

## 九、性能优化指南

### 9.1 响应时间优化

| 优化点 | 预期收益 | 实现方式 |
|--------|---------|---------|
| 流式响应 | 首字节时间减少 80% | 使用 stream API |
| 连接复用 | 请求延迟减少 50ms | 复用 httpx.AsyncClient |
| Prompt 缓存 | 编译时间减少 | 预加载模板 |

### 9.2 资源使用优化

```python
# 使用上下文管理器确保资源释放
async with ClaudeClient() as client:
    result = await client.send_message(messages)

# 或在应用启动/关闭时管理
@app.on_event("startup")
async def startup():
    app.state.claude_client = ClaudeClient()

@app.on_event("shutdown")
async def shutdown():
    await app.state.claude_client.close()
```

---

## 十、检查清单

### 开发前检查

- [ ] 环境变量已配置
- [ ] 依赖已安装
- [ ] pre-commit hooks 已启用

### 提交前检查

- [ ] `ruff check .` 无错误
- [ ] `ruff format .` 已格式化
- [ ] `pytest` 全部通过
- [ ] 类型提示完整
- [ ] 文档字符串完整

### 合并前检查

- [ ] 代码审查通过
- [ ] CI 流水线通过
- [ ] 无冲突
