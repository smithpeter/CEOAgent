# CEOAgent 后端开发规范

> **文档版本**：v1.0
> **适用阶段**：Phase 1 MVP
> **最后更新**：2025-01-12

---

## 一、总体架构

### 1.1 模块结构

```
src/ceo_agent/
├── __init__.py              # 包初始化，导出版本号
├── main.py                  # FastAPI 应用入口
├── config.py                # 配置管理（环境变量）
├── exceptions.py            # 自定义异常类
├── core/                    # 核心业务逻辑
│   ├── __init__.py
│   ├── agent.py             # AgentCore - 核心编排器
│   ├── claude_client.py     # Claude API 客户端
│   ├── prompt_manager.py    # Prompt 模板管理
│   ├── response_parser.py   # 响应解析器
│   └── memory.py            # 会话记忆存储
├── api/                     # API 层
│   ├── __init__.py
│   ├── routes.py            # 路由定义
│   ├── schemas.py           # 请求/响应 Pydantic 模型
│   └── dependencies.py      # FastAPI 依赖注入
└── utils/                   # 工具函数
    ├── __init__.py
    └── logging.py           # 日志配置
```

### 1.2 依赖关系图

```
┌─────────────────────────────────────────────────────────────┐
│                        main.py                               │
│                    (FastAPI App)                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      api/routes.py                           │
│                   (HTTP 端点定义)                            │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  api/schemas.py  │ │ dependencies │ │   exceptions.py  │
│  (数据模型)      │ │  (依赖注入)  │ │    (异常处理)    │
└──────────────────┘ └──────────────┘ └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     core/agent.py                            │
│                     (AgentCore)                              │
│         ┌─────────────────────────────────────┐             │
│         │  analyze(query, context) -> Result  │             │
│         └─────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────┘
          │               │               │               │
          ▼               ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│PromptManager │ │ ClaudeClient │ │ResponseParser│ │ MemoryStore  │
│  (模板管理)  │ │  (API调用)   │ │  (解析响应)  │ │  (会话存储)  │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
          │               │
          ▼               ▼
┌──────────────┐ ┌──────────────┐
│ prompts/v1/  │ │ Anthropic SDK│
│  (模板文件)  │ │  (外部依赖)  │
└──────────────┘ └──────────────┘
```

### 1.3 核心设计原则

| 原则 | 说明 |
|------|------|
| **单一职责** | 每个模块只负责一件事 |
| **依赖注入** | 通过 FastAPI Depends 注入依赖 |
| **异步优先** | 所有 I/O 操作使用 async/await |
| **类型安全** | 严格类型提示，mypy strict 模式 |
| **配置外置** | 敏感配置通过环境变量管理 |

---

## 二、数据模型设计

### 2.1 请求模型 (api/schemas.py)

```python
from pydantic import BaseModel, Field
from typing import Any
from enum import Enum

class DecisionType(str, Enum):
    """决策类型枚举"""
    INVESTMENT = "investment"      # 投资决策
    RISK = "risk"                  # 风险评估
    STRATEGY = "strategy"          # 战略规划

class AnalysisRequest(BaseModel):
    """决策分析请求"""
    query: str = Field(
        ...,
        min_length=10,
        max_length=5000,
        description="决策问题描述",
        examples=["我们正在考虑收购一家AI初创公司，估值5000万美元..."]
    )
    decision_type: DecisionType = Field(
        default=DecisionType.INVESTMENT,
        description="决策类型"
    )
    context: dict[str, Any] | None = Field(
        default=None,
        description="附加上下文信息（财务数据、市场数据等）"
    )
    session_id: str | None = Field(
        default=None,
        description="会话ID（用于多轮对话）"
    )

class FeedbackRequest(BaseModel):
    """反馈请求"""
    analysis_id: str = Field(..., description="分析ID")
    rating: int = Field(..., ge=1, le=5, description="评分 1-5")
    comment: str | None = Field(default=None, max_length=1000)
```

### 2.2 响应模型 (api/schemas.py)

```python
from pydantic import BaseModel, Field
from typing import Any
from datetime import datetime

class RiskFactor(BaseModel):
    """风险因素"""
    category: str = Field(..., description="风险类别")
    description: str = Field(..., description="风险描述")
    severity: str = Field(..., description="严重程度: low/medium/high")
    mitigation: str = Field(..., description="缓解建议")

class Recommendation(BaseModel):
    """建议方案"""
    title: str = Field(..., description="方案名称")
    description: str = Field(..., description="方案描述")
    pros: list[str] = Field(default_factory=list, description="优点")
    cons: list[str] = Field(default_factory=list, description="缺点")
    action_steps: list[str] = Field(default_factory=list, description="执行步骤")
    estimated_impact: str | None = Field(default=None, description="预期影响")

class FinalRecommendation(BaseModel):
    """最终建议"""
    chosen_option: str = Field(..., description="推荐方案")
    reasoning: str = Field(..., description="推荐理由")
    confidence_level: str = Field(..., description="置信度: low/medium/high")
    key_assumptions: list[str] = Field(default_factory=list, description="关键假设")

class AnalysisResult(BaseModel):
    """分析结果"""
    situation_analysis: str = Field(..., description="态势分析")
    risk_score: int = Field(..., ge=1, le=10, description="风险评分 1-10")
    risk_factors: list[RiskFactor] = Field(default_factory=list)
    recommendations: list[Recommendation] = Field(default_factory=list)
    final_recommendation: FinalRecommendation

class AnalysisMetadata(BaseModel):
    """分析元数据"""
    model: str = Field(..., description="使用的模型")
    tokens_used: int = Field(..., description="Token 消耗")
    execution_time_ms: int = Field(..., description="执行时间(毫秒)")
    prompt_version: str = Field(default="v1", description="Prompt 版本")

class AnalysisResponse(BaseModel):
    """完整分析响应"""
    success: bool = True
    data: dict[str, Any] = Field(default_factory=dict)
    metadata: AnalysisMetadata | None = None

    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "data": {
                    "analysis_id": "550e8400-e29b-41d4-a716-446655440000",
                    "query": "是否应该收购这家AI公司？",
                    "result": {
                        "situation_analysis": "基于当前市场环境和公司财务状况...",
                        "risk_score": 7,
                        "risk_factors": [],
                        "recommendations": [],
                        "final_recommendation": {}
                    }
                },
                "metadata": {
                    "model": "claude-3-5-sonnet-20241022",
                    "tokens_used": 1234,
                    "execution_time_ms": 2500
                }
            }
        }

class ErrorDetail(BaseModel):
    """错误详情"""
    code: str = Field(..., description="错误代码")
    message: str = Field(..., description="错误消息")
    details: dict[str, Any] | None = None

class ErrorResponse(BaseModel):
    """错误响应"""
    success: bool = False
    error: ErrorDetail

class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str = "healthy"
    version: str
    timestamp: datetime
```

### 2.3 内部模型 (core/)

```python
# core/agent.py 内部使用的模型

from dataclasses import dataclass
from typing import Any

@dataclass
class ConversationMessage:
    """对话消息"""
    role: str  # "user" | "assistant"
    content: str
    timestamp: datetime

@dataclass
class AnalysisContext:
    """分析上下文"""
    session_id: str
    messages: list[ConversationMessage]
    metadata: dict[str, Any]

@dataclass
class ClaudeResponse:
    """Claude API 响应"""
    content: str
    model: str
    input_tokens: int
    output_tokens: int
    stop_reason: str
```

---

## 三、核心模块详细设计

### 3.1 config.py - 配置管理

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """应用配置"""
    # API 配置
    app_name: str = "CEOAgent"
    app_version: str = "0.1.0"
    debug: bool = False

    # Anthropic 配置
    anthropic_api_key: str
    claude_model: str = "claude-3-5-sonnet-20241022"
    claude_max_tokens: int = 4096
    claude_timeout: int = 60  # 秒

    # Prompt 配置
    prompt_version: str = "v1"
    prompt_dir: str = "prompts"

    # 服务配置
    host: str = "0.0.0.0"
    port: int = 8000

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

### 3.2 core/claude_client.py - Claude API 客户端

```python
"""Claude API 客户端封装"""

from anthropic import AsyncAnthropic
from typing import AsyncGenerator

class ClaudeClient:
    """Claude API 异步客户端"""

    def __init__(self, api_key: str, model: str, max_tokens: int, timeout: int):
        self._client = AsyncAnthropic(api_key=api_key, timeout=timeout)
        self._model = model
        self._max_tokens = max_tokens

    async def complete(
        self,
        system_prompt: str,
        messages: list[dict[str, str]],
        temperature: float = 0.7
    ) -> ClaudeResponse:
        """
        发送消息并获取完整响应

        Args:
            system_prompt: 系统提示词
            messages: 对话消息列表 [{"role": "user", "content": "..."}]
            temperature: 生成温度 0-1

        Returns:
            ClaudeResponse 包含响应内容和元数据

        Raises:
            ClaudeAPIError: API 调用失败
            ClaudeTimeoutError: 请求超时
        """
        pass

    async def complete_stream(
        self,
        system_prompt: str,
        messages: list[dict[str, str]],
        temperature: float = 0.7
    ) -> AsyncGenerator[str, None]:
        """流式响应（Phase 2）"""
        pass

    async def close(self) -> None:
        """关闭客户端连接"""
        await self._client.close()
```

### 3.3 core/prompt_manager.py - Prompt 管理器

```python
"""Prompt 模板管理"""

from pathlib import Path
from string import Template

class PromptManager:
    """Prompt 模板管理器"""

    def __init__(self, prompt_dir: str, version: str = "v1"):
        self._base_path = Path(prompt_dir) / version
        self._cache: dict[str, str] = {}

    def get_system_prompt(self) -> str:
        """获取系统提示词"""
        return self._load_template("system.txt")

    def get_analysis_prompt(
        self,
        decision_type: str,
        query: str,
        context: dict | None = None
    ) -> str:
        """
        获取分析提示词

        Args:
            decision_type: 决策类型 (investment/risk/strategy)
            query: 用户问题
            context: 上下文信息

        Returns:
            格式化后的提示词
        """
        pass

    def _load_template(self, filename: str) -> str:
        """加载模板文件（带缓存）"""
        if filename not in self._cache:
            path = self._base_path / filename
            self._cache[filename] = path.read_text(encoding="utf-8")
        return self._cache[filename]

    def reload_templates(self) -> None:
        """重新加载所有模板（开发用）"""
        self._cache.clear()
```

### 3.4 core/response_parser.py - 响应解析器

```python
"""Claude 响应解析器"""

import json
import re
from typing import Any

class ResponseParser:
    """解析 Claude 响应为结构化数据"""

    def parse(self, raw_response: str) -> AnalysisResult:
        """
        解析原始响应为结构化结果

        Args:
            raw_response: Claude 返回的原始文本

        Returns:
            AnalysisResult 结构化结果

        Raises:
            ParseError: 解析失败
        """
        pass

    def _extract_json(self, text: str) -> dict[str, Any]:
        """从文本中提取 JSON 块"""
        # 尝试多种模式匹配
        patterns = [
            r'```json\s*(.*?)\s*```',  # Markdown JSON 块
            r'\{[\s\S]*\}',             # 纯 JSON 对象
        ]
        pass

    def _extract_risk_score(self, text: str) -> int:
        """提取风险评分（容错解析）"""
        # 支持多种格式：7/10, 7分, Risk Score: 7
        pass

    def _validate_result(self, result: dict) -> bool:
        """验证解析结果完整性"""
        required_fields = [
            "situation_analysis",
            "risk_score",
            "recommendations",
            "final_recommendation"
        ]
        return all(field in result for field in required_fields)
```

### 3.5 core/memory.py - 会话存储

```python
"""会话记忆管理"""

from datetime import datetime, timedelta
from collections import OrderedDict
import uuid

class MemoryStore:
    """内存会话存储（Phase 1）"""

    def __init__(self, max_sessions: int = 1000, session_ttl: int = 3600):
        self._sessions: OrderedDict[str, AnalysisContext] = OrderedDict()
        self._max_sessions = max_sessions
        self._session_ttl = timedelta(seconds=session_ttl)

    def create_session(self) -> str:
        """创建新会话，返回 session_id"""
        session_id = str(uuid.uuid4())
        self._sessions[session_id] = AnalysisContext(
            session_id=session_id,
            messages=[],
            metadata={"created_at": datetime.utcnow()}
        )
        self._cleanup_if_needed()
        return session_id

    def get_session(self, session_id: str) -> AnalysisContext | None:
        """获取会话上下文"""
        ctx = self._sessions.get(session_id)
        if ctx and self._is_expired(ctx):
            self.delete_session(session_id)
            return None
        return ctx

    def add_message(
        self,
        session_id: str,
        role: str,
        content: str
    ) -> None:
        """添加对话消息"""
        pass

    def delete_session(self, session_id: str) -> None:
        """删除会话"""
        self._sessions.pop(session_id, None)

    def _cleanup_if_needed(self) -> None:
        """清理过期和超量会话"""
        # 使用 LRU 策略
        while len(self._sessions) > self._max_sessions:
            self._sessions.popitem(last=False)

    def _is_expired(self, ctx: AnalysisContext) -> bool:
        """检查会话是否过期"""
        created = ctx.metadata.get("created_at", datetime.min)
        return datetime.utcnow() - created > self._session_ttl
```

### 3.6 core/agent.py - AgentCore 核心

```python
"""AgentCore - 核心业务编排器"""

import time
import uuid
from typing import Any

class AgentCore:
    """CEO 决策分析核心引擎"""

    def __init__(
        self,
        claude_client: ClaudeClient,
        prompt_manager: PromptManager,
        response_parser: ResponseParser,
        memory_store: MemoryStore
    ):
        self._claude = claude_client
        self._prompts = prompt_manager
        self._parser = response_parser
        self._memory = memory_store

    async def analyze(
        self,
        query: str,
        decision_type: str = "investment",
        context: dict[str, Any] | None = None,
        session_id: str | None = None
    ) -> tuple[AnalysisResult, AnalysisMetadata]:
        """
        执行决策分析

        Args:
            query: 决策问题
            decision_type: 决策类型
            context: 附加上下文
            session_id: 会话ID（可选）

        Returns:
            (分析结果, 元数据) 元组

        Raises:
            AnalysisError: 分析失败
        """
        start_time = time.perf_counter()
        analysis_id = str(uuid.uuid4())

        # 1. 准备会话上下文
        if session_id:
            session = self._memory.get_session(session_id)
            if not session:
                session_id = self._memory.create_session()
        else:
            session_id = self._memory.create_session()

        # 2. 构建提示词
        system_prompt = self._prompts.get_system_prompt()
        user_prompt = self._prompts.get_analysis_prompt(
            decision_type=decision_type,
            query=query,
            context=context
        )

        # 3. 获取历史消息
        session = self._memory.get_session(session_id)
        messages = self._build_messages(session, user_prompt)

        # 4. 调用 Claude API
        response = await self._claude.complete(
            system_prompt=system_prompt,
            messages=messages
        )

        # 5. 解析响应
        result = self._parser.parse(response.content)

        # 6. 存储对话
        self._memory.add_message(session_id, "user", user_prompt)
        self._memory.add_message(session_id, "assistant", response.content)

        # 7. 构建元数据
        execution_time = int((time.perf_counter() - start_time) * 1000)
        metadata = AnalysisMetadata(
            model=response.model,
            tokens_used=response.input_tokens + response.output_tokens,
            execution_time_ms=execution_time,
            prompt_version=self._prompts._version
        )

        return result, metadata

    def _build_messages(
        self,
        session: AnalysisContext | None,
        new_message: str
    ) -> list[dict[str, str]]:
        """构建消息列表"""
        messages = []
        if session:
            for msg in session.messages[-10:]:  # 最近10条
                messages.append({"role": msg.role, "content": msg.content})
        messages.append({"role": "user", "content": new_message})
        return messages
```

### 3.7 api/routes.py - API 路由

```python
"""API 路由定义"""

from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime

router = APIRouter(prefix="/api/v1", tags=["decision"])

@router.post(
    "/analyze",
    response_model=AnalysisResponse,
    responses={
        400: {"model": ErrorResponse, "description": "请求参数错误"},
        500: {"model": ErrorResponse, "description": "服务器内部错误"},
        503: {"model": ErrorResponse, "description": "Claude API 不可用"}
    },
    summary="执行决策分析",
    description="接收决策问题，返回结构化的分析结果和建议"
)
async def analyze_decision(
    request: AnalysisRequest,
    agent: AgentCore = Depends(get_agent)
) -> AnalysisResponse:
    """
    执行决策分析

    - **query**: 决策问题描述（10-5000字符）
    - **decision_type**: 决策类型（investment/risk/strategy）
    - **context**: 可选的上下文信息
    - **session_id**: 可选的会话ID（用于多轮对话）
    """
    try:
        result, metadata = await agent.analyze(
            query=request.query,
            decision_type=request.decision_type.value,
            context=request.context,
            session_id=request.session_id
        )

        return AnalysisResponse(
            success=True,
            data={
                "analysis_id": str(uuid.uuid4()),
                "query": request.query,
                "session_id": request.session_id,
                "result": result.model_dump()
            },
            metadata=metadata
        )
    except ClaudeAPIError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": "CLAUDE_API_ERROR", "message": str(e)}
        )
    except ParseError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"code": "PARSE_ERROR", "message": str(e)}
        )

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="健康检查",
    tags=["system"]
)
async def health_check(settings: Settings = Depends(get_settings)) -> HealthResponse:
    """检查服务健康状态"""
    return HealthResponse(
        status="healthy",
        version=settings.app_version,
        timestamp=datetime.utcnow()
    )

@router.post(
    "/decisions/{analysis_id}/feedback",
    response_model=dict,
    summary="提交反馈"
)
async def submit_feedback(
    analysis_id: str,
    request: FeedbackRequest
) -> dict:
    """提交分析结果反馈（Phase 2 持久化）"""
    # MVP 阶段仅记录日志
    return {"status": "received", "analysis_id": analysis_id}
```

### 3.8 exceptions.py - 异常定义

```python
"""自定义异常类"""

class CEOAgentError(Exception):
    """基础异常"""
    def __init__(self, message: str, code: str = "UNKNOWN_ERROR"):
        self.message = message
        self.code = code
        super().__init__(message)

class ClaudeAPIError(CEOAgentError):
    """Claude API 调用异常"""
    def __init__(self, message: str):
        super().__init__(message, "CLAUDE_API_ERROR")

class ClaudeTimeoutError(ClaudeAPIError):
    """Claude API 超时"""
    def __init__(self):
        super().__init__("Claude API request timeout", "CLAUDE_TIMEOUT")

class ParseError(CEOAgentError):
    """响应解析异常"""
    def __init__(self, message: str):
        super().__init__(message, "PARSE_ERROR")

class ValidationError(CEOAgentError):
    """验证异常"""
    def __init__(self, message: str):
        super().__init__(message, "VALIDATION_ERROR")

class SessionNotFoundError(CEOAgentError):
    """会话不存在"""
    def __init__(self, session_id: str):
        super().__init__(f"Session not found: {session_id}", "SESSION_NOT_FOUND")
```

### 3.9 main.py - 应用入口

```python
"""FastAPI 应用入口"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时初始化
    settings = get_settings()
    app.state.claude_client = ClaudeClient(
        api_key=settings.anthropic_api_key,
        model=settings.claude_model,
        max_tokens=settings.claude_max_tokens,
        timeout=settings.claude_timeout
    )
    app.state.prompt_manager = PromptManager(
        prompt_dir=settings.prompt_dir,
        version=settings.prompt_version
    )
    app.state.memory_store = MemoryStore()
    app.state.response_parser = ResponseParser()

    yield

    # 关闭时清理
    await app.state.claude_client.close()

def create_app() -> FastAPI:
    """创建 FastAPI 应用"""
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="AI-powered CEO decision support system",
        lifespan=lifespan
    )

    # CORS 配置
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # 生产环境需限制
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 注册路由
    app.include_router(router)

    # 异常处理器
    @app.exception_handler(CEOAgentError)
    async def handle_ceo_agent_error(request, exc):
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "error": {"code": exc.code, "message": exc.message}
            }
        )

    return app

app = create_app()

def main():
    """命令行入口"""
    import uvicorn
    settings = get_settings()
    uvicorn.run(
        "ceo_agent.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )

if __name__ == "__main__":
    main()
```

---

## 四、Prompt 模板设计

### 4.1 prompts/v1/system.txt

```text
你是 CEOAgent，一个专业的 CEO 决策支持 AI 助手。你的职责是帮助 CEO 进行高质量的决策分析。

## 核心能力
- 投资决策分析：评估投资机会的风险与收益
- 风险评估：识别和量化企业面临的各类风险
- 战略规划：制定和评估战略方向

## 输出要求
你必须以结构化的 JSON 格式返回分析结果，包含以下字段：

```json
{
  "situation_analysis": "态势分析（150字以内）",
  "risk_score": 7,  // 1-10 整数，10为最高风险
  "risk_factors": [
    {
      "category": "市场风险",
      "description": "风险描述",
      "severity": "high",  // low/medium/high
      "mitigation": "缓解建议"
    }
  ],
  "recommendations": [
    {
      "title": "方案名称",
      "description": "方案描述",
      "pros": ["优点1", "优点2"],
      "cons": ["缺点1", "缺点2"],
      "action_steps": ["步骤1", "步骤2"],
      "estimated_impact": "预期影响"
    }
  ],
  "final_recommendation": {
    "chosen_option": "推荐的方案名称",
    "reasoning": "推荐理由",
    "confidence_level": "high",  // low/medium/high
    "key_assumptions": ["假设1", "假设2"]
  }
}
```

## 分析原则
1. 客观中立：基于事实和数据，避免主观臆断
2. 多维度思考：考虑财务、市场、运营、人才等多个维度
3. 可行性优先：建议必须具有可执行性
4. 风险意识：充分披露潜在风险和不确定性
```

### 4.2 prompts/v1/investment.txt

```text
## 投资决策分析

请对以下投资决策问题进行全面分析：

**决策问题**：
${query}

**上下文信息**：
${context}

请按照系统提示的 JSON 格式返回分析结果。确保：
1. 态势分析简洁明了，不超过150字
2. 风险评分有明确依据
3. 至少提供2-3个可行方案
4. 每个方案包含具体执行步骤
5. 最终建议有充分的推理过程
```

### 4.3 prompts/v1/risk.txt

```text
## 风险评估分析

请对以下风险评估需求进行全面分析：

**评估需求**：
${query}

**上下文信息**：
${context}

重点评估以下风险领域：
- 财务风险
- 市场风险
- 运营风险
- 合规风险
- 人才风险

请按照系统提示的 JSON 格式返回分析结果。
```

### 4.4 prompts/v1/strategy.txt

```text
## 战略规划分析

请对以下战略规划问题进行全面分析：

**战略问题**：
${query}

**上下文信息**：
${context}

请从以下角度进行分析：
- 当前战略执行状况
- 外部环境变化
- 内部能力评估
- 战略调整建议
- 实施路线图

请按照系统提示的 JSON 格式返回分析结果。
```

---

## 五、测试用例设计

### 5.1 测试策略

```
测试金字塔:

              ┌───────────┐
              │   E2E     │  2-3 个关键场景
              │   Tests   │
              └───────────┘
           ┌─────────────────┐
           │   Integration   │  API 路由测试
           │     Tests       │
           └─────────────────┘
        ┌───────────────────────┐
        │      Unit Tests       │  各模块单元测试
        │                       │
        └───────────────────────┘
```

### 5.2 单元测试 (tests/unit/)

#### tests/unit/test_claude_client.py

```python
"""ClaudeClient 单元测试"""

import pytest
from unittest.mock import AsyncMock, patch
from ceo_agent.core.claude_client import ClaudeClient
from ceo_agent.exceptions import ClaudeAPIError, ClaudeTimeoutError

@pytest.fixture
def mock_anthropic():
    """Mock Anthropic 客户端"""
    with patch("ceo_agent.core.claude_client.AsyncAnthropic") as mock:
        yield mock

@pytest.fixture
def claude_client(mock_anthropic):
    """创建测试用 ClaudeClient"""
    return ClaudeClient(
        api_key="test-key",
        model="claude-3-5-sonnet-20241022",
        max_tokens=4096,
        timeout=60
    )

class TestClaudeClientComplete:
    """测试 complete 方法"""

    async def test_complete_success(self, claude_client, mock_anthropic):
        """正常调用返回响应"""
        # Arrange
        mock_response = AsyncMock()
        mock_response.content = [AsyncMock(text="分析结果")]
        mock_response.model = "claude-3-5-sonnet-20241022"
        mock_response.usage.input_tokens = 100
        mock_response.usage.output_tokens = 200
        mock_response.stop_reason = "end_turn"

        mock_anthropic.return_value.messages.create = AsyncMock(
            return_value=mock_response
        )

        # Act
        result = await claude_client.complete(
            system_prompt="You are a helpful assistant",
            messages=[{"role": "user", "content": "Hello"}]
        )

        # Assert
        assert result.content == "分析结果"
        assert result.model == "claude-3-5-sonnet-20241022"
        assert result.input_tokens == 100
        assert result.output_tokens == 200

    async def test_complete_api_error(self, claude_client, mock_anthropic):
        """API 错误应抛出 ClaudeAPIError"""
        mock_anthropic.return_value.messages.create = AsyncMock(
            side_effect=Exception("API Error")
        )

        with pytest.raises(ClaudeAPIError):
            await claude_client.complete(
                system_prompt="test",
                messages=[{"role": "user", "content": "test"}]
            )

    async def test_complete_timeout(self, claude_client, mock_anthropic):
        """超时应抛出 ClaudeTimeoutError"""
        from asyncio import TimeoutError
        mock_anthropic.return_value.messages.create = AsyncMock(
            side_effect=TimeoutError()
        )

        with pytest.raises(ClaudeTimeoutError):
            await claude_client.complete(
                system_prompt="test",
                messages=[{"role": "user", "content": "test"}]
            )

    async def test_complete_with_temperature(self, claude_client, mock_anthropic):
        """验证 temperature 参数传递"""
        mock_anthropic.return_value.messages.create = AsyncMock(
            return_value=AsyncMock(
                content=[AsyncMock(text="result")],
                model="test",
                usage=AsyncMock(input_tokens=0, output_tokens=0),
                stop_reason="end_turn"
            )
        )

        await claude_client.complete(
            system_prompt="test",
            messages=[{"role": "user", "content": "test"}],
            temperature=0.5
        )

        # 验证调用参数
        call_args = mock_anthropic.return_value.messages.create.call_args
        assert call_args.kwargs["temperature"] == 0.5
```

#### tests/unit/test_prompt_manager.py

```python
"""PromptManager 单元测试"""

import pytest
from pathlib import Path
from ceo_agent.core.prompt_manager import PromptManager

@pytest.fixture
def temp_prompts(tmp_path):
    """创建临时 Prompt 文件"""
    v1_dir = tmp_path / "v1"
    v1_dir.mkdir()

    (v1_dir / "system.txt").write_text("System prompt content")
    (v1_dir / "investment.txt").write_text(
        "Investment analysis for: ${query}\nContext: ${context}"
    )

    return tmp_path

@pytest.fixture
def prompt_manager(temp_prompts):
    return PromptManager(prompt_dir=str(temp_prompts), version="v1")

class TestPromptManager:
    """PromptManager 测试"""

    def test_get_system_prompt(self, prompt_manager):
        """获取系统提示词"""
        result = prompt_manager.get_system_prompt()
        assert result == "System prompt content"

    def test_get_analysis_prompt_investment(self, prompt_manager):
        """获取投资分析提示词"""
        result = prompt_manager.get_analysis_prompt(
            decision_type="investment",
            query="Should we invest?",
            context={"budget": "1M"}
        )

        assert "Should we invest?" in result
        assert "budget" in result

    def test_get_analysis_prompt_no_context(self, prompt_manager):
        """无上下文时的处理"""
        result = prompt_manager.get_analysis_prompt(
            decision_type="investment",
            query="Test query",
            context=None
        )

        assert "Test query" in result

    def test_template_caching(self, prompt_manager):
        """模板缓存测试"""
        # 第一次加载
        result1 = prompt_manager.get_system_prompt()
        # 第二次应从缓存获取
        result2 = prompt_manager.get_system_prompt()

        assert result1 == result2
        assert len(prompt_manager._cache) == 1

    def test_reload_templates(self, prompt_manager, temp_prompts):
        """重新加载模板"""
        # 加载一次
        prompt_manager.get_system_prompt()
        assert len(prompt_manager._cache) == 1

        # 修改文件
        (temp_prompts / "v1" / "system.txt").write_text("Updated content")

        # 重新加载
        prompt_manager.reload_templates()
        assert len(prompt_manager._cache) == 0

        # 验证新内容
        result = prompt_manager.get_system_prompt()
        assert result == "Updated content"

    def test_missing_template_file(self, temp_prompts):
        """缺少模板文件应抛出异常"""
        pm = PromptManager(prompt_dir=str(temp_prompts), version="v1")

        with pytest.raises(FileNotFoundError):
            pm._load_template("nonexistent.txt")
```

#### tests/unit/test_response_parser.py

```python
"""ResponseParser 单元测试"""

import pytest
from ceo_agent.core.response_parser import ResponseParser
from ceo_agent.exceptions import ParseError

@pytest.fixture
def parser():
    return ResponseParser()

@pytest.fixture
def valid_response():
    return '''
    基于分析，这是我的建议：

    ```json
    {
        "situation_analysis": "当前市场环境复杂，需要谨慎决策。",
        "risk_score": 7,
        "risk_factors": [
            {
                "category": "市场风险",
                "description": "市场波动较大",
                "severity": "high",
                "mitigation": "分散投资"
            }
        ],
        "recommendations": [
            {
                "title": "保守方案",
                "description": "维持现状",
                "pros": ["风险低"],
                "cons": ["增长慢"],
                "action_steps": ["观望", "收集数据"],
                "estimated_impact": "稳定"
            }
        ],
        "final_recommendation": {
            "chosen_option": "保守方案",
            "reasoning": "考虑到当前市场不确定性",
            "confidence_level": "medium",
            "key_assumptions": ["市场将在6个月内稳定"]
        }
    }
    ```
    '''

class TestResponseParser:
    """ResponseParser 测试"""

    def test_parse_valid_json_block(self, parser, valid_response):
        """解析有效的 JSON 块"""
        result = parser.parse(valid_response)

        assert result.situation_analysis == "当前市场环境复杂，需要谨慎决策。"
        assert result.risk_score == 7
        assert len(result.risk_factors) == 1
        assert result.risk_factors[0].category == "市场风险"
        assert len(result.recommendations) == 1
        assert result.final_recommendation.chosen_option == "保守方案"

    def test_parse_pure_json(self, parser):
        """解析纯 JSON（无 Markdown 包裹）"""
        response = '''
        {
            "situation_analysis": "测试",
            "risk_score": 5,
            "risk_factors": [],
            "recommendations": [],
            "final_recommendation": {
                "chosen_option": "A",
                "reasoning": "因为",
                "confidence_level": "high",
                "key_assumptions": []
            }
        }
        '''
        result = parser.parse(response)
        assert result.risk_score == 5

    def test_parse_invalid_json(self, parser):
        """无效 JSON 应抛出 ParseError"""
        with pytest.raises(ParseError):
            parser.parse("This is not JSON at all")

    def test_parse_missing_required_field(self, parser):
        """缺少必要字段应抛出 ParseError"""
        response = '''
        ```json
        {
            "situation_analysis": "测试"
        }
        ```
        '''
        with pytest.raises(ParseError) as exc_info:
            parser.parse(response)
        assert "risk_score" in str(exc_info.value).lower() or "required" in str(exc_info.value).lower()

    def test_extract_risk_score_various_formats(self, parser):
        """测试多种风险评分格式"""
        test_cases = [
            ("风险评分: 7", 7),
            ("Risk Score: 8/10", 8),
            ("风险等级为 6 分", 6),
            ('"risk_score": 9', 9),
        ]

        for text, expected in test_cases:
            result = parser._extract_risk_score(text)
            assert result == expected, f"Failed for: {text}"

    def test_validate_result_complete(self, parser):
        """验证完整结果"""
        complete_result = {
            "situation_analysis": "...",
            "risk_score": 5,
            "risk_factors": [],
            "recommendations": [],
            "final_recommendation": {}
        }
        assert parser._validate_result(complete_result) is True

    def test_validate_result_incomplete(self, parser):
        """验证不完整结果"""
        incomplete_result = {
            "situation_analysis": "..."
        }
        assert parser._validate_result(incomplete_result) is False
```

#### tests/unit/test_memory.py

```python
"""MemoryStore 单元测试"""

import pytest
from datetime import datetime, timedelta
from ceo_agent.core.memory import MemoryStore

@pytest.fixture
def memory_store():
    return MemoryStore(max_sessions=5, session_ttl=3600)

class TestMemoryStore:
    """MemoryStore 测试"""

    def test_create_session(self, memory_store):
        """创建会话"""
        session_id = memory_store.create_session()

        assert session_id is not None
        assert len(session_id) == 36  # UUID 格式

    def test_get_session(self, memory_store):
        """获取会话"""
        session_id = memory_store.create_session()
        session = memory_store.get_session(session_id)

        assert session is not None
        assert session.session_id == session_id
        assert session.messages == []

    def test_get_nonexistent_session(self, memory_store):
        """获取不存在的会话返回 None"""
        session = memory_store.get_session("nonexistent-id")
        assert session is None

    def test_add_message(self, memory_store):
        """添加消息"""
        session_id = memory_store.create_session()

        memory_store.add_message(session_id, "user", "Hello")
        memory_store.add_message(session_id, "assistant", "Hi there")

        session = memory_store.get_session(session_id)
        assert len(session.messages) == 2
        assert session.messages[0].role == "user"
        assert session.messages[0].content == "Hello"
        assert session.messages[1].role == "assistant"

    def test_delete_session(self, memory_store):
        """删除会话"""
        session_id = memory_store.create_session()
        memory_store.delete_session(session_id)

        assert memory_store.get_session(session_id) is None

    def test_max_sessions_limit(self, memory_store):
        """超过最大会话数时自动清理"""
        session_ids = []
        for _ in range(7):  # 超过 max_sessions=5
            session_ids.append(memory_store.create_session())

        # 最早的会话应被清理
        assert memory_store.get_session(session_ids[0]) is None
        assert memory_store.get_session(session_ids[1]) is None
        # 最近的会话应保留
        assert memory_store.get_session(session_ids[-1]) is not None

    def test_session_expiry(self, memory_store):
        """会话过期测试"""
        # 创建过期会话（通过修改元数据）
        session_id = memory_store.create_session()
        session = memory_store.get_session(session_id)
        session.metadata["created_at"] = datetime.utcnow() - timedelta(hours=2)

        # 获取时应返回 None 并清理
        assert memory_store.get_session(session_id) is None
```

#### tests/unit/test_agent.py

```python
"""AgentCore 单元测试"""

import pytest
from unittest.mock import AsyncMock, MagicMock
from ceo_agent.core.agent import AgentCore
from ceo_agent.api.schemas import AnalysisResult, FinalRecommendation

@pytest.fixture
def mock_claude_client():
    client = AsyncMock()
    client.complete.return_value = MagicMock(
        content='{"situation_analysis": "test", "risk_score": 5, '
                '"risk_factors": [], "recommendations": [], '
                '"final_recommendation": {"chosen_option": "A", '
                '"reasoning": "test", "confidence_level": "high", '
                '"key_assumptions": []}}',
        model="claude-3-5-sonnet-20241022",
        input_tokens=100,
        output_tokens=200
    )
    return client

@pytest.fixture
def mock_prompt_manager():
    pm = MagicMock()
    pm.get_system_prompt.return_value = "System prompt"
    pm.get_analysis_prompt.return_value = "Analysis prompt"
    pm._version = "v1"
    return pm

@pytest.fixture
def mock_response_parser():
    parser = MagicMock()
    parser.parse.return_value = AnalysisResult(
        situation_analysis="测试态势分析",
        risk_score=5,
        risk_factors=[],
        recommendations=[],
        final_recommendation=FinalRecommendation(
            chosen_option="方案A",
            reasoning="测试理由",
            confidence_level="high",
            key_assumptions=[]
        )
    )
    return parser

@pytest.fixture
def mock_memory_store():
    store = MagicMock()
    store.create_session.return_value = "test-session-id"
    store.get_session.return_value = MagicMock(
        session_id="test-session-id",
        messages=[]
    )
    return store

@pytest.fixture
def agent(mock_claude_client, mock_prompt_manager,
          mock_response_parser, mock_memory_store):
    return AgentCore(
        claude_client=mock_claude_client,
        prompt_manager=mock_prompt_manager,
        response_parser=mock_response_parser,
        memory_store=mock_memory_store
    )

class TestAgentCore:
    """AgentCore 测试"""

    async def test_analyze_basic(self, agent):
        """基本分析流程"""
        result, metadata = await agent.analyze(
            query="Should we invest?",
            decision_type="investment"
        )

        assert result.situation_analysis == "测试态势分析"
        assert result.risk_score == 5
        assert metadata.model == "claude-3-5-sonnet-20241022"
        assert metadata.tokens_used == 300  # 100 + 200

    async def test_analyze_with_context(self, agent, mock_prompt_manager):
        """带上下文的分析"""
        context = {"budget": "1M", "timeline": "6 months"}

        await agent.analyze(
            query="Investment decision",
            decision_type="investment",
            context=context
        )

        # 验证上下文被传递
        mock_prompt_manager.get_analysis_prompt.assert_called_with(
            decision_type="investment",
            query="Investment decision",
            context=context
        )

    async def test_analyze_with_session(self, agent, mock_memory_store):
        """带会话的分析"""
        await agent.analyze(
            query="Follow up question",
            session_id="existing-session-id"
        )

        # 验证获取现有会话
        mock_memory_store.get_session.assert_called()

    async def test_analyze_creates_new_session(self, agent, mock_memory_store):
        """无会话时创建新会话"""
        mock_memory_store.get_session.return_value = None

        await agent.analyze(query="New question")

        mock_memory_store.create_session.assert_called()

    async def test_analyze_stores_messages(self, agent, mock_memory_store):
        """验证消息被存储"""
        await agent.analyze(query="Test question")

        # 应存储用户消息和助手响应
        assert mock_memory_store.add_message.call_count == 2

    async def test_analyze_execution_time(self, agent):
        """验证执行时间记录"""
        _, metadata = await agent.analyze(query="Test")

        assert metadata.execution_time_ms >= 0
        assert isinstance(metadata.execution_time_ms, int)
```

### 5.3 集成测试 (tests/integration/)

#### tests/integration/test_api.py

```python
"""API 集成测试"""

import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import patch, AsyncMock, MagicMock
from ceo_agent.main import app

@pytest.fixture
def mock_agent():
    """Mock AgentCore"""
    with patch("ceo_agent.api.routes.get_agent") as mock:
        agent = AsyncMock()
        agent.analyze.return_value = (
            MagicMock(
                situation_analysis="测试分析",
                risk_score=5,
                risk_factors=[],
                recommendations=[],
                final_recommendation=MagicMock(
                    chosen_option="A",
                    reasoning="测试",
                    confidence_level="high",
                    key_assumptions=[]
                ),
                model_dump=lambda: {
                    "situation_analysis": "测试分析",
                    "risk_score": 5,
                    "risk_factors": [],
                    "recommendations": [],
                    "final_recommendation": {
                        "chosen_option": "A",
                        "reasoning": "测试",
                        "confidence_level": "high",
                        "key_assumptions": []
                    }
                }
            ),
            MagicMock(
                model="claude-3-5-sonnet-20241022",
                tokens_used=300,
                execution_time_ms=1000,
                prompt_version="v1"
            )
        )
        mock.return_value = agent
        yield agent

@pytest.fixture
async def client():
    """创建测试客户端"""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

class TestAnalyzeEndpoint:
    """POST /api/v1/analyze 测试"""

    async def test_analyze_success(self, client, mock_agent):
        """正常分析请求"""
        response = await client.post(
            "/api/v1/analyze",
            json={
                "query": "Should we invest in this startup?",
                "decision_type": "investment"
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "analysis_id" in data["data"]
        assert data["data"]["result"]["risk_score"] == 5

    async def test_analyze_with_context(self, client, mock_agent):
        """带上下文的请求"""
        response = await client.post(
            "/api/v1/analyze",
            json={
                "query": "Investment decision",
                "decision_type": "investment",
                "context": {"budget": "1000000"}
            }
        )

        assert response.status_code == 200

    async def test_analyze_query_too_short(self, client):
        """查询太短应返回 422"""
        response = await client.post(
            "/api/v1/analyze",
            json={"query": "short"}  # 少于 10 字符
        )

        assert response.status_code == 422

    async def test_analyze_invalid_decision_type(self, client):
        """无效的决策类型"""
        response = await client.post(
            "/api/v1/analyze",
            json={
                "query": "A valid query that is long enough",
                "decision_type": "invalid_type"
            }
        )

        assert response.status_code == 422

    async def test_analyze_missing_query(self, client):
        """缺少 query 字段"""
        response = await client.post(
            "/api/v1/analyze",
            json={"decision_type": "investment"}
        )

        assert response.status_code == 422

class TestHealthEndpoint:
    """GET /api/v1/health 测试"""

    async def test_health_check(self, client):
        """健康检查"""
        response = await client.get("/api/v1/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "timestamp" in data

class TestFeedbackEndpoint:
    """POST /api/v1/decisions/{id}/feedback 测试"""

    async def test_submit_feedback(self, client):
        """提交反馈"""
        response = await client.post(
            "/api/v1/decisions/test-id/feedback",
            json={
                "analysis_id": "test-id",
                "rating": 5,
                "comment": "Very helpful"
            }
        )

        assert response.status_code == 200
        assert response.json()["status"] == "received"

    async def test_feedback_invalid_rating(self, client):
        """无效评分"""
        response = await client.post(
            "/api/v1/decisions/test-id/feedback",
            json={
                "analysis_id": "test-id",
                "rating": 10  # 超出 1-5 范围
            }
        )

        assert response.status_code == 422
```

### 5.4 E2E 测试 (tests/e2e/)

#### tests/e2e/test_scenarios.py

```python
"""端到端场景测试"""

import pytest
import os
from httpx import AsyncClient, ASGITransport

# 仅在设置了 API Key 时运行
pytestmark = pytest.mark.skipif(
    not os.getenv("ANTHROPIC_API_KEY"),
    reason="ANTHROPIC_API_KEY not set"
)

@pytest.fixture(scope="module")
def real_app():
    """使用真实配置的应用"""
    from ceo_agent.main import create_app
    return create_app()

@pytest.fixture
async def real_client(real_app):
    transport = ASGITransport(app=real_app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

class TestInvestmentScenario:
    """投资决策场景 E2E 测试"""

    @pytest.mark.slow
    async def test_investment_decision_complete_flow(self, real_client):
        """完整投资决策流程"""
        response = await real_client.post(
            "/api/v1/analyze",
            json={
                "query": """
                我们正在考虑收购一家 AI 初创公司：
                - 估值：5000 万美元
                - 年收入：500 万美元
                - 团队：30 人，含 5 位博士
                - 核心技术：大语言模型微调平台
                - 主要客户：3 家世界 500 强

                请分析这笔收购的风险和收益。
                """,
                "decision_type": "investment",
                "context": {
                    "our_company": "大型科技公司",
                    "available_budget": "1亿美元",
                    "strategic_goal": "增强 AI 能力"
                }
            },
            timeout=120.0  # Claude API 可能需要较长时间
        )

        assert response.status_code == 200
        data = response.json()

        # 验证响应结构
        assert data["success"] is True
        result = data["data"]["result"]

        # 验证必要字段
        assert "situation_analysis" in result
        assert len(result["situation_analysis"]) > 0
        assert 1 <= result["risk_score"] <= 10
        assert len(result["recommendations"]) >= 2
        assert result["final_recommendation"]["reasoning"]

        # 验证元数据
        assert data["metadata"]["tokens_used"] > 0
        assert data["metadata"]["execution_time_ms"] > 0

class TestRiskScenario:
    """风险评估场景 E2E 测试"""

    @pytest.mark.slow
    async def test_risk_assessment_complete_flow(self, real_client):
        """完整风险评估流程"""
        response = await real_client.post(
            "/api/v1/analyze",
            json={
                "query": """
                请评估我们公司面临的主要风险：
                - 行业：电商平台
                - 年收入：10 亿美元
                - 增长率：同比下降 15%
                - 竞争：新进入者采用低价策略
                - 供应链：依赖单一供应商
                """,
                "decision_type": "risk"
            },
            timeout=120.0
        )

        assert response.status_code == 200
        data = response.json()
        result = data["data"]["result"]

        # 风险评估应识别多个风险因素
        assert len(result["risk_factors"]) >= 2

        # 每个风险因素应有完整信息
        for factor in result["risk_factors"]:
            assert factor["category"]
            assert factor["severity"] in ["low", "medium", "high"]
            assert factor["mitigation"]
```

### 5.5 测试配置

#### conftest.py

```python
"""Pytest 配置和共享 Fixtures"""

import pytest
import asyncio
from typing import Generator

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """创建事件循环"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(autouse=True)
def reset_singletons():
    """每个测试后重置单例"""
    yield
    # 清理缓存的设置
    from ceo_agent.config import get_settings
    get_settings.cache_clear()

def pytest_configure(config):
    """注册自定义标记"""
    config.addinivalue_line("markers", "slow: marks tests as slow")

def pytest_collection_modifyitems(config, items):
    """根据标记跳过测试"""
    if not config.getoption("--run-slow"):
        skip_slow = pytest.mark.skip(reason="need --run-slow option to run")
        for item in items:
            if "slow" in item.keywords:
                item.add_marker(skip_slow)

def pytest_addoption(parser):
    """添加命令行选项"""
    parser.addoption(
        "--run-slow",
        action="store_true",
        default=False,
        help="run slow tests"
    )
```

#### pytest.ini

```ini
[pytest]
testpaths = tests
asyncio_mode = auto
addopts = -v --tb=short --strict-markers
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    e2e: marks tests as end-to-end tests
filterwarnings =
    ignore::DeprecationWarning
```

---

## 六、评估用例

### 6.1 评估用例文件 (evaluation/test_cases/)

#### investment_cases.json

```json
{
  "version": "1.0",
  "cases": [
    {
      "id": "INV-001",
      "name": "AI 初创公司收购",
      "query": "我们正在考虑收购一家 AI 初创公司，估值5000万美元，年收入500万，30人团队含5位博士，核心技术是大语言模型微调平台，有3家世界500强客户。请分析这笔收购。",
      "decision_type": "investment",
      "context": {
        "buyer": "大型科技公司",
        "budget": "1亿美元"
      },
      "expected": {
        "risk_score_range": [5, 8],
        "must_include_keywords": ["估值", "技术", "团队", "客户"],
        "min_recommendations": 2,
        "must_have_action_steps": true
      }
    },
    {
      "id": "INV-002",
      "name": "海外市场扩张",
      "query": "我们是国内领先的 SaaS 公司，正在考虑进入东南亚市场。需要投入2000万美元，预计3年回本。请分析是否应该投资。",
      "decision_type": "investment",
      "context": {
        "company": "SaaS 企业",
        "current_revenue": "5亿人民币"
      },
      "expected": {
        "risk_score_range": [4, 7],
        "must_include_keywords": ["市场", "竞争", "本地化"],
        "min_recommendations": 2
      }
    },
    {
      "id": "INV-003",
      "name": "高风险加密货币投资",
      "query": "一位投资人建议我们用公司现金储备的30%投资比特币，他认为明年会翻倍。请分析这个建议。",
      "decision_type": "investment",
      "expected": {
        "risk_score_range": [8, 10],
        "must_include_keywords": ["波动", "风险", "监管"],
        "should_warn": true
      }
    }
  ]
}
```

#### risk_cases.json

```json
{
  "version": "1.0",
  "cases": [
    {
      "id": "RISK-001",
      "name": "供应链单一依赖",
      "query": "我们90%的关键零部件来自一家供应商，这家供应商最近出现财务问题。请评估风险。",
      "decision_type": "risk",
      "expected": {
        "risk_score_range": [7, 10],
        "must_include_categories": ["供应链风险", "运营风险"],
        "must_have_mitigation": true
      }
    },
    {
      "id": "RISK-002",
      "name": "核心人才流失",
      "query": "我们的技术VP和3位核心工程师正在被竞争对手挖角，他们掌握公司核心技术。请评估风险和应对策略。",
      "decision_type": "risk",
      "expected": {
        "risk_score_range": [6, 9],
        "must_include_categories": ["人才风险"],
        "min_mitigation_strategies": 2
      }
    }
  ]
}
```

### 6.2 评估脚本 (evaluation/run_eval.py)

```python
#!/usr/bin/env python3
"""评估脚本"""

import json
import asyncio
from pathlib import Path
from dataclasses import dataclass
from httpx import AsyncClient

@dataclass
class EvalResult:
    case_id: str
    case_name: str
    passed: bool
    score: float
    details: dict

class Evaluator:
    """评估器"""

    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url

    async def run_all(self) -> list[EvalResult]:
        """运行所有评估用例"""
        results = []
        cases_dir = Path(__file__).parent / "test_cases"

        async with AsyncClient(base_url=self.base_url, timeout=120.0) as client:
            for case_file in cases_dir.glob("*.json"):
                data = json.loads(case_file.read_text())
                for case in data["cases"]:
                    result = await self.evaluate_case(client, case)
                    results.append(result)

        return results

    async def evaluate_case(self, client: AsyncClient, case: dict) -> EvalResult:
        """评估单个用例"""
        try:
            response = await client.post(
                "/api/v1/analyze",
                json={
                    "query": case["query"],
                    "decision_type": case.get("decision_type", "investment"),
                    "context": case.get("context")
                }
            )

            if response.status_code != 200:
                return EvalResult(
                    case_id=case["id"],
                    case_name=case["name"],
                    passed=False,
                    score=0,
                    details={"error": f"HTTP {response.status_code}"}
                )

            result = response.json()["data"]["result"]
            score, details = self.calculate_score(result, case["expected"])

            return EvalResult(
                case_id=case["id"],
                case_name=case["name"],
                passed=score >= 60,
                score=score,
                details=details
            )
        except Exception as e:
            return EvalResult(
                case_id=case["id"],
                case_name=case["name"],
                passed=False,
                score=0,
                details={"error": str(e)}
            )

    def calculate_score(self, result: dict, expected: dict) -> tuple[float, dict]:
        """计算得分"""
        score = 0
        details = {}

        # 完整性 (40分)
        completeness = 0
        if result.get("situation_analysis"):
            completeness += 10
            details["has_situation_analysis"] = True
        if result.get("risk_score") is not None:
            completeness += 10
            details["has_risk_score"] = True
        if len(result.get("recommendations", [])) >= 2:
            completeness += 10
            details["has_multiple_recommendations"] = True
        if result.get("final_recommendation"):
            completeness += 10
            details["has_final_recommendation"] = True
        score += completeness

        # 准确性 (30分)
        accuracy = 0
        if "risk_score_range" in expected:
            min_score, max_score = expected["risk_score_range"]
            if min_score <= result.get("risk_score", 0) <= max_score:
                accuracy += 15
                details["risk_score_in_range"] = True
            else:
                details["risk_score_in_range"] = False

        if "must_include_keywords" in expected:
            text = json.dumps(result, ensure_ascii=False)
            found = sum(1 for kw in expected["must_include_keywords"] if kw in text)
            keyword_score = (found / len(expected["must_include_keywords"])) * 15
            accuracy += keyword_score
            details["keywords_found"] = found
        score += accuracy

        # 可行性 (30分)
        feasibility = 0
        for rec in result.get("recommendations", []):
            if rec.get("action_steps") and len(rec["action_steps"]) >= 2:
                feasibility += 10
                details["has_action_steps"] = True
                break

        if result.get("final_recommendation", {}).get("reasoning"):
            feasibility += 20
            details["has_reasoning"] = True
        score += feasibility

        return score, details

async def main():
    evaluator = Evaluator()
    results = await evaluator.run_all()

    print("\n" + "=" * 60)
    print("评估结果")
    print("=" * 60)

    total_score = 0
    passed_count = 0

    for r in results:
        status = "✅ PASS" if r.passed else "❌ FAIL"
        print(f"\n{r.case_id}: {r.case_name}")
        print(f"  状态: {status}")
        print(f"  得分: {r.score:.1f}/100")
        print(f"  详情: {r.details}")
        total_score += r.score
        if r.passed:
            passed_count += 1

    print("\n" + "=" * 60)
    print(f"总结: {passed_count}/{len(results)} 通过")
    print(f"平均分: {total_score / len(results):.1f}")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 七、自我评审清单

### 7.1 代码质量检查

| 检查项 | 标准 | 检查命令 |
|--------|------|----------|
| 类型检查 | mypy 无错误 | `mypy src/ceo_agent --strict` |
| 代码风格 | ruff 无警告 | `ruff check .` |
| 代码格式 | 已格式化 | `ruff format --check .` |
| 测试覆盖 | > 80% | `pytest --cov=src/ceo_agent --cov-report=term-missing` |
| 文档字符串 | 所有公开函数有 docstring | 代码审查 |

### 7.2 功能检查

| 检查项 | 验证方法 |
|--------|----------|
| API 启动 | `uvicorn src.ceo_agent.main:app` 无错误 |
| 健康检查 | `curl localhost:8000/api/v1/health` 返回 200 |
| 分析接口 | `curl -X POST localhost:8000/api/v1/analyze -d '{"query":"test query for analysis"}' -H 'Content-Type: application/json'` 返回结构化结果 |
| API 文档 | 浏览器访问 `localhost:8000/docs` |
| 评估通过 | `python evaluation/run_eval.py` 平均分 > 60 |

### 7.3 安全检查

| 检查项 | 说明 |
|--------|------|
| API Key 保护 | 不硬编码，使用环境变量 |
| 输入验证 | 所有输入经 Pydantic 验证 |
| 错误信息 | 不泄露敏感信息 |
| CORS | 生产环境限制 origins |
| 日志 | 不记录敏感数据 |

### 7.4 性能检查

| 检查项 | 标准 |
|--------|------|
| 响应时间 | Claude API 响应 < 60s |
| 内存使用 | 会话数不超过上限 |
| 连接管理 | 客户端正确关闭 |
| 超时处理 | 所有外部调用有超时设置 |

### 7.5 发布前检查

```bash
# 完整检查脚本
#!/bin/bash
set -e

echo "1. 运行类型检查..."
mypy src/ceo_agent --strict

echo "2. 运行代码检查..."
ruff check .

echo "3. 运行格式检查..."
ruff format --check .

echo "4. 运行测试..."
pytest --cov=src/ceo_agent --cov-fail-under=80

echo "5. 启动服务测试..."
uvicorn src.ceo_agent.main:app &
PID=$!
sleep 3

echo "6. 健康检查..."
curl -f http://localhost:8000/api/v1/health

echo "7. 关闭服务..."
kill $PID

echo "✅ 所有检查通过！"
```

---

## 八、开发流程

### 8.1 开发顺序

```
Day 1: 项目结构 + 配置
├── 创建目录结构
├── 配置 pyproject.toml
├── 实现 config.py
├── 实现 exceptions.py
└── 编写配置测试

Day 2: 核心组件 (1)
├── 实现 ClaudeClient
├── 实现 PromptManager
├── 创建 Prompt 模板
└── 编写单元测试

Day 3: 核心组件 (2)
├── 实现 ResponseParser
├── 实现 MemoryStore
├── 实现 AgentCore
└── 编写单元测试

Day 4: API 层
├── 定义 schemas.py
├── 实现 routes.py
├── 实现 main.py
├── 配置依赖注入
└── 编写集成测试

Day 5: 测试 + 评估
├── 补充测试用例
├── 运行评估脚本
├── 修复发现的问题
├── 完成发布检查
└── 编写使用文档
```

### 8.2 Git 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
test: 测试相关
refactor: 重构
chore: 构建/配置

示例:
feat(api): add /analyze endpoint
fix(parser): handle malformed JSON response
test(agent): add integration tests for multi-turn conversation
```

---

## 九、附录

### 9.1 环境变量

```bash
# .env.example
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
CLAUDE_MODEL=claude-3-5-sonnet-20241022
CLAUDE_MAX_TOKENS=4096
CLAUDE_TIMEOUT=60

DEBUG=false
HOST=0.0.0.0
PORT=8000

PROMPT_VERSION=v1
PROMPT_DIR=prompts
```

### 9.2 依赖版本

```
# requirements.txt (Phase 1)
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
anthropic>=0.18.0
pydantic>=2.5.0
pydantic-settings>=2.1.0
python-dotenv>=1.0.0
httpx>=0.26.0
```

### 9.3 相关文档

| 文档 | 说明 |
|------|------|
| MASTER_PLAN.md | 权威开发计划 |
| API_DESIGN.md | API 设计规范 |
| ARCHITECTURE.md | 系统架构 |
| scenarios/*.md | 场景验证 |
