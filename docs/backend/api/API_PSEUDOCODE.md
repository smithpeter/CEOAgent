# API 伪代码逻辑

> **创建日期**: 2026-01-12
> **创建人**: 后端开发 (Backend Dev)
> **关联文档**: API_DESIGN.md, PRD_decision_analysis.md

---

## 一、验证结论

### 1.1 API 设计与需求一致性

| 验证项 | 状态 | 说明 |
|--------|------|------|
| API 端点覆盖 P0 用例 | ✅ | POST /api/v1/decision/analyze |
| 请求 Schema 符合 PRD | ✅ | query + context 结构 |
| 响应 Schema 符合 PRD | ✅ | 四部分内容完整 |
| 错误码定义一致 | ✅ | 400/500/502/504 |

### 1.2 数据模型验证

| 模型 | 字段完整性 | 验证规则 |
|------|-----------|---------|
| AnalyzeRequest | ✅ | query 必填，max 10000 |
| AnalyzeResponse | ✅ | 四部分结构 |
| RiskAssessment | ✅ | score 1-10 |
| Recommendation | ✅ | 至少 2 个方案 |

---

## 二、API 端点伪代码

### 2.1 POST /api/v1/decision/analyze

```python
# =============================================================================
# 决策分析 API 端点伪代码
# =============================================================================

@router.post("/api/v1/decision/analyze", response_model=AnalyzeResponse)
async def analyze_decision(request: AnalyzeRequest) -> AnalyzeResponse:
    """
    决策分析端点
    
    流程:
    1. 请求验证
    2. 构建 Prompt
    3. 调用 Claude API
    4. 解析响应
    5. 返回结果
    """
    
    # Step 1: 请求验证
    # -----------------
    IF request.query IS EMPTY:
        RAISE HTTPException(400, code="INVALID_INPUT", message="query field is required")
    
    IF LENGTH(request.query) > 10000:
        RAISE HTTPException(400, code="INVALID_INPUT", message="query exceeds maximum length")
    
    IF request.context IS PROVIDED AND NOT VALID_JSON(request.context):
        RAISE HTTPException(400, code="INVALID_INPUT", message="invalid context format")
    
    # Step 2: 构建 Prompt
    # -------------------
    system_prompt = prompt_manager.get_system_prompt()
    user_message = prompt_manager.build_user_message(
        query=request.query,
        context=request.context
    )
    
    # Step 3: 调用 Claude API
    # -----------------------
    TRY:
        start_time = NOW()
        
        response_text, usage = await claude_client.complete_with_retry(
            system_prompt=system_prompt,
            user_message=user_message,
            max_retries=3,
            timeout=60
        )
        
        execution_time = NOW() - start_time
        
    CATCH TimeoutError:
        RAISE HTTPException(504, code="TIMEOUT", message="Request timeout")
    
    CATCH AnthropicAPIError as e:
        LOG.error(f"Claude API error: {e}")
        RAISE HTTPException(502, code="LLM_ERROR", message=str(e))
    
    # Step 4: 解析响应
    # ----------------
    TRY:
        result = response_parser.parse(response_text)
        
        # 验证风险评分范围
        IF NOT (1 <= result.risk_assessment.overall_score <= 10):
            LOG.warning("Risk score out of range, clamping")
            result.risk_assessment.overall_score = CLAMP(result.risk_assessment.overall_score, 1, 10)
        
        # 验证方案数量
        IF LENGTH(result.recommendations) < 2:
            LOG.warning("Less than 2 recommendations")
        
    CATCH ParseError as e:
        LOG.error(f"Response parse error: {e}")
        RAISE HTTPException(500, code="PARSE_ERROR", message="Failed to parse LLM response")
    
    # Step 5: 构建响应
    # ----------------
    RETURN AnalyzeResponse(
        success=True,
        data=AnalysisData(
            analysis_id=GENERATE_UUID(),
            query=request.query,
            result=result
        ),
        metadata=Metadata(
            model=config.model_name,
            tokens_used=usage.total_tokens,
            execution_time_ms=execution_time.milliseconds
        )
    )
```

### 2.2 核心组件伪代码

#### ClaudeClient

```python
# =============================================================================
# Claude API 客户端伪代码
# =============================================================================

class ClaudeClient:
    
    def __init__(self, api_key: str, model: str):
        self.client = Anthropic(api_key=api_key)
        self.model = model
    
    async def complete_with_retry(
        self,
        system_prompt: str,
        user_message: str,
        max_retries: int = 3,
        timeout: int = 60
    ) -> tuple[str, Usage]:
        """
        带重试的 API 调用
        
        重试策略:
        - 指数退避: 1s, 2s, 4s
        - 仅重试可恢复错误 (5xx, 超时)
        - 不重试客户端错误 (4xx)
        """
        
        retry_count = 0
        last_error = None
        
        WHILE retry_count < max_retries:
            TRY:
                WITH TIMEOUT(timeout):
                    response = await self.client.messages.create(
                        model=self.model,
                        max_tokens=4096,
                        system=system_prompt,
                        messages=[{"role": "user", "content": user_message}]
                    )
                
                RETURN (
                    response.content[0].text,
                    Usage(
                        input_tokens=response.usage.input_tokens,
                        output_tokens=response.usage.output_tokens,
                        total_tokens=response.usage.input_tokens + response.usage.output_tokens
                    )
                )
            
            CATCH (TimeoutError, ServerError) as e:
                last_error = e
                retry_count += 1
                
                IF retry_count < max_retries:
                    wait_time = 2 ** (retry_count - 1)  # 指数退避
                    LOG.warning(f"Retry {retry_count}/{max_retries} after {wait_time}s")
                    await SLEEP(wait_time)
            
            CATCH ClientError as e:
                # 客户端错误不重试
                RAISE e
        
        RAISE last_error
```

#### ResponseParser

```python
# =============================================================================
# 响应解析器伪代码
# =============================================================================

class ResponseParser:
    
    def parse(self, response_text: str) -> AnalysisResult:
        """
        解析 Claude 响应
        
        支持的格式:
        1. 纯 JSON
        2. Markdown code block 包裹的 JSON
        3. 混合文本 + JSON
        """
        
        # Step 1: 提取 JSON
        json_str = self._extract_json(response_text)
        
        IF json_str IS NONE:
            RAISE ParseError("No valid JSON found in response")
        
        # Step 2: 解析 JSON
        TRY:
            data = JSON.parse(json_str)
        CATCH JSONDecodeError as e:
            RAISE ParseError(f"Invalid JSON: {e}")
        
        # Step 3: 验证结构
        IF NOT self._validate_structure(data):
            RAISE ParseError("Response structure incomplete")
        
        # Step 4: 构建结果
        RETURN AnalysisResult(
            situation_analysis=SituationAnalysis(
                summary=data.get("situation_analysis", {}).get("summary", ""),
                key_findings=data.get("situation_analysis", {}).get("key_findings", [])
            ),
            risk_assessment=RiskAssessment(
                overall_score=data.get("risk_assessment", {}).get("overall_score", 5),
                risk_factors=data.get("risk_assessment", {}).get("risk_factors", [])
            ),
            recommendations=self._parse_recommendations(data.get("recommendations", [])),
            final_recommendation=data.get("final_recommendation", {})
        )
    
    def _extract_json(self, text: str) -> str | None:
        """从文本中提取 JSON"""
        
        # 尝试 1: 直接解析
        TRY:
            JSON.parse(text)
            RETURN text
        CATCH:
            PASS
        
        # 尝试 2: 提取 markdown code block
        match = REGEX.search(r"```(?:json)?\s*([\s\S]*?)```", text)
        IF match:
            RETURN match.group(1).strip()
        
        # 尝试 3: 提取 { ... } 结构
        match = REGEX.search(r"\{[\s\S]*\}", text)
        IF match:
            RETURN match.group(0)
        
        RETURN None
    
    def _validate_structure(self, data: dict) -> bool:
        """验证数据结构"""
        required_fields = ["situation_analysis", "risk_assessment", "recommendations", "final_recommendation"]
        RETURN ALL(field IN data FOR field IN required_fields)
    
    def _parse_recommendations(self, recs: list) -> list[Recommendation]:
        """解析推荐方案，带容错"""
        result = []
        FOR rec IN recs:
            result.append(Recommendation(
                title=rec.get("title", "未命名方案"),
                investment_amount=rec.get("investment_amount"),
                expected_return=rec.get("expected_return"),
                risk_level=rec.get("risk_level", "unknown"),
                timeline=rec.get("timeline"),
                pros=rec.get("pros", []),
                cons=rec.get("cons", []),
                action_steps=rec.get("action_steps", [])
            ))
        RETURN result
```

#### AgentCore

```python
# =============================================================================
# Agent 核心伪代码
# =============================================================================

class AgentCore:
    
    def __init__(
        self,
        claude_client: ClaudeClient,
        prompt_manager: PromptManager,
        response_parser: ResponseParser,
        memory_store: MemoryStore
    ):
        self.claude = claude_client
        self.prompts = prompt_manager
        self.parser = response_parser
        self.memory = memory_store
    
    async def analyze(
        self,
        query: str,
        context: dict | None = None,
        session_id: str | None = None
    ) -> AnalysisResponse:
        """
        执行决策分析
        
        流程:
        1. 加载会话上下文
        2. 构建 Prompt
        3. 调用 Claude API
        4. 解析响应
        5. 保存会话
        6. 返回结果
        """
        
        # Step 1: 加载会话上下文
        conversation_history = []
        IF session_id:
            session = self.memory.get(session_id)
            IF session:
                conversation_history = session.messages
        
        # Step 2: 构建 Prompt
        system_prompt = self.prompts.get_system_prompt()
        user_message = self.prompts.build_user_message(
            query=query,
            context=context,
            history=conversation_history
        )
        
        # Step 3: 调用 Claude API
        start_time = NOW()
        
        response_text, usage = await self.claude.complete_with_retry(
            system_prompt=system_prompt,
            user_message=user_message
        )
        
        execution_time = NOW() - start_time
        
        # Step 4: 解析响应
        result = self.parser.parse(response_text)
        
        # Step 5: 保存会话
        IF session_id:
            self.memory.append(session_id, {
                "role": "user",
                "content": query
            })
            self.memory.append(session_id, {
                "role": "assistant",
                "content": response_text
            })
        
        # Step 6: 返回结果
        RETURN AnalysisResponse(
            analysis_id=GENERATE_UUID(),
            query=query,
            result=result,
            metadata=Metadata(
                model=self.claude.model,
                tokens_used=usage.total_tokens,
                execution_time_ms=execution_time.milliseconds
            )
        )
```

---

## 三、数据模型定义

### 3.1 请求模型

```python
class AnalyzeRequest(BaseModel):
    """决策分析请求"""
    
    query: str = Field(
        ...,
        min_length=1,
        max_length=10000,
        description="决策问题描述"
    )
    
    context: Optional[Dict[str, Any]] = Field(
        default=None,
        description="上下文数据"
    )
    
    # 验证器
    @validator("query")
    def validate_query(cls, v):
        IF NOT v.strip():
            RAISE ValueError("Query cannot be empty")
        RETURN v.strip()
```

### 3.2 响应模型

```python
class SituationAnalysis(BaseModel):
    """态势分析"""
    summary: str = Field(..., description="当前状况总结")
    key_findings: List[str] = Field(default=[], description="关键发现")

class RiskFactor(BaseModel):
    """风险因素"""
    name: str
    level: str  # low/medium/high
    reason: str

class RiskAssessment(BaseModel):
    """风险评估"""
    overall_score: int = Field(..., ge=1, le=10, description="总体风险评分")
    risk_factors: List[RiskFactor] = Field(default=[])

class Recommendation(BaseModel):
    """推荐方案"""
    title: str
    investment_amount: Optional[str] = None
    expected_return: Optional[str] = None
    risk_level: str  # low/medium/high
    timeline: Optional[str] = None
    pros: List[str] = []
    cons: List[str] = []
    action_steps: List[str] = []

class FinalRecommendation(BaseModel):
    """最终建议"""
    choice: str
    reasoning: str

class AnalysisResult(BaseModel):
    """分析结果"""
    situation_analysis: SituationAnalysis
    risk_assessment: RiskAssessment
    recommendations: List[Recommendation] = Field(..., min_items=2)
    final_recommendation: FinalRecommendation

class AnalysisData(BaseModel):
    """分析数据"""
    analysis_id: str
    query: str
    result: AnalysisResult

class Metadata(BaseModel):
    """元数据"""
    model: str
    tokens_used: int
    execution_time_ms: int

class AnalyzeResponse(BaseModel):
    """分析响应"""
    success: bool = True
    data: AnalysisData
    metadata: Metadata
```

---

## 四、错误处理

### 4.1 错误码映射

| 错误场景 | HTTP 状态码 | 错误码 | 处理方式 |
|---------|------------|--------|---------|
| query 为空 | 400 | INVALID_INPUT | 返回错误信息 |
| query 过长 | 400 | INVALID_INPUT | 返回错误信息 |
| context 格式错误 | 400 | INVALID_INPUT | 返回错误信息 |
| Claude API 超时 | 504 | TIMEOUT | 重试后返回错误 |
| Claude API 错误 | 502 | LLM_ERROR | 返回错误信息 |
| 响应解析失败 | 500 | PARSE_ERROR | 返回错误信息 |

### 4.2 错误响应格式

```python
class ErrorResponse(BaseModel):
    """错误响应"""
    success: bool = False
    error: ErrorDetail
    metadata: Optional[Metadata] = None

class ErrorDetail(BaseModel):
    """错误详情"""
    code: str
    message: str
    details: Optional[Dict] = None
```

---

## 五、验证结论

✅ **后端设计验证通过**

- API 设计与 PRD 需求完全对应
- 数据模型完整，验证规则合理
- 错误处理覆盖所有异常场景
- 伪代码逻辑清晰，可直接实现

---

## 更新日志

| 日期 | 修改内容 | 修改人 |
|------|---------|--------|
| 2026-01-12 | 创建 API 伪代码文档 | Backend |
