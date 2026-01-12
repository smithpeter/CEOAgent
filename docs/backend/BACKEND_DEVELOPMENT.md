# CEOAgent 后端开发准备文档

> **文档目的**：为 AI Agent 提供完整的后端开发指南，包含所有实现细节，使其能够自动化完成开发任务。
>
> **目标读者**：AI 开发助手（Claude Code）、后端开发人员
>
> **当前阶段**：Phase 1 MVP

---

## 一、开发任务总览

### 1.1 需要创建的文件

```
src/ceo_agent/
├── __init__.py                 # 包初始化，版本信息
├── main.py                     # FastAPI 应用入口
├── config.py                   # 配置管理（Pydantic Settings）
├── core/
│   ├── __init__.py
│   ├── agent.py                # AgentCore 主协调器
│   ├── claude_client.py        # Claude API 封装
│   ├── prompt_manager.py       # Prompt 模板管理
│   ├── response_parser.py      # 响应解析器
│   └── memory.py               # 会话内存存储
├── api/
│   ├── __init__.py
│   ├── routes.py               # API 路由定义
│   ├── schemas.py              # Pydantic 请求/响应模型
│   └── dependencies.py         # FastAPI 依赖注入
└── exceptions.py               # 自定义异常类

prompts/v1/
├── system.txt                  # 系统级 Prompt
├── investment_decision.txt     # 投资决策分析模板
├── risk_assessment.txt         # 风险评估模板
└── strategy_planning.txt       # 战略规划模板

tests/
├── __init__.py
├── conftest.py                 # pytest fixtures
├── test_claude_client.py
├── test_prompt_manager.py
├── test_response_parser.py
├── test_agent.py
└── test_api.py

evaluation/
├── test_cases/
│   ├── investment_cases.json
│   ├── risk_cases.json
│   └── strategy_cases.json
└── run_eval.py
```

### 1.2 开发顺序

```
Day 1: 基础设施
  └── config.py → exceptions.py → schemas.py

Day 2: 核心组件
  └── claude_client.py → prompt_manager.py → response_parser.py

Day 3: 业务逻辑
  └── memory.py → agent.py

Day 4: API 层
  └── dependencies.py → routes.py → main.py

Day 5: 测试与评估
  └── tests/* → evaluation/* → 集成测试
```

---

## 二、配置管理 (config.py)

### 2.1 实现规范

```python
"""
文件: src/ceo_agent/config.py
职责: 集中管理所有配置项，支持环境变量覆盖
依赖: pydantic-settings
"""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator


class Settings(BaseSettings):
    """应用配置类

    所有配置项从环境变量读取，支持 .env 文件
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ===== 必需配置 =====
    anthropic_api_key: str = Field(
        ...,
        description="Anthropic API Key",
        json_schema_extra={"env": "ANTHROPIC_API_KEY"}
    )

    # ===== Claude 配置 =====
    claude_model: str = Field(
        default="claude-sonnet-4-20250514",
        description="Claude 模型版本"
    )
    max_tokens: int = Field(
        default=4096,
        ge=100,
        le=8192,
        description="单次请求最大 token 数"
    )
    temperature: float = Field(
        default=0.7,
        ge=0.0,
        le=1.0,
        description="生成温度"
    )
    request_timeout: int = Field(
        default=120,
        ge=30,
        le=300,
        description="API 请求超时时间（秒）"
    )

    # ===== 应用配置 =====
    app_env: str = Field(
        default="development",
        pattern="^(development|staging|production)$"
    )
    api_host: str = Field(default="0.0.0.0")
    api_port: int = Field(default=8000, ge=1, le=65535)
    debug: bool = Field(default=False)
    log_level: str = Field(
        default="INFO",
        pattern="^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$"
    )

    # ===== 速率限制 =====
    rate_limit_per_minute: int = Field(default=10, ge=1, le=100)

    # ===== 内存存储配置 =====
    memory_max_conversations: int = Field(
        default=100,
        description="最大保存会话数"
    )
    memory_max_turns_per_conversation: int = Field(
        default=50,
        description="每个会话最大对话轮数"
    )
    memory_ttl_seconds: int = Field(
        default=3600,
        description="会话过期时间（秒）"
    )

    # ===== Prompt 配置 =====
    prompts_dir: str = Field(
        default="prompts/v1",
        description="Prompt 模板目录"
    )

    @field_validator("anthropic_api_key")
    @classmethod
    def validate_api_key(cls, v: str) -> str:
        if not v.startswith("sk-ant-"):
            raise ValueError("Invalid Anthropic API key format")
        return v

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    """获取配置单例"""
    return Settings()
```

### 2.2 使用方式

```python
from ceo_agent.config import get_settings

settings = get_settings()
api_key = settings.anthropic_api_key
```

---

## 三、异常处理 (exceptions.py)

### 3.1 异常类层次

```python
"""
文件: src/ceo_agent/exceptions.py
职责: 定义所有自定义异常，统一错误处理
"""

from typing import Any


class CEOAgentError(Exception):
    """基础异常类"""

    def __init__(
        self,
        message: str,
        code: str,
        details: dict[str, Any] | None = None
    ):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "message": self.message,
            "details": self.details,
        }


# ===== Claude API 相关异常 =====

class ClaudeAPIError(CEOAgentError):
    """Claude API 调用失败"""

    def __init__(self, message: str, details: dict[str, Any] | None = None):
        super().__init__(message, "CLAUDE_API_ERROR", details)


class ClaudeRateLimitError(ClaudeAPIError):
    """Claude API 速率限制"""

    def __init__(self, retry_after: int | None = None):
        details = {"retry_after": retry_after} if retry_after else {}
        super().__init__("Rate limit exceeded", details)
        self.code = "CLAUDE_RATE_LIMIT"


class ClaudeTimeoutError(ClaudeAPIError):
    """Claude API 超时"""

    def __init__(self, timeout: int):
        super().__init__(f"Request timed out after {timeout}s", {"timeout": timeout})
        self.code = "CLAUDE_TIMEOUT"


# ===== 业务逻辑异常 =====

class ValidationError(CEOAgentError):
    """输入验证失败"""

    def __init__(self, message: str, field: str | None = None):
        details = {"field": field} if field else {}
        super().__init__(message, "VALIDATION_ERROR", details)


class AnalysisError(CEOAgentError):
    """分析执行失败"""

    def __init__(self, message: str, analysis_type: str):
        super().__init__(message, "ANALYSIS_ERROR", {"analysis_type": analysis_type})


class ResponseParseError(CEOAgentError):
    """响应解析失败"""

    def __init__(self, message: str, raw_response: str | None = None):
        details = {"raw_response_preview": raw_response[:200] if raw_response else None}
        super().__init__(message, "RESPONSE_PARSE_ERROR", details)


# ===== 资源相关异常 =====

class PromptNotFoundError(CEOAgentError):
    """Prompt 模板未找到"""

    def __init__(self, template_name: str):
        super().__init__(
            f"Prompt template not found: {template_name}",
            "PROMPT_NOT_FOUND",
            {"template_name": template_name}
        )


class ConversationNotFoundError(CEOAgentError):
    """会话未找到"""

    def __init__(self, conversation_id: str):
        super().__init__(
            f"Conversation not found: {conversation_id}",
            "CONVERSATION_NOT_FOUND",
            {"conversation_id": conversation_id}
        )
```

---

## 四、数据模型 (schemas.py)

### 4.1 请求模型

```python
"""
文件: src/ceo_agent/api/schemas.py
职责: 定义所有 API 请求和响应的 Pydantic 模型
"""

from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, field_validator


# ===== 枚举类型 =====

class AnalysisType(str, Enum):
    """分析类型"""
    INVESTMENT = "investment"
    RISK = "risk"
    STRATEGY = "strategy"
    GENERAL = "general"


class RiskLevel(str, Enum):
    """风险等级"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class RiskTolerance(str, Enum):
    """风险容忍度"""
    CONSERVATIVE = "conservative"
    MODERATE = "moderate"
    AGGRESSIVE = "aggressive"


# ===== 通用子模型 =====

class FinancialData(BaseModel):
    """财务数据"""
    revenue: float = Field(..., ge=0, description="营收")
    profit: float = Field(..., description="利润")
    cash_flow: float = Field(..., description="现金流")

    @field_validator("revenue", "profit", "cash_flow", mode="before")
    @classmethod
    def convert_to_float(cls, v: Any) -> float:
        if isinstance(v, str):
            # 处理带单位的字符串，如 "12M", "1.5B"
            v = v.strip().upper()
            multipliers = {"K": 1e3, "M": 1e6, "B": 1e9}
            for suffix, mult in multipliers.items():
                if v.endswith(suffix):
                    return float(v[:-1]) * mult
        return float(v)


class CompanyProfile(BaseModel):
    """公司概况"""
    name: str | None = Field(default=None, max_length=100)
    industry: str = Field(..., max_length=50)
    size: str | None = Field(default=None, description="公司规模")
    stage: str | None = Field(default=None, description="发展阶段")


class RiskFactor(BaseModel):
    """风险因素"""
    name: str = Field(..., max_length=100)
    level: RiskLevel
    reason: str = Field(..., max_length=500)
    probability: str | None = None
    impact: str | None = None


class Recommendation(BaseModel):
    """推荐方案"""
    title: str = Field(..., max_length=200)
    description: str = Field(..., max_length=2000)
    risk_level: RiskLevel
    pros: list[str] = Field(default_factory=list)
    cons: list[str] = Field(default_factory=list)
    action_steps: list[str] = Field(default_factory=list)
    timeline: str | None = None
    expected_return: str | None = None
    investment_amount: str | None = None


class FinalRecommendation(BaseModel):
    """最终推荐"""
    choice: str = Field(..., description="推荐的方案")
    reasoning: str = Field(..., max_length=2000, description="推荐理由")
    confidence: float = Field(default=0.0, ge=0.0, le=1.0)


# ===== 请求模型 =====

class AnalysisRequest(BaseModel):
    """通用分析请求"""
    query: str = Field(
        ...,
        min_length=10,
        max_length=5000,
        description="分析问题"
    )
    analysis_type: AnalysisType = Field(
        default=AnalysisType.GENERAL,
        description="分析类型"
    )
    context: dict[str, Any] | None = Field(
        default=None,
        description="上下文数据"
    )
    conversation_id: str | None = Field(
        default=None,
        description="会话 ID，用于多轮对话"
    )

    @field_validator("query")
    @classmethod
    def validate_query(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Query cannot be empty")
        return v


class InvestmentAnalysisRequest(BaseModel):
    """投资决策分析请求"""
    query: str = Field(..., min_length=10, max_length=5000)
    company_financials: dict[str, FinancialData] = Field(
        ...,
        description="按季度/年度的财务数据"
    )
    decision_type: str = Field(..., description="决策类型")
    budget_range: str = Field(..., description="预算范围")
    risk_tolerance: RiskTolerance = Field(default=RiskTolerance.MODERATE)
    competitor_data: dict[str, Any] | None = None
    market_report: str | None = Field(default=None, max_length=10000)
    constraints: list[str] = Field(default_factory=list)
    conversation_id: str | None = None


class RiskAssessmentRequest(BaseModel):
    """风险评估请求"""
    query: str = Field(..., min_length=10, max_length=5000)
    company_profile: CompanyProfile
    financial_health: dict[str, Any] = Field(..., description="财务健康指标")
    risk_areas: list[str] = Field(
        default_factory=lambda: ["financial", "market", "operational"],
        description="需要评估的风险领域"
    )
    external_factors: dict[str, Any] | None = None
    historical_incidents: list[dict[str, Any]] = Field(default_factory=list)
    risk_tolerance: RiskTolerance = Field(default=RiskTolerance.MODERATE)
    conversation_id: str | None = None


class StrategyPlanningRequest(BaseModel):
    """战略规划请求"""
    query: str = Field(..., min_length=10, max_length=5000)
    business_status: dict[str, Any] = Field(..., description="业务现状")
    strategic_goals: list[str] = Field(..., min_length=1, description="战略目标")
    constraints: list[str] = Field(default_factory=list)
    swot: dict[str, list[str]] | None = Field(
        default=None,
        description="SWOT 分析"
    )
    market_analysis: dict[str, Any] | None = None
    competitor_info: list[dict[str, Any]] = Field(default_factory=list)
    time_horizon: str = Field(default="12_months")
    conversation_id: str | None = None


class ChatRequest(BaseModel):
    """对话请求"""
    message: str = Field(..., min_length=1, max_length=5000)
    conversation_id: str | None = None


# ===== 响应模型 =====

class SituationAnalysis(BaseModel):
    """态势分析"""
    summary: str = Field(..., max_length=500)
    key_findings: list[str] = Field(default_factory=list)


class RiskAssessment(BaseModel):
    """风险评估结果"""
    overall_score: int = Field(..., ge=1, le=10)
    risk_level: RiskLevel
    risk_factors: list[RiskFactor] = Field(default_factory=list)


class AnalysisResult(BaseModel):
    """分析结果"""
    situation_analysis: SituationAnalysis
    risk_assessment: RiskAssessment
    recommendations: list[Recommendation] = Field(default_factory=list)
    final_recommendation: FinalRecommendation | None = None


class ResponseMetadata(BaseModel):
    """响应元数据"""
    request_id: str = Field(default_factory=lambda: str(uuid4()))
    model: str
    tokens_used: int = Field(ge=0)
    execution_time_ms: int = Field(ge=0)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class AnalysisResponse(BaseModel):
    """分析响应"""
    success: bool = True
    data: dict[str, Any] = Field(default_factory=dict)
    metadata: ResponseMetadata

    @classmethod
    def create_success(
        cls,
        analysis_id: str,
        query: str,
        result: AnalysisResult,
        metadata: ResponseMetadata,
    ) -> "AnalysisResponse":
        return cls(
            success=True,
            data={
                "analysis_id": analysis_id,
                "query": query,
                "result": result.model_dump(),
            },
            metadata=metadata,
        )


class ErrorDetail(BaseModel):
    """错误详情"""
    code: str
    message: str
    details: dict[str, Any] = Field(default_factory=dict)


class ErrorResponse(BaseModel):
    """错误响应"""
    success: bool = False
    error: ErrorDetail
    metadata: ResponseMetadata | None = None


class ChatMessage(BaseModel):
    """对话消息"""
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ChatResponse(BaseModel):
    """对话响应"""
    success: bool = True
    data: dict[str, Any]
    metadata: ResponseMetadata


class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str = "healthy"
    version: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    checks: dict[str, bool] = Field(default_factory=dict)
```

---

## 五、核心组件实现

### 5.1 Claude 客户端 (claude_client.py)

```python
"""
文件: src/ceo_agent/core/claude_client.py
职责: 封装 Anthropic SDK，提供统一的 Claude API 调用接口
"""

import asyncio
import logging
from typing import Any, AsyncGenerator

from anthropic import AsyncAnthropic, APIError, RateLimitError, APITimeoutError

from ceo_agent.config import Settings
from ceo_agent.exceptions import (
    ClaudeAPIError,
    ClaudeRateLimitError,
    ClaudeTimeoutError,
)

logger = logging.getLogger(__name__)


class ClaudeClient:
    """Claude API 客户端

    功能：
    - 异步 API 调用
    - 流式响应支持
    - 自动重试机制
    - Token 使用统计
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = AsyncAnthropic(api_key=settings.anthropic_api_key)
        self._total_tokens_used = 0

    async def complete(
        self,
        system_prompt: str,
        user_message: str,
        conversation_history: list[dict[str, str]] | None = None,
        max_tokens: int | None = None,
        temperature: float | None = None,
    ) -> tuple[str, int]:
        """发送完成请求

        Args:
            system_prompt: 系统 Prompt
            user_message: 用户消息
            conversation_history: 对话历史 [{"role": "user/assistant", "content": "..."}]
            max_tokens: 最大 token 数
            temperature: 生成温度

        Returns:
            tuple[str, int]: (响应文本, 使用的 token 数)

        Raises:
            ClaudeAPIError: API 调用失败
            ClaudeRateLimitError: 速率限制
            ClaudeTimeoutError: 请求超时
        """
        messages = []

        # 添加历史消息
        if conversation_history:
            messages.extend(conversation_history)

        # 添加当前用户消息
        messages.append({"role": "user", "content": user_message})

        try:
            response = await self._call_with_retry(
                system_prompt=system_prompt,
                messages=messages,
                max_tokens=max_tokens or self.settings.max_tokens,
                temperature=temperature or self.settings.temperature,
            )

            content = response.content[0].text
            tokens_used = response.usage.input_tokens + response.usage.output_tokens
            self._total_tokens_used += tokens_used

            logger.info(
                f"Claude API call completed. Tokens: {tokens_used}, "
                f"Total: {self._total_tokens_used}"
            )

            return content, tokens_used

        except RateLimitError as e:
            logger.error(f"Rate limit exceeded: {e}")
            retry_after = getattr(e, "retry_after", None)
            raise ClaudeRateLimitError(retry_after=retry_after)

        except APITimeoutError as e:
            logger.error(f"API timeout: {e}")
            raise ClaudeTimeoutError(timeout=self.settings.request_timeout)

        except APIError as e:
            logger.error(f"API error: {e}")
            raise ClaudeAPIError(str(e), {"status_code": getattr(e, "status_code", None)})

    async def stream_complete(
        self,
        system_prompt: str,
        user_message: str,
        conversation_history: list[dict[str, str]] | None = None,
    ) -> AsyncGenerator[str, None]:
        """流式完成请求

        Yields:
            str: 响应文本片段
        """
        messages = []
        if conversation_history:
            messages.extend(conversation_history)
        messages.append({"role": "user", "content": user_message})

        try:
            async with self.client.messages.stream(
                model=self.settings.claude_model,
                max_tokens=self.settings.max_tokens,
                system=system_prompt,
                messages=messages,
            ) as stream:
                async for text in stream.text_stream:
                    yield text

        except Exception as e:
            logger.error(f"Streaming error: {e}")
            raise ClaudeAPIError(f"Streaming failed: {e}")

    async def _call_with_retry(
        self,
        system_prompt: str,
        messages: list[dict[str, str]],
        max_tokens: int,
        temperature: float,
        max_retries: int = 3,
        base_delay: float = 1.0,
    ) -> Any:
        """带重试的 API 调用

        使用指数退避策略
        """
        last_error = None

        for attempt in range(max_retries):
            try:
                return await asyncio.wait_for(
                    self.client.messages.create(
                        model=self.settings.claude_model,
                        max_tokens=max_tokens,
                        temperature=temperature,
                        system=system_prompt,
                        messages=messages,
                    ),
                    timeout=self.settings.request_timeout,
                )
            except (APIError, asyncio.TimeoutError) as e:
                last_error = e
                if attempt < max_retries - 1:
                    delay = base_delay * (2 ** attempt)
                    logger.warning(
                        f"API call failed (attempt {attempt + 1}/{max_retries}), "
                        f"retrying in {delay}s: {e}"
                    )
                    await asyncio.sleep(delay)

        raise last_error or ClaudeAPIError("Max retries exceeded")

    @property
    def total_tokens_used(self) -> int:
        """获取总 token 使用量"""
        return self._total_tokens_used

    def reset_token_counter(self) -> None:
        """重置 token 计数器"""
        self._total_tokens_used = 0
```

### 5.2 Prompt 管理器 (prompt_manager.py)

```python
"""
文件: src/ceo_agent/core/prompt_manager.py
职责: 加载、缓存和渲染 Prompt 模板
"""

import logging
from pathlib import Path
from string import Template
from typing import Any

from ceo_agent.config import Settings
from ceo_agent.exceptions import PromptNotFoundError

logger = logging.getLogger(__name__)


class PromptManager:
    """Prompt 模板管理器

    功能：
    - 从文件加载模板
    - 模板缓存
    - 变量替换渲染
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.prompts_dir = Path(settings.prompts_dir)
        self._cache: dict[str, str] = {}

        # 预加载所有模板
        self._preload_templates()

    def _preload_templates(self) -> None:
        """预加载所有 Prompt 模板"""
        if not self.prompts_dir.exists():
            logger.warning(f"Prompts directory not found: {self.prompts_dir}")
            return

        for prompt_file in self.prompts_dir.glob("*.txt"):
            template_name = prompt_file.stem
            try:
                content = prompt_file.read_text(encoding="utf-8")
                self._cache[template_name] = content
                logger.debug(f"Loaded prompt template: {template_name}")
            except Exception as e:
                logger.error(f"Failed to load template {template_name}: {e}")

        logger.info(f"Loaded {len(self._cache)} prompt templates")

    def get_template(self, name: str) -> str:
        """获取模板内容

        Args:
            name: 模板名称（不含 .txt 后缀）

        Returns:
            模板内容

        Raises:
            PromptNotFoundError: 模板不存在
        """
        if name in self._cache:
            return self._cache[name]

        # 尝试从文件加载
        template_path = self.prompts_dir / f"{name}.txt"
        if template_path.exists():
            content = template_path.read_text(encoding="utf-8")
            self._cache[name] = content
            return content

        raise PromptNotFoundError(name)

    def render(self, name: str, variables: dict[str, Any] | None = None) -> str:
        """渲染模板

        Args:
            name: 模板名称
            variables: 变量字典

        Returns:
            渲染后的内容
        """
        template_content = self.get_template(name)

        if not variables:
            return template_content

        # 使用 safe_substitute 避免缺失变量时报错
        template = Template(template_content)
        return template.safe_substitute(variables)

    def get_system_prompt(self) -> str:
        """获取系统 Prompt"""
        try:
            return self.get_template("system")
        except PromptNotFoundError:
            # 返回默认系统 Prompt
            return self._get_default_system_prompt()

    def get_analysis_prompt(
        self,
        analysis_type: str,
        data: dict[str, Any],
    ) -> str:
        """获取分析类型对应的 Prompt

        Args:
            analysis_type: 分析类型 (investment/risk/strategy/general)
            data: 需要填充到模板的数据

        Returns:
            渲染后的 Prompt
        """
        template_map = {
            "investment": "investment_decision",
            "risk": "risk_assessment",
            "strategy": "strategy_planning",
            "general": "general_analysis",
        }

        template_name = template_map.get(analysis_type, "general_analysis")

        try:
            return self.render(template_name, data)
        except PromptNotFoundError:
            # 使用通用模板
            return self._build_fallback_prompt(analysis_type, data)

    def _get_default_system_prompt(self) -> str:
        """默认系统 Prompt"""
        return """You are an expert CEO decision support AI assistant.

Your role is to help CEOs make informed decisions by:
1. Analyzing business situations comprehensively
2. Assessing risks with quantitative scores (1-10 scale)
3. Providing multiple strategic options
4. Making clear, justified recommendations

Always structure your responses with:
- Situation Analysis: Key findings and context
- Risk Assessment: Score and factors
- Recommendations: Multiple options with pros/cons
- Final Recommendation: Clear choice with reasoning

Be concise, data-driven, and actionable."""

    def _build_fallback_prompt(
        self,
        analysis_type: str,
        data: dict[str, Any],
    ) -> str:
        """构建备用 Prompt"""
        data_str = "\n".join(f"- {k}: {v}" for k, v in data.items() if v)

        return f"""Perform a {analysis_type} analysis based on the following information:

{data_str}

Please provide:
1. Situation Analysis (max 150 words)
2. Risk Assessment (score 1-10 with factors)
3. At least 2-3 recommendations with action steps
4. Final recommendation with clear reasoning

Format your response as structured sections."""

    def reload_templates(self) -> None:
        """重新加载所有模板"""
        self._cache.clear()
        self._preload_templates()

    def list_templates(self) -> list[str]:
        """列出所有可用模板"""
        return list(self._cache.keys())
```

### 5.3 响应解析器 (response_parser.py)

```python
"""
文件: src/ceo_agent/core/response_parser.py
职责: 解析 Claude 响应，提取结构化数据
"""

import json
import logging
import re
from typing import Any

from ceo_agent.api.schemas import (
    AnalysisResult,
    FinalRecommendation,
    Recommendation,
    RiskAssessment,
    RiskFactor,
    RiskLevel,
    SituationAnalysis,
)
from ceo_agent.exceptions import ResponseParseError

logger = logging.getLogger(__name__)


class ResponseParser:
    """响应解析器

    功能：
    - 从文本中提取 JSON
    - 解析结构化部分
    - 容错处理
    """

    # JSON 代码块模式
    JSON_PATTERN = re.compile(r"```(?:json)?\s*\n?(.*?)\n?```", re.DOTALL)

    # 风险评分模式
    RISK_SCORE_PATTERN = re.compile(
        r"(?:risk\s*score|overall\s*score|风险评分)[:\s]*(\d+)",
        re.IGNORECASE
    )

    # 章节标题模式
    SECTION_PATTERNS = {
        "situation": re.compile(
            r"(?:##?\s*)?(?:situation\s*analysis|态势分析|现状分析)[:\s]*\n?(.*?)(?=(?:##?\s*)?(?:risk|recommendation|建议|风险)|$)",
            re.IGNORECASE | re.DOTALL
        ),
        "risk": re.compile(
            r"(?:##?\s*)?(?:risk\s*assessment|风险评估|风险分析)[:\s]*\n?(.*?)(?=(?:##?\s*)?(?:recommendation|建议|final)|$)",
            re.IGNORECASE | re.DOTALL
        ),
        "recommendations": re.compile(
            r"(?:##?\s*)?(?:recommendations?|建议|方案)[:\s]*\n?(.*?)(?=(?:##?\s*)?(?:final|最终|结论)|$)",
            re.IGNORECASE | re.DOTALL
        ),
        "final": re.compile(
            r"(?:##?\s*)?(?:final\s*recommendation|最终建议|结论)[:\s]*\n?(.*?)$",
            re.IGNORECASE | re.DOTALL
        ),
    }

    def parse(self, response: str) -> AnalysisResult:
        """解析响应文本

        Args:
            response: Claude 原始响应

        Returns:
            AnalysisResult: 结构化分析结果

        Raises:
            ResponseParseError: 解析失败
        """
        try:
            # 首先尝试提取 JSON
            json_result = self._extract_json(response)
            if json_result:
                return self._parse_json_result(json_result)

            # 回退到文本解析
            return self._parse_text_result(response)

        except Exception as e:
            logger.error(f"Failed to parse response: {e}")
            raise ResponseParseError(str(e), response)

    def _extract_json(self, text: str) -> dict[str, Any] | None:
        """从文本中提取 JSON"""
        # 尝试找 JSON 代码块
        matches = self.JSON_PATTERN.findall(text)
        for match in matches:
            try:
                return json.loads(match.strip())
            except json.JSONDecodeError:
                continue

        # 尝试直接解析整个文本
        try:
            # 找到第一个 { 和最后一个 }
            start = text.find("{")
            end = text.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(text[start:end])
        except json.JSONDecodeError:
            pass

        return None

    def _parse_json_result(self, data: dict[str, Any]) -> AnalysisResult:
        """解析 JSON 格式的结果"""
        # 解析态势分析
        situation = self._parse_situation_from_dict(
            data.get("situation_analysis", data.get("situationAnalysis", {}))
        )

        # 解析风险评估
        risk = self._parse_risk_from_dict(
            data.get("risk_assessment", data.get("riskAssessment", {}))
        )

        # 解析推荐方案
        recommendations = self._parse_recommendations_from_list(
            data.get("recommendations", [])
        )

        # 解析最终推荐
        final = self._parse_final_from_dict(
            data.get("final_recommendation", data.get("finalRecommendation", {}))
        )

        return AnalysisResult(
            situation_analysis=situation,
            risk_assessment=risk,
            recommendations=recommendations,
            final_recommendation=final,
        )

    def _parse_text_result(self, text: str) -> AnalysisResult:
        """解析纯文本格式的结果"""
        sections = self._extract_sections(text)

        # 解析各部分
        situation = self._parse_situation_from_text(sections.get("situation", ""))
        risk = self._parse_risk_from_text(sections.get("risk", ""), text)
        recommendations = self._parse_recommendations_from_text(
            sections.get("recommendations", "")
        )
        final = self._parse_final_from_text(sections.get("final", ""))

        return AnalysisResult(
            situation_analysis=situation,
            risk_assessment=risk,
            recommendations=recommendations,
            final_recommendation=final,
        )

    def _extract_sections(self, text: str) -> dict[str, str]:
        """提取文本中的各个部分"""
        sections = {}
        for name, pattern in self.SECTION_PATTERNS.items():
            match = pattern.search(text)
            if match:
                sections[name] = match.group(1).strip()
        return sections

    def _parse_situation_from_dict(
        self,
        data: dict[str, Any] | str,
    ) -> SituationAnalysis:
        """从字典解析态势分析"""
        if isinstance(data, str):
            return SituationAnalysis(summary=data[:500], key_findings=[])

        return SituationAnalysis(
            summary=str(data.get("summary", data.get("description", "")))[:500],
            key_findings=data.get("key_findings", data.get("keyFindings", [])),
        )

    def _parse_situation_from_text(self, text: str) -> SituationAnalysis:
        """从文本解析态势分析"""
        # 提取关键发现（列表项）
        findings = re.findall(r"[-•]\s*(.+)", text)
        summary = text[:500] if not findings else text.split("\n")[0][:500]

        return SituationAnalysis(
            summary=summary.strip(),
            key_findings=findings[:5],
        )

    def _parse_risk_from_dict(self, data: dict[str, Any]) -> RiskAssessment:
        """从字典解析风险评估"""
        if not data:
            return RiskAssessment(
                overall_score=5,
                risk_level=RiskLevel.MEDIUM,
                risk_factors=[],
            )

        score = int(data.get("overall_score", data.get("overallScore", 5)))
        score = max(1, min(10, score))  # 确保在 1-10 范围内

        # 根据分数确定风险等级
        risk_level = self._score_to_level(score)

        # 解析风险因素
        factors = []
        for factor in data.get("risk_factors", data.get("riskFactors", [])):
            if isinstance(factor, dict):
                factors.append(RiskFactor(
                    name=factor.get("name", "Unknown"),
                    level=RiskLevel(factor.get("level", "medium").lower()),
                    reason=factor.get("reason", factor.get("description", "")),
                    probability=factor.get("probability"),
                    impact=factor.get("impact"),
                ))

        return RiskAssessment(
            overall_score=score,
            risk_level=risk_level,
            risk_factors=factors,
        )

    def _parse_risk_from_text(self, section: str, full_text: str) -> RiskAssessment:
        """从文本解析风险评估"""
        # 提取风险评分
        score = 5  # 默认值
        match = self.RISK_SCORE_PATTERN.search(full_text)
        if match:
            score = int(match.group(1))
            score = max(1, min(10, score))

        risk_level = self._score_to_level(score)

        # 提取风险因素
        factors = []
        factor_matches = re.findall(r"[-•]\s*(.+?)[:：]\s*(.+)", section)
        for name, reason in factor_matches[:5]:
            factors.append(RiskFactor(
                name=name.strip(),
                level=risk_level,
                reason=reason.strip(),
            ))

        return RiskAssessment(
            overall_score=score,
            risk_level=risk_level,
            risk_factors=factors,
        )

    def _parse_recommendations_from_list(
        self,
        data: list[dict[str, Any]],
    ) -> list[Recommendation]:
        """从列表解析推荐方案"""
        recommendations = []

        for item in data[:5]:  # 最多 5 个方案
            if isinstance(item, dict):
                recommendations.append(Recommendation(
                    title=item.get("title", "Untitled"),
                    description=item.get("description", ""),
                    risk_level=RiskLevel(
                        item.get("risk_level", item.get("riskLevel", "medium")).lower()
                    ),
                    pros=item.get("pros", []),
                    cons=item.get("cons", []),
                    action_steps=item.get("action_steps", item.get("actionSteps", [])),
                    timeline=item.get("timeline"),
                    expected_return=item.get("expected_return", item.get("expectedReturn")),
                    investment_amount=item.get("investment_amount", item.get("investmentAmount")),
                ))

        return recommendations

    def _parse_recommendations_from_text(self, text: str) -> list[Recommendation]:
        """从文本解析推荐方案"""
        recommendations = []

        # 尝试按方案标题分割
        plan_pattern = re.compile(
            r"(?:方案|Plan|Option)\s*[A-Z\d一二三四五][:：]?\s*(.+?)(?=(?:方案|Plan|Option)\s*[A-Z\d一二三四五]|$)",
            re.IGNORECASE | re.DOTALL
        )

        matches = plan_pattern.findall(text)

        if not matches:
            # 回退：按数字列表分割
            matches = re.split(r"\n\d+\.\s+", text)
            matches = [m.strip() for m in matches if m.strip()]

        for i, match in enumerate(matches[:5]):
            lines = match.strip().split("\n")
            title = lines[0][:100] if lines else f"Option {i + 1}"
            description = "\n".join(lines[1:])[:1000] if len(lines) > 1 else ""

            # 提取优缺点
            pros = re.findall(r"(?:优点|pros?|advantages?)[:\s]*(.+)", match, re.I)
            cons = re.findall(r"(?:缺点|cons?|disadvantages?)[:\s]*(.+)", match, re.I)

            # 提取行动步骤
            steps = re.findall(r"(?:步骤|step|action)[:\s]*(.+)", match, re.I)

            recommendations.append(Recommendation(
                title=title.strip(),
                description=description.strip(),
                risk_level=RiskLevel.MEDIUM,
                pros=[p.strip() for p in pros],
                cons=[c.strip() for c in cons],
                action_steps=[s.strip() for s in steps],
            ))

        return recommendations

    def _parse_final_from_dict(
        self,
        data: dict[str, Any] | None,
    ) -> FinalRecommendation | None:
        """从字典解析最终推荐"""
        if not data:
            return None

        return FinalRecommendation(
            choice=str(data.get("choice", data.get("recommendation", ""))),
            reasoning=str(data.get("reasoning", data.get("reason", "")))[:2000],
            confidence=float(data.get("confidence", 0.0)),
        )

    def _parse_final_from_text(self, text: str) -> FinalRecommendation | None:
        """从文本解析最终推荐"""
        if not text.strip():
            return None

        # 尝试提取选择和理由
        choice_match = re.search(
            r"(?:recommend|选择|建议)[:\s]*(.+?)(?:\n|$)",
            text,
            re.IGNORECASE
        )
        choice = choice_match.group(1).strip() if choice_match else text.split("\n")[0]

        # 剩余部分作为理由
        reasoning = text.replace(choice, "").strip()[:2000]

        return FinalRecommendation(
            choice=choice[:200],
            reasoning=reasoning or "Based on the analysis above.",
        )

    def _score_to_level(self, score: int) -> RiskLevel:
        """将评分转换为风险等级"""
        if score <= 3:
            return RiskLevel.LOW
        elif score <= 5:
            return RiskLevel.MEDIUM
        elif score <= 7:
            return RiskLevel.HIGH
        else:
            return RiskLevel.CRITICAL
```

### 5.4 内存存储 (memory.py)

```python
"""
文件: src/ceo_agent/core/memory.py
职责: 管理会话和对话历史
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Any
from uuid import uuid4

from ceo_agent.config import Settings
from ceo_agent.exceptions import ConversationNotFoundError

logger = logging.getLogger(__name__)


class Message:
    """对话消息"""

    def __init__(self, role: str, content: str):
        self.role = role
        self.content = content
        self.timestamp = datetime.utcnow()

    def to_dict(self) -> dict[str, str]:
        return {"role": self.role, "content": self.content}


class Conversation:
    """会话"""

    def __init__(self, conversation_id: str, max_turns: int):
        self.id = conversation_id
        self.max_turns = max_turns
        self.messages: list[Message] = []
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.metadata: dict[str, Any] = {}

    def add_message(self, role: str, content: str) -> None:
        """添加消息"""
        self.messages.append(Message(role, content))
        self.updated_at = datetime.utcnow()

        # 超过最大轮数时删除最早的消息
        while len(self.messages) > self.max_turns * 2:
            self.messages.pop(0)

    def get_history(self) -> list[dict[str, str]]:
        """获取对话历史"""
        return [msg.to_dict() for msg in self.messages]

    def clear(self) -> None:
        """清空消息"""
        self.messages.clear()
        self.updated_at = datetime.utcnow()


class MemoryStore:
    """内存存储

    功能：
    - 会话管理
    - 对话历史存储
    - TTL 过期清理
    - 并发安全
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self._conversations: dict[str, Conversation] = {}
        self._lock = asyncio.Lock()
        self._cleanup_task: asyncio.Task | None = None

    async def start(self) -> None:
        """启动内存存储（开始清理任务）"""
        if self._cleanup_task is None:
            self._cleanup_task = asyncio.create_task(self._cleanup_loop())
            logger.info("Memory store cleanup task started")

    async def stop(self) -> None:
        """停止内存存储"""
        if self._cleanup_task:
            self._cleanup_task.cancel()
            try:
                await self._cleanup_task
            except asyncio.CancelledError:
                pass
            self._cleanup_task = None
            logger.info("Memory store cleanup task stopped")

    async def create_conversation(self) -> str:
        """创建新会话"""
        conversation_id = str(uuid4())

        async with self._lock:
            # 检查是否超过最大会话数
            if len(self._conversations) >= self.settings.memory_max_conversations:
                # 删除最旧的会话
                await self._remove_oldest()

            self._conversations[conversation_id] = Conversation(
                conversation_id=conversation_id,
                max_turns=self.settings.memory_max_turns_per_conversation,
            )

        logger.debug(f"Created conversation: {conversation_id}")
        return conversation_id

    async def get_conversation(self, conversation_id: str) -> Conversation:
        """获取会话"""
        async with self._lock:
            if conversation_id not in self._conversations:
                raise ConversationNotFoundError(conversation_id)
            return self._conversations[conversation_id]

    async def get_or_create_conversation(
        self,
        conversation_id: str | None,
    ) -> tuple[str, Conversation]:
        """获取或创建会话"""
        if conversation_id:
            try:
                conv = await self.get_conversation(conversation_id)
                return conversation_id, conv
            except ConversationNotFoundError:
                pass

        new_id = await self.create_conversation()
        conv = await self.get_conversation(new_id)
        return new_id, conv

    async def add_message(
        self,
        conversation_id: str,
        role: str,
        content: str,
    ) -> None:
        """向会话添加消息"""
        async with self._lock:
            if conversation_id not in self._conversations:
                raise ConversationNotFoundError(conversation_id)

            self._conversations[conversation_id].add_message(role, content)

    async def get_history(self, conversation_id: str) -> list[dict[str, str]]:
        """获取对话历史"""
        async with self._lock:
            if conversation_id not in self._conversations:
                raise ConversationNotFoundError(conversation_id)

            return self._conversations[conversation_id].get_history()

    async def delete_conversation(self, conversation_id: str) -> None:
        """删除会话"""
        async with self._lock:
            if conversation_id in self._conversations:
                del self._conversations[conversation_id]
                logger.debug(f"Deleted conversation: {conversation_id}")

    async def clear_all(self) -> None:
        """清空所有会话"""
        async with self._lock:
            self._conversations.clear()
            logger.info("Cleared all conversations")

    async def _remove_oldest(self) -> None:
        """删除最旧的会话（需要在锁内调用）"""
        if not self._conversations:
            return

        oldest_id = min(
            self._conversations.keys(),
            key=lambda k: self._conversations[k].updated_at,
        )
        del self._conversations[oldest_id]
        logger.debug(f"Removed oldest conversation: {oldest_id}")

    async def _cleanup_expired(self) -> None:
        """清理过期会话"""
        ttl = timedelta(seconds=self.settings.memory_ttl_seconds)
        cutoff = datetime.utcnow() - ttl

        async with self._lock:
            expired = [
                cid for cid, conv in self._conversations.items()
                if conv.updated_at < cutoff
            ]

            for cid in expired:
                del self._conversations[cid]

            if expired:
                logger.info(f"Cleaned up {len(expired)} expired conversations")

    async def _cleanup_loop(self) -> None:
        """定期清理循环"""
        while True:
            try:
                await asyncio.sleep(60)  # 每分钟检查一次
                await self._cleanup_expired()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Cleanup error: {e}")

    @property
    def conversation_count(self) -> int:
        """当前会话数量"""
        return len(self._conversations)

    def get_stats(self) -> dict[str, Any]:
        """获取统计信息"""
        total_messages = sum(
            len(conv.messages) for conv in self._conversations.values()
        )

        return {
            "conversation_count": len(self._conversations),
            "total_messages": total_messages,
            "max_conversations": self.settings.memory_max_conversations,
            "max_turns_per_conversation": self.settings.memory_max_turns_per_conversation,
            "ttl_seconds": self.settings.memory_ttl_seconds,
        }
```

### 5.5 Agent 核心 (agent.py)

```python
"""
文件: src/ceo_agent/core/agent.py
职责: 协调各组件完成分析任务
"""

import logging
import time
from typing import Any
from uuid import uuid4

from ceo_agent.api.schemas import (
    AnalysisRequest,
    AnalysisResponse,
    AnalysisResult,
    AnalysisType,
    ChatRequest,
    ChatResponse,
    ResponseMetadata,
)
from ceo_agent.config import Settings
from ceo_agent.core.claude_client import ClaudeClient
from ceo_agent.core.memory import MemoryStore
from ceo_agent.core.prompt_manager import PromptManager
from ceo_agent.core.response_parser import ResponseParser
from ceo_agent.exceptions import AnalysisError

logger = logging.getLogger(__name__)


class AgentCore:
    """Agent 核心协调器

    职责：
    - 接收分析请求
    - 协调各组件工作
    - 管理会话状态
    - 返回结构化结果
    """

    def __init__(
        self,
        settings: Settings,
        claude_client: ClaudeClient,
        prompt_manager: PromptManager,
        response_parser: ResponseParser,
        memory_store: MemoryStore,
    ):
        self.settings = settings
        self.claude = claude_client
        self.prompts = prompt_manager
        self.parser = response_parser
        self.memory = memory_store

    async def analyze(self, request: AnalysisRequest) -> AnalysisResponse:
        """执行决策分析

        Args:
            request: 分析请求

        Returns:
            AnalysisResponse: 分析响应
        """
        start_time = time.time()
        analysis_id = str(uuid4())

        logger.info(
            f"Starting analysis {analysis_id}, type: {request.analysis_type}, "
            f"query length: {len(request.query)}"
        )

        try:
            # 1. 获取或创建会话
            conversation_id, conversation = await self.memory.get_or_create_conversation(
                request.conversation_id
            )

            # 2. 构建 Prompt
            system_prompt = self.prompts.get_system_prompt()
            user_prompt = self._build_user_prompt(request)

            # 3. 获取对话历史
            history = conversation.get_history()

            # 4. 调用 Claude API
            response_text, tokens_used = await self.claude.complete(
                system_prompt=system_prompt,
                user_message=user_prompt,
                conversation_history=history,
            )

            # 5. 保存对话
            await self.memory.add_message(conversation_id, "user", user_prompt)
            await self.memory.add_message(conversation_id, "assistant", response_text)

            # 6. 解析响应
            result = self.parser.parse(response_text)

            # 7. 构建响应
            execution_time = int((time.time() - start_time) * 1000)

            metadata = ResponseMetadata(
                model=self.settings.claude_model,
                tokens_used=tokens_used,
                execution_time_ms=execution_time,
            )

            response = AnalysisResponse.create_success(
                analysis_id=analysis_id,
                query=request.query,
                result=result,
                metadata=metadata,
            )

            # 添加会话 ID 到响应
            response.data["conversation_id"] = conversation_id

            logger.info(
                f"Analysis {analysis_id} completed in {execution_time}ms, "
                f"tokens: {tokens_used}"
            )

            return response

        except Exception as e:
            logger.error(f"Analysis {analysis_id} failed: {e}")
            raise AnalysisError(str(e), request.analysis_type.value)

    async def chat(self, request: ChatRequest) -> ChatResponse:
        """处理对话请求

        Args:
            request: 对话请求

        Returns:
            ChatResponse: 对话响应
        """
        start_time = time.time()

        # 获取或创建会话
        conversation_id, conversation = await self.memory.get_or_create_conversation(
            request.conversation_id
        )

        # 获取系统 Prompt
        system_prompt = self.prompts.get_system_prompt()

        # 获取历史
        history = conversation.get_history()

        # 调用 Claude
        response_text, tokens_used = await self.claude.complete(
            system_prompt=system_prompt,
            user_message=request.message,
            conversation_history=history,
        )

        # 保存消息
        await self.memory.add_message(conversation_id, "user", request.message)
        await self.memory.add_message(conversation_id, "assistant", response_text)

        execution_time = int((time.time() - start_time) * 1000)

        return ChatResponse(
            success=True,
            data={
                "conversation_id": conversation_id,
                "message": response_text,
            },
            metadata=ResponseMetadata(
                model=self.settings.claude_model,
                tokens_used=tokens_used,
                execution_time_ms=execution_time,
            ),
        )

    def _build_user_prompt(self, request: AnalysisRequest) -> str:
        """构建用户 Prompt"""
        # 根据分析类型选择模板变量
        template_data = {
            "query": request.query,
            "analysis_type": request.analysis_type.value,
        }

        # 添加上下文数据
        if request.context:
            template_data.update(request.context)

        # 获取对应的分析 Prompt
        prompt = self.prompts.get_analysis_prompt(
            analysis_type=request.analysis_type.value,
            data=template_data,
        )

        return prompt

    async def get_conversation_history(
        self,
        conversation_id: str,
    ) -> list[dict[str, str]]:
        """获取会话历史"""
        return await self.memory.get_history(conversation_id)

    async def clear_conversation(self, conversation_id: str) -> None:
        """清空会话"""
        await self.memory.delete_conversation(conversation_id)

    def get_stats(self) -> dict[str, Any]:
        """获取 Agent 统计信息"""
        return {
            "memory": self.memory.get_stats(),
            "total_tokens_used": self.claude.total_tokens_used,
            "available_templates": self.prompts.list_templates(),
        }
```

---

## 六、API 层实现

### 6.1 依赖注入 (dependencies.py)

```python
"""
文件: src/ceo_agent/api/dependencies.py
职责: FastAPI 依赖注入
"""

from functools import lru_cache

from ceo_agent.config import Settings, get_settings
from ceo_agent.core.agent import AgentCore
from ceo_agent.core.claude_client import ClaudeClient
from ceo_agent.core.memory import MemoryStore
from ceo_agent.core.prompt_manager import PromptManager
from ceo_agent.core.response_parser import ResponseParser


@lru_cache
def get_claude_client() -> ClaudeClient:
    """获取 Claude 客户端单例"""
    return ClaudeClient(get_settings())


@lru_cache
def get_prompt_manager() -> PromptManager:
    """获取 Prompt 管理器单例"""
    return PromptManager(get_settings())


@lru_cache
def get_response_parser() -> ResponseParser:
    """获取响应解析器单例"""
    return ResponseParser()


@lru_cache
def get_memory_store() -> MemoryStore:
    """获取内存存储单例"""
    return MemoryStore(get_settings())


@lru_cache
def get_agent_core() -> AgentCore:
    """获取 Agent 核心单例"""
    return AgentCore(
        settings=get_settings(),
        claude_client=get_claude_client(),
        prompt_manager=get_prompt_manager(),
        response_parser=get_response_parser(),
        memory_store=get_memory_store(),
    )
```

### 6.2 路由定义 (routes.py)

```python
"""
文件: src/ceo_agent/api/routes.py
职责: 定义所有 API 路由
"""

import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from ceo_agent import __version__
from ceo_agent.api.dependencies import get_agent_core, get_memory_store
from ceo_agent.api.schemas import (
    AnalysisRequest,
    AnalysisResponse,
    ChatRequest,
    ChatResponse,
    ErrorResponse,
    ErrorDetail,
    HealthResponse,
    InvestmentAnalysisRequest,
    RiskAssessmentRequest,
    StrategyPlanningRequest,
    AnalysisType,
    ResponseMetadata,
)
from ceo_agent.core.agent import AgentCore
from ceo_agent.core.memory import MemoryStore
from ceo_agent.exceptions import (
    CEOAgentError,
    ConversationNotFoundError,
    ClaudeAPIError,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["CEOAgent API"])


# ===== 健康检查 =====

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="健康检查",
    description="检查服务状态",
)
async def health_check(
    memory: Annotated[MemoryStore, Depends(get_memory_store)],
) -> HealthResponse:
    """健康检查端点"""
    return HealthResponse(
        status="healthy",
        version=__version__,
        checks={
            "memory_store": True,
            "conversation_count": memory.conversation_count,
        },
    )


# ===== 通用分析 =====

@router.post(
    "/analyze",
    response_model=AnalysisResponse,
    responses={
        400: {"model": ErrorResponse, "description": "请求参数错误"},
        500: {"model": ErrorResponse, "description": "服务器内部错误"},
    },
    summary="决策分析",
    description="执行决策分析，返回结构化分析结果",
)
async def analyze(
    request: AnalysisRequest,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> AnalysisResponse:
    """通用决策分析端点"""
    try:
        return await agent.analyze(request)
    except CEOAgentError as e:
        logger.error(f"Analysis error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.to_dict(),
        )
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"code": "INTERNAL_ERROR", "message": str(e)},
        )


# ===== 投资决策分析 =====

@router.post(
    "/decision/investment",
    response_model=AnalysisResponse,
    summary="投资决策分析",
    description="专门针对投资决策的分析",
)
async def investment_analysis(
    request: InvestmentAnalysisRequest,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> AnalysisResponse:
    """投资决策分析端点"""
    # 转换为通用请求
    analysis_request = AnalysisRequest(
        query=request.query,
        analysis_type=AnalysisType.INVESTMENT,
        context={
            "company_financials": {
                k: v.model_dump() for k, v in request.company_financials.items()
            },
            "decision_type": request.decision_type,
            "budget_range": request.budget_range,
            "risk_tolerance": request.risk_tolerance.value,
            "competitor_data": request.competitor_data,
            "market_report": request.market_report,
            "constraints": request.constraints,
        },
        conversation_id=request.conversation_id,
    )

    return await agent.analyze(analysis_request)


# ===== 风险评估 =====

@router.post(
    "/decision/risk",
    response_model=AnalysisResponse,
    summary="风险评估",
    description="企业风险综合评估",
)
async def risk_assessment(
    request: RiskAssessmentRequest,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> AnalysisResponse:
    """风险评估端点"""
    analysis_request = AnalysisRequest(
        query=request.query,
        analysis_type=AnalysisType.RISK,
        context={
            "company_profile": request.company_profile.model_dump(),
            "financial_health": request.financial_health,
            "risk_areas": request.risk_areas,
            "external_factors": request.external_factors,
            "historical_incidents": request.historical_incidents,
            "risk_tolerance": request.risk_tolerance.value,
        },
        conversation_id=request.conversation_id,
    )

    return await agent.analyze(analysis_request)


# ===== 战略规划 =====

@router.post(
    "/decision/strategy",
    response_model=AnalysisResponse,
    summary="战略规划",
    description="年度战略规划建议",
)
async def strategy_planning(
    request: StrategyPlanningRequest,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> AnalysisResponse:
    """战略规划端点"""
    analysis_request = AnalysisRequest(
        query=request.query,
        analysis_type=AnalysisType.STRATEGY,
        context={
            "business_status": request.business_status,
            "strategic_goals": request.strategic_goals,
            "constraints": request.constraints,
            "swot": request.swot,
            "market_analysis": request.market_analysis,
            "competitor_info": request.competitor_info,
            "time_horizon": request.time_horizon,
        },
        conversation_id=request.conversation_id,
    )

    return await agent.analyze(analysis_request)


# ===== 对话 =====

@router.post(
    "/chat",
    response_model=ChatResponse,
    summary="对话",
    description="自然语言对话接口",
)
async def chat(
    request: ChatRequest,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> ChatResponse:
    """对话端点"""
    try:
        return await agent.chat(request)
    except CEOAgentError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.to_dict(),
        )


# ===== 会话管理 =====

@router.get(
    "/conversations/{conversation_id}/history",
    summary="获取会话历史",
    description="获取指定会话的对话历史",
)
async def get_conversation_history(
    conversation_id: str,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> dict:
    """获取会话历史"""
    try:
        history = await agent.get_conversation_history(conversation_id)
        return {"conversation_id": conversation_id, "messages": history}
    except ConversationNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.to_dict(),
        )


@router.delete(
    "/conversations/{conversation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="删除会话",
    description="删除指定会话",
)
async def delete_conversation(
    conversation_id: str,
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> None:
    """删除会话"""
    await agent.clear_conversation(conversation_id)


# ===== 统计信息 =====

@router.get(
    "/stats",
    summary="获取统计信息",
    description="获取 Agent 运行统计",
)
async def get_stats(
    agent: Annotated[AgentCore, Depends(get_agent_core)],
) -> dict:
    """获取统计信息"""
    return agent.get_stats()
```

### 6.3 应用入口 (main.py)

```python
"""
文件: src/ceo_agent/main.py
职责: FastAPI 应用入口
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from ceo_agent import __version__
from ceo_agent.api.dependencies import get_memory_store
from ceo_agent.api.routes import router
from ceo_agent.config import get_settings
from ceo_agent.exceptions import CEOAgentError

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    settings = get_settings()
    logger.info(f"Starting CEOAgent v{__version__} in {settings.app_env} mode")

    # 启动内存存储清理任务
    memory_store = get_memory_store()
    await memory_store.start()

    yield

    # 停止清理任务
    await memory_store.stop()
    logger.info("CEOAgent shutdown complete")


def create_app() -> FastAPI:
    """创建 FastAPI 应用"""
    settings = get_settings()

    app = FastAPI(
        title="CEOAgent API",
        description="AI-powered CEO decision support system",
        version=__version__,
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        lifespan=lifespan,
    )

    # CORS 中间件
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if settings.debug else [],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 注册路由
    app.include_router(router)

    # 全局异常处理
    @app.exception_handler(CEOAgentError)
    async def ceo_agent_error_handler(
        request: Request,
        exc: CEOAgentError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "error": exc.to_dict(),
            },
        )

    @app.exception_handler(Exception)
    async def general_error_handler(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        logger.exception(f"Unhandled error: {exc}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "An unexpected error occurred",
                },
            },
        )

    return app


# 创建应用实例
app = create_app()


def main() -> None:
    """命令行入口"""
    import uvicorn

    settings = get_settings()
    uvicorn.run(
        "ceo_agent.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )


if __name__ == "__main__":
    main()
```

### 6.4 包初始化 (__init__.py)

```python
"""
文件: src/ceo_agent/__init__.py
"""

__version__ = "0.1.0"
__author__ = "CEOAgent Team"
```

---

## 七、Prompt 模板

### 7.1 系统 Prompt (prompts/v1/system.txt)

```text
You are an expert CEO decision support AI assistant with deep expertise in:
- Strategic planning and business development
- Financial analysis and investment evaluation
- Risk assessment and mitigation
- Market analysis and competitive intelligence

Your role is to help CEOs make informed, data-driven decisions by providing:
1. Comprehensive situation analysis
2. Quantitative risk assessment (1-10 scale)
3. Multiple strategic options with pros/cons
4. Clear, actionable recommendations

## Response Guidelines

### Structure
Always organize your response with clear sections:
- **Situation Analysis**: Key findings from the provided data (max 150 words)
- **Risk Assessment**: Overall score (1-10) and specific risk factors
- **Recommendations**: 2-4 options with detailed analysis
- **Final Recommendation**: Your top choice with reasoning

### Risk Scoring
- 1-3: Low risk - Proceed with standard precautions
- 4-5: Medium risk - Proceed with enhanced monitoring
- 6-7: High risk - Proceed with caution and mitigation plans
- 8-10: Critical risk - Consider alternatives or delay

### Quality Standards
- Be data-driven: Reference specific numbers from the input
- Be actionable: Include concrete next steps and timelines
- Be balanced: Present both opportunities and risks
- Be concise: Focus on what matters most for the decision

### Output Format
When possible, structure your response as JSON for easy parsing:
```json
{
  "situation_analysis": {
    "summary": "...",
    "key_findings": ["...", "..."]
  },
  "risk_assessment": {
    "overall_score": 7,
    "risk_level": "high",
    "risk_factors": [
      {"name": "...", "level": "high", "reason": "..."}
    ]
  },
  "recommendations": [
    {
      "title": "Option A: ...",
      "description": "...",
      "risk_level": "medium",
      "pros": ["..."],
      "cons": ["..."],
      "action_steps": ["..."]
    }
  ],
  "final_recommendation": {
    "choice": "Option A",
    "reasoning": "..."
  }
}
```
```

### 7.2 投资决策模板 (prompts/v1/investment_decision.txt)

```text
## Investment Decision Analysis

You are analyzing an investment decision with the following context:

### Query
${query}

### Financial Data
${company_financials}

### Decision Parameters
- Decision Type: ${decision_type}
- Budget Range: ${budget_range}
- Risk Tolerance: ${risk_tolerance}

### Market Context
${market_report}

### Competitor Information
${competitor_data}

### Constraints
${constraints}

---

Please provide a comprehensive investment analysis including:

1. **Situation Analysis** (max 150 words)
   - Current financial health assessment
   - Market position evaluation
   - Key trends affecting this decision

2. **Risk Assessment**
   - Overall risk score (1-10)
   - Financial risks (cash flow, debt, profitability)
   - Market risks (competition, timing, demand)
   - Execution risks (capability, resources)

3. **Investment Options** (provide 2-4 options)
   For each option include:
   - Investment amount and structure
   - Expected ROI and timeline
   - Risk level (low/medium/high)
   - Pros and cons
   - Specific action steps with timeline

4. **Final Recommendation**
   - Your recommended option
   - Key reasoning based on the data
   - Critical success factors
   - Contingency considerations

Remember to consider the stated risk tolerance (${risk_tolerance}) when making your recommendation.
```

### 7.3 风险评估模板 (prompts/v1/risk_assessment.txt)

```text
## Enterprise Risk Assessment

You are conducting a comprehensive risk assessment with the following context:

### Query
${query}

### Company Profile
${company_profile}

### Financial Health Indicators
${financial_health}

### Risk Areas to Evaluate
${risk_areas}

### External Factors
${external_factors}

### Historical Incidents
${historical_incidents}

### Risk Tolerance
${risk_tolerance}

---

Please provide a thorough risk assessment including:

1. **Executive Summary**
   - Overall risk score (1-10)
   - Risk level classification (low/medium/high/critical)
   - Top 3 priority risks requiring immediate attention

2. **Risk Category Analysis**
   For each risk area, provide:
   - Category score (1-10)
   - Key risk factors
   - Probability assessment (low/medium/high)
   - Impact assessment (minor/moderate/severe/catastrophic)
   - Trend direction (improving/stable/worsening)

3. **Risk Matrix**
   Classify identified risks into:
   - High probability, High impact (immediate action required)
   - High probability, Low impact (monitor closely)
   - Low probability, High impact (contingency planning)
   - Low probability, Low impact (accept and monitor)

4. **Mitigation Strategies**
   For each major risk, provide:
   - Specific mitigation actions
   - Priority level (urgent/high/medium/low)
   - Timeline for implementation
   - Required resources
   - Expected risk reduction

5. **Monitoring Plan**
   - Key risk indicators (KRIs) to track
   - Recommended review frequency
   - Escalation triggers and thresholds
```

### 7.4 战略规划模板 (prompts/v1/strategy_planning.txt)

```text
## Strategic Planning Analysis

You are developing strategic recommendations with the following context:

### Query
${query}

### Current Business Status
${business_status}

### Strategic Goals
${strategic_goals}

### SWOT Analysis
${swot}

### Market Analysis
${market_analysis}

### Competitive Landscape
${competitor_info}

### Constraints
${constraints}

### Planning Horizon
${time_horizon}

---

Please provide strategic planning recommendations including:

1. **Strategic Assessment**
   - Current market position analysis
   - Gap analysis (current state vs. goals)
   - Key challenges to address
   - Key opportunities to leverage

2. **Recommended Strategy**
   - Strategy name and description
   - Strategic pillars (3-5 focus areas)
   - For each pillar:
     * Objectives
     * Key initiatives
     * Success metrics (KPIs)

3. **Alternative Strategies** (2-3 options)
   For each alternative:
   - Strategy description
   - Pros and cons
   - Risk level
   - Resource requirements
   - Why it may or may not be suitable

4. **Implementation Roadmap**
   Quarterly breakdown:
   - Q1: Foundation initiatives
   - Q2: Growth initiatives
   - Q3: Optimization initiatives
   - Q4: Evaluation and adjustment

5. **Resource Requirements**
   - Budget estimates
   - Headcount needs
   - Technology investments
   - External support (consultants, partners)

6. **Success Metrics**
   - Primary KPIs with targets
   - Secondary metrics
   - Measurement frequency
   - Review milestones

Consider the stated constraints and time horizon when developing your recommendations.
```

---

## 八、测试规范

### 8.1 测试配置 (tests/conftest.py)

```python
"""
文件: tests/conftest.py
职责: pytest fixtures 和测试配置
"""

import asyncio
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient

from ceo_agent.config import Settings
from ceo_agent.core.agent import AgentCore
from ceo_agent.core.claude_client import ClaudeClient
from ceo_agent.core.memory import MemoryStore
from ceo_agent.core.prompt_manager import PromptManager
from ceo_agent.core.response_parser import ResponseParser
from ceo_agent.main import app


@pytest.fixture(scope="session")
def event_loop():
    """创建事件循环"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def test_settings() -> Settings:
    """测试配置"""
    return Settings(
        anthropic_api_key="sk-ant-test-key-for-testing-only",
        claude_model="claude-sonnet-4-20250514",
        app_env="development",
        debug=True,
        memory_max_conversations=10,
        memory_max_turns_per_conversation=5,
        memory_ttl_seconds=60,
    )


@pytest.fixture
def mock_claude_response() -> str:
    """模拟 Claude 响应"""
    return """
```json
{
  "situation_analysis": {
    "summary": "Test situation analysis summary",
    "key_findings": ["Finding 1", "Finding 2"]
  },
  "risk_assessment": {
    "overall_score": 6,
    "risk_level": "medium",
    "risk_factors": [
      {"name": "Test Risk", "level": "medium", "reason": "Test reason"}
    ]
  },
  "recommendations": [
    {
      "title": "Option A: Test Option",
      "description": "Test description",
      "risk_level": "medium",
      "pros": ["Pro 1"],
      "cons": ["Con 1"],
      "action_steps": ["Step 1", "Step 2"]
    }
  ],
  "final_recommendation": {
    "choice": "Option A",
    "reasoning": "Test reasoning"
  }
}
```
"""


@pytest.fixture
def mock_claude_client(mock_claude_response: str) -> ClaudeClient:
    """模拟 Claude 客户端"""
    mock = MagicMock(spec=ClaudeClient)
    mock.complete = AsyncMock(return_value=(mock_claude_response, 500))
    mock.total_tokens_used = 500
    return mock


@pytest.fixture
def prompt_manager(test_settings: Settings) -> PromptManager:
    """Prompt 管理器"""
    return PromptManager(test_settings)


@pytest.fixture
def response_parser() -> ResponseParser:
    """响应解析器"""
    return ResponseParser()


@pytest.fixture
async def memory_store(test_settings: Settings) -> AsyncGenerator[MemoryStore, None]:
    """内存存储"""
    store = MemoryStore(test_settings)
    await store.start()
    yield store
    await store.stop()


@pytest.fixture
async def agent_core(
    test_settings: Settings,
    mock_claude_client: ClaudeClient,
    prompt_manager: PromptManager,
    response_parser: ResponseParser,
    memory_store: MemoryStore,
) -> AgentCore:
    """Agent 核心"""
    return AgentCore(
        settings=test_settings,
        claude_client=mock_claude_client,
        prompt_manager=prompt_manager,
        response_parser=response_parser,
        memory_store=memory_store,
    )


@pytest.fixture
def test_client() -> TestClient:
    """同步测试客户端"""
    return TestClient(app)


@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    """异步测试客户端"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
```

### 8.2 单元测试示例 (tests/test_response_parser.py)

```python
"""
文件: tests/test_response_parser.py
"""

import pytest

from ceo_agent.api.schemas import RiskLevel
from ceo_agent.core.response_parser import ResponseParser
from ceo_agent.exceptions import ResponseParseError


class TestResponseParser:
    """响应解析器测试"""

    @pytest.fixture
    def parser(self) -> ResponseParser:
        return ResponseParser()

    def test_parse_json_response(self, parser: ResponseParser):
        """测试解析 JSON 格式响应"""
        response = """
Here is my analysis:

```json
{
  "situation_analysis": {
    "summary": "Test summary",
    "key_findings": ["Finding 1", "Finding 2"]
  },
  "risk_assessment": {
    "overall_score": 7,
    "risk_level": "high",
    "risk_factors": [
      {"name": "Risk 1", "level": "high", "reason": "Reason 1"}
    ]
  },
  "recommendations": [
    {
      "title": "Option A",
      "description": "Description A",
      "risk_level": "medium",
      "pros": ["Pro 1"],
      "cons": ["Con 1"],
      "action_steps": ["Step 1"]
    }
  ],
  "final_recommendation": {
    "choice": "Option A",
    "reasoning": "Best option"
  }
}
```
"""
        result = parser.parse(response)

        assert result.situation_analysis.summary == "Test summary"
        assert len(result.situation_analysis.key_findings) == 2
        assert result.risk_assessment.overall_score == 7
        assert result.risk_assessment.risk_level == RiskLevel.HIGH
        assert len(result.recommendations) == 1
        assert result.final_recommendation.choice == "Option A"

    def test_parse_text_response(self, parser: ResponseParser):
        """测试解析纯文本响应"""
        response = """
## Situation Analysis

This is a test summary of the current situation.

- Finding 1
- Finding 2

## Risk Assessment

Risk Score: 6

- Cash flow risk: High due to negative trends
- Market risk: Medium due to competition

## Recommendations

### Option A: Conservative Approach

A conservative approach to the situation.

Pros:
- Low risk

Cons:
- Lower returns

## Final Recommendation

Recommend Option A because it aligns with risk tolerance.
"""
        result = parser.parse(response)

        assert result.situation_analysis.summary
        assert result.risk_assessment.overall_score == 6
        assert result.final_recommendation is not None

    def test_score_to_level(self, parser: ResponseParser):
        """测试评分转风险等级"""
        assert parser._score_to_level(1) == RiskLevel.LOW
        assert parser._score_to_level(3) == RiskLevel.LOW
        assert parser._score_to_level(4) == RiskLevel.MEDIUM
        assert parser._score_to_level(5) == RiskLevel.MEDIUM
        assert parser._score_to_level(6) == RiskLevel.HIGH
        assert parser._score_to_level(7) == RiskLevel.HIGH
        assert parser._score_to_level(8) == RiskLevel.CRITICAL
        assert parser._score_to_level(10) == RiskLevel.CRITICAL
```

### 8.3 API 测试示例 (tests/test_api.py)

```python
"""
文件: tests/test_api.py
"""

import pytest
from fastapi.testclient import TestClient


class TestHealthEndpoint:
    """健康检查端点测试"""

    def test_health_check(self, test_client: TestClient):
        """测试健康检查"""
        response = test_client.get("/api/v1/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data


class TestAnalyzeEndpoint:
    """分析端点测试"""

    def test_analyze_success(self, test_client: TestClient):
        """测试成功分析"""
        response = test_client.post(
            "/api/v1/analyze",
            json={
                "query": "Should we invest $5M in expanding our cloud infrastructure?",
                "analysis_type": "investment",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data
        assert "metadata" in data

    def test_analyze_invalid_query(self, test_client: TestClient):
        """测试无效查询"""
        response = test_client.post(
            "/api/v1/analyze",
            json={
                "query": "short",  # 太短
                "analysis_type": "general",
            },
        )

        assert response.status_code == 422  # Validation error


class TestChatEndpoint:
    """对话端点测试"""

    def test_chat_new_conversation(self, test_client: TestClient):
        """测试新对话"""
        response = test_client.post(
            "/api/v1/chat",
            json={"message": "Hello, I need help with a strategic decision."},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "conversation_id" in data["data"]

    def test_chat_continue_conversation(self, test_client: TestClient):
        """测试继续对话"""
        # 第一条消息
        response1 = test_client.post(
            "/api/v1/chat",
            json={"message": "Hello"},
        )
        conversation_id = response1.json()["data"]["conversation_id"]

        # 第二条消息
        response2 = test_client.post(
            "/api/v1/chat",
            json={
                "message": "Tell me more about risk assessment.",
                "conversation_id": conversation_id,
            },
        )

        assert response2.status_code == 200
        assert response2.json()["data"]["conversation_id"] == conversation_id
```

---

## 九、评估系统

### 9.1 测试用例 (evaluation/test_cases/investment_cases.json)

```json
{
  "test_cases": [
    {
      "id": "INV-001",
      "name": "Standard Investment Decision",
      "description": "A typical Q4 investment decision scenario",
      "input": {
        "query": "Should we invest $5-10M in expanding our cloud infrastructure given Q3 performance?",
        "analysis_type": "investment",
        "context": {
          "company_financials": {
            "Q1": {"revenue": 12000000, "profit": 1800000, "cash_flow": 1500000},
            "Q2": {"revenue": 13500000, "profit": 2100000, "cash_flow": 1800000},
            "Q3": {"revenue": 11000000, "profit": 950000, "cash_flow": 400000}
          },
          "decision_type": "infrastructure_expansion",
          "budget_range": "5M-10M CNY",
          "risk_tolerance": "moderate"
        }
      },
      "expected": {
        "has_situation_analysis": true,
        "has_risk_assessment": true,
        "risk_score_range": [5, 8],
        "min_recommendations": 2,
        "has_final_recommendation": true,
        "must_include_keywords": ["cash flow", "Q3", "infrastructure"],
        "recommendations_have_action_steps": true
      }
    },
    {
      "id": "INV-002",
      "name": "High Risk Investment",
      "description": "Investment decision with significant cash flow concerns",
      "input": {
        "query": "We're considering acquiring a competitor for $20M. Our cash reserves are $8M and we'd need to take on debt.",
        "analysis_type": "investment",
        "context": {
          "company_financials": {
            "Q1": {"revenue": 5000000, "profit": 200000, "cash_flow": -100000},
            "Q2": {"revenue": 4800000, "profit": 150000, "cash_flow": -200000},
            "Q3": {"revenue": 4500000, "profit": 50000, "cash_flow": -300000}
          },
          "decision_type": "acquisition",
          "budget_range": "20M CNY",
          "risk_tolerance": "conservative"
        }
      },
      "expected": {
        "has_situation_analysis": true,
        "has_risk_assessment": true,
        "risk_score_range": [7, 10],
        "min_recommendations": 2,
        "has_final_recommendation": true,
        "must_include_keywords": ["debt", "cash", "risk"],
        "should_warn_about_risk": true
      }
    }
  ]
}
```

### 9.2 评估脚本 (evaluation/run_eval.py)

```python
"""
文件: evaluation/run_eval.py
职责: 运行评估测试并生成报告
"""

import asyncio
import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class EvaluationResult:
    """评估结果"""
    test_case_id: str
    test_case_name: str
    passed: bool
    score: float
    details: dict[str, Any]
    errors: list[str]


class Evaluator:
    """评估器"""

    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.client = httpx.AsyncClient(base_url=base_url, timeout=300.0)

    async def close(self):
        await self.client.aclose()

    async def evaluate_case(self, test_case: dict) -> EvaluationResult:
        """评估单个测试用例"""
        test_id = test_case["id"]
        test_name = test_case["name"]
        errors = []
        score = 0.0
        details = {}

        try:
            # 发送请求
            response = await self.client.post(
                "/api/v1/analyze",
                json=test_case["input"],
            )

            if response.status_code != 200:
                errors.append(f"API returned {response.status_code}")
                return EvaluationResult(
                    test_case_id=test_id,
                    test_case_name=test_name,
                    passed=False,
                    score=0.0,
                    details={"response_code": response.status_code},
                    errors=errors,
                )

            data = response.json()
            result = data.get("data", {}).get("result", {})
            expected = test_case["expected"]

            # 评估完整性 (40分)
            completeness_score, completeness_details = self._evaluate_completeness(
                result, expected
            )
            score += completeness_score
            details["completeness"] = completeness_details

            # 评估准确性 (30分)
            accuracy_score, accuracy_details = self._evaluate_accuracy(
                result, expected
            )
            score += accuracy_score
            details["accuracy"] = accuracy_details

            # 评估可行性 (30分)
            feasibility_score, feasibility_details = self._evaluate_feasibility(
                result, expected
            )
            score += feasibility_score
            details["feasibility"] = feasibility_details

            passed = score >= 60.0

        except Exception as e:
            errors.append(str(e))
            passed = False

        return EvaluationResult(
            test_case_id=test_id,
            test_case_name=test_name,
            passed=passed,
            score=score,
            details=details,
            errors=errors,
        )

    def _evaluate_completeness(
        self,
        result: dict,
        expected: dict,
    ) -> tuple[float, dict]:
        """评估完整性 (40分)"""
        score = 0.0
        details = {}

        # 态势分析 (10分)
        if expected.get("has_situation_analysis"):
            situation = result.get("situation_analysis", {})
            if situation.get("summary"):
                score += 5.0
                details["situation_summary"] = "pass"
            else:
                details["situation_summary"] = "missing"

            if situation.get("key_findings"):
                score += 5.0
                details["situation_findings"] = "pass"
            else:
                details["situation_findings"] = "missing"

        # 风险评估 (10分)
        if expected.get("has_risk_assessment"):
            risk = result.get("risk_assessment", {})
            if risk.get("overall_score") is not None:
                score += 5.0
                details["risk_score"] = "pass"
            else:
                details["risk_score"] = "missing"

            if risk.get("risk_factors"):
                score += 5.0
                details["risk_factors"] = "pass"
            else:
                details["risk_factors"] = "missing"

        # 推荐方案 (10分)
        recommendations = result.get("recommendations", [])
        min_recs = expected.get("min_recommendations", 2)
        if len(recommendations) >= min_recs:
            score += 10.0
            details["recommendations_count"] = f"pass ({len(recommendations)}/{min_recs})"
        else:
            details["recommendations_count"] = f"fail ({len(recommendations)}/{min_recs})"

        # 最终推荐 (10分)
        if expected.get("has_final_recommendation"):
            final = result.get("final_recommendation", {})
            if final.get("choice") and final.get("reasoning"):
                score += 10.0
                details["final_recommendation"] = "pass"
            else:
                details["final_recommendation"] = "missing"

        return score, details

    def _evaluate_accuracy(
        self,
        result: dict,
        expected: dict,
    ) -> tuple[float, dict]:
        """评估准确性 (30分)"""
        score = 0.0
        details = {}

        # 风险评分范围 (15分)
        risk = result.get("risk_assessment", {})
        actual_score = risk.get("overall_score")
        score_range = expected.get("risk_score_range")

        if actual_score is not None and score_range:
            if score_range[0] <= actual_score <= score_range[1]:
                score += 15.0
                details["risk_score_range"] = f"pass ({actual_score} in {score_range})"
            else:
                details["risk_score_range"] = f"fail ({actual_score} not in {score_range})"

        # 关键词包含 (15分)
        keywords = expected.get("must_include_keywords", [])
        if keywords:
            # 将结果转为字符串搜索
            result_text = json.dumps(result).lower()
            found = sum(1 for kw in keywords if kw.lower() in result_text)
            keyword_score = (found / len(keywords)) * 15.0
            score += keyword_score
            details["keywords"] = f"{found}/{len(keywords)} keywords found"

        return score, details

    def _evaluate_feasibility(
        self,
        result: dict,
        expected: dict,
    ) -> tuple[float, dict]:
        """评估可行性 (30分)"""
        score = 0.0
        details = {}

        # 行动步骤 (15分)
        if expected.get("recommendations_have_action_steps"):
            recommendations = result.get("recommendations", [])
            has_steps = any(
                rec.get("action_steps") and len(rec.get("action_steps", [])) >= 2
                for rec in recommendations
            )
            if has_steps:
                score += 15.0
                details["action_steps"] = "pass"
            else:
                details["action_steps"] = "missing or insufficient"

        # 最终推荐有理由 (15分)
        final = result.get("final_recommendation", {})
        if final.get("reasoning") and len(final.get("reasoning", "")) > 50:
            score += 15.0
            details["reasoning"] = "pass"
        else:
            details["reasoning"] = "missing or too short"

        return score, details


async def main():
    """主函数"""
    # 加载测试用例
    test_cases_dir = Path(__file__).parent / "test_cases"
    all_results = []

    evaluator = Evaluator()

    try:
        for test_file in test_cases_dir.glob("*.json"):
            logger.info(f"Loading test cases from {test_file}")

            with open(test_file) as f:
                data = json.load(f)

            for test_case in data.get("test_cases", []):
                logger.info(f"Evaluating: {test_case['id']} - {test_case['name']}")
                result = await evaluator.evaluate_case(test_case)
                all_results.append(result)

                status = "PASS" if result.passed else "FAIL"
                logger.info(f"  Result: {status} (Score: {result.score:.1f})")
                if result.errors:
                    logger.error(f"  Errors: {result.errors}")

    finally:
        await evaluator.close()

    # 生成报告
    print("\n" + "=" * 60)
    print("EVALUATION REPORT")
    print("=" * 60)

    total_cases = len(all_results)
    passed_cases = sum(1 for r in all_results if r.passed)
    avg_score = sum(r.score for r in all_results) / total_cases if total_cases else 0

    print(f"\nTotal Test Cases: {total_cases}")
    print(f"Passed: {passed_cases}")
    print(f"Failed: {total_cases - passed_cases}")
    print(f"Pass Rate: {passed_cases / total_cases * 100:.1f}%")
    print(f"Average Score: {avg_score:.1f}")

    print("\nDetailed Results:")
    print("-" * 60)

    for result in all_results:
        status = "✓ PASS" if result.passed else "✗ FAIL"
        print(f"\n{result.test_case_id}: {result.test_case_name}")
        print(f"  Status: {status}")
        print(f"  Score: {result.score:.1f}/100")

        for category, detail in result.details.items():
            print(f"  {category}: {detail}")

        if result.errors:
            print(f"  Errors: {result.errors}")

    # 保存报告
    report = {
        "summary": {
            "total_cases": total_cases,
            "passed": passed_cases,
            "failed": total_cases - passed_cases,
            "pass_rate": passed_cases / total_cases * 100 if total_cases else 0,
            "average_score": avg_score,
        },
        "results": [
            {
                "id": r.test_case_id,
                "name": r.test_case_name,
                "passed": r.passed,
                "score": r.score,
                "details": r.details,
                "errors": r.errors,
            }
            for r in all_results
        ],
    }

    report_path = Path(__file__).parent / "evaluation_report.json"
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)

    logger.info(f"\nReport saved to {report_path}")

    # 返回退出码
    return 0 if passed_cases == total_cases else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
```

---

## 十、验收清单

### 10.1 Phase 0 完成标准

| 项目 | 状态 | 验证方法 |
|------|------|---------|
| 场景定义 | ✅ | `scenarios/*.md` 文件存在 |
| Prompt 模板 | ⬜ | `prompts/v1/*.txt` 文件存在 |
| 评估用例 | ⬜ | `evaluation/test_cases/*.json` 至少 10 个用例 |
| 手动验证 | ⬜ | 在 claude.ai 中验证通过 |

### 10.2 Phase 1 完成标准

| 项目 | 标准 | 验证方法 |
|------|------|---------|
| 服务启动 | 无错误 | `uvicorn src.ceo_agent.main:app` |
| 健康检查 | 200 OK | `curl localhost:8000/api/v1/health` |
| 分析接口 | 返回结构化结果 | `curl -X POST localhost:8000/api/v1/analyze` |
| 单元测试 | 全部通过 | `pytest` |
| 覆盖率 | > 80% | `pytest --cov=src/ceo_agent` |
| 评估得分 | > 60% | `python evaluation/run_eval.py` |
| API 文档 | 可访问 | `http://localhost:8000/docs` |

### 10.3 开发检查清单

```bash
# 1. 创建目录结构
mkdir -p src/ceo_agent/core src/ceo_agent/api
mkdir -p prompts/v1
mkdir -p tests
mkdir -p evaluation/test_cases

# 2. 创建所有源文件
touch src/ceo_agent/__init__.py
touch src/ceo_agent/main.py
touch src/ceo_agent/config.py
touch src/ceo_agent/exceptions.py
touch src/ceo_agent/core/__init__.py
touch src/ceo_agent/core/agent.py
touch src/ceo_agent/core/claude_client.py
touch src/ceo_agent/core/prompt_manager.py
touch src/ceo_agent/core/response_parser.py
touch src/ceo_agent/core/memory.py
touch src/ceo_agent/api/__init__.py
touch src/ceo_agent/api/routes.py
touch src/ceo_agent/api/schemas.py
touch src/ceo_agent/api/dependencies.py

# 3. 创建 Prompt 模板
touch prompts/v1/system.txt
touch prompts/v1/investment_decision.txt
touch prompts/v1/risk_assessment.txt
touch prompts/v1/strategy_planning.txt

# 4. 创建测试文件
touch tests/__init__.py
touch tests/conftest.py
touch tests/test_claude_client.py
touch tests/test_prompt_manager.py
touch tests/test_response_parser.py
touch tests/test_agent.py
touch tests/test_api.py

# 5. 创建评估文件
touch evaluation/test_cases/investment_cases.json
touch evaluation/test_cases/risk_cases.json
touch evaluation/test_cases/strategy_cases.json
touch evaluation/run_eval.py

# 6. 运行测试
pytest -v

# 7. 启动服务
uvicorn src.ceo_agent.main:app --reload

# 8. 运行评估
python evaluation/run_eval.py
```

---

## 十一、API 调用示例

### 11.1 健康检查

```bash
curl http://localhost:8000/api/v1/health
```

### 11.2 通用分析

```bash
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Should we invest $5M in expanding our cloud infrastructure?",
    "analysis_type": "investment",
    "context": {
      "budget_range": "5-10M",
      "risk_tolerance": "moderate"
    }
  }'
```

### 11.3 投资决策分析

```bash
curl -X POST http://localhost:8000/api/v1/decision/investment \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Evaluate Q4 expansion investment opportunity",
    "company_financials": {
      "Q1": {"revenue": 12000000, "profit": 1800000, "cash_flow": 1500000},
      "Q2": {"revenue": 13500000, "profit": 2100000, "cash_flow": 1800000},
      "Q3": {"revenue": 11000000, "profit": 950000, "cash_flow": 400000}
    },
    "decision_type": "infrastructure_expansion",
    "budget_range": "5M-10M CNY",
    "risk_tolerance": "moderate"
  }'
```

### 11.4 对话

```bash
# 开始新对话
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "I need help evaluating a potential acquisition."}'

# 继续对话
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "The target company has $10M revenue but negative cash flow.",
    "conversation_id": "uuid-from-previous-response"
  }'
```

---

**文档版本**: 1.0
**最后更新**: 2025-01-11
**适用阶段**: Phase 1 MVP
