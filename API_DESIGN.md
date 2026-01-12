# API 设计规范

## API 设计原则

### RESTful 原则

1. **资源导向**：URL 表示资源，HTTP 方法表示操作
2. **无状态**：每个请求包含所有必要信息
3. **统一接口**：使用标准 HTTP 方法
4. **分层系统**：客户端无需知道中间层
5. **可缓存**：响应应标记为可缓存或不可缓存

### 设计原则

- **一致性**：统一的命名、格式、错误处理
- **可预测性**：相似的资源使用相似的路径
- **可扩展性**：支持未来扩展而不破坏现有客户端
- **向后兼容**：版本控制保证兼容性

## API 版本控制

### URL 版本控制

```
/api/v1/decision/analyze
/api/v2/decision/analyze
```

### Header 版本控制（备选）

```
Accept: application/vnd.ceoagent.v1+json
```

**推荐**：使用 URL 版本控制，更直观

## API 端点设计

### 基础路径

```
Base URL: https://api.ceoagent.com
API Prefix: /api/v1
```

### 端点分类

#### 1. 认证相关

```
POST   /api/v1/auth/register       # 用户注册
POST   /api/v1/auth/login          # 用户登录
POST   /api/v1/auth/refresh        # 刷新 Token
POST   /api/v1/auth/logout         # 用户登出
POST   /api/v1/auth/password/reset # 重置密码
```

#### 2. 决策相关

```
POST   /api/v1/decision/analyze              # 分析决策
GET    /api/v1/decisions                     # 获取决策列表
GET    /api/v1/decisions/{id}                # 获取决策详情
POST   /api/v1/decisions/{id}/feedback       # 提交反馈
DELETE /api/v1/decisions/{id}                # 删除决策
GET    /api/v1/decisions/{id}/trail          # 获取决策追溯
```

#### 3. 数据相关

```
POST   /api/v1/data/collect                  # 收集数据
GET    /api/v1/data/sources                  # 获取数据源列表
GET    /api/v1/data/analysis                 # 数据分析
GET    /api/v1/data/visualization            # 数据可视化
```

#### 4. 知识库相关

```
GET    /api/v1/knowledge/search              # 搜索知识
POST   /api/v1/knowledge/documents           # 上传文档
GET    /api/v1/knowledge/documents/{id}      # 获取文档
DELETE /api/v1/knowledge/documents/{id}      # 删除文档
```

#### 5. Skill 相关

```
GET    /api/v1/skills                        # 获取 Skill 列表
GET    /api/v1/skills/{name}                 # 获取 Skill 详情
POST   /api/v1/skills/{name}/execute         # 执行 Skill
```

#### 6. 实时通信

```
WS     /ws/chat                              # WebSocket 聊天
WS     /ws/decision/{id}                     # 决策执行流式更新
```

## 请求/响应格式

### 请求格式

**Content-Type**: `application/json`

```json
{
  "query": "Should we expand to new markets?",
  "context": {
    "industry": "technology",
    "company_size": "medium"
  },
  "options": ["Yes", "No", "Defer"]
}
```

### 响应格式

#### 成功响应

```json
{
  "success": true,
  "data": {
    "decision_id": "uuid",
    "query": "Should we expand to new markets?",
    "recommendation": {
      "option": "Yes",
      "confidence": 0.85,
      "reasoning": "...",
      "risks": [...],
      "benefits": [...]
    },
    "skills_used": ["data_analysis", "risk_assessment"],
    "created_at": "2025-01-11T10:00:00Z"
  },
  "metadata": {
    "request_id": "req-uuid",
    "execution_time_ms": 1234
  }
}
```

#### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "The query field is required",
    "details": {
      "field": "query",
      "reason": "missing_required_field"
    }
  },
  "metadata": {
    "request_id": "req-uuid",
    "timestamp": "2025-01-11T10:00:00Z"
  }
}
```

### 分页响应

```json
{
  "success": true,
  "data": [
    {...},
    {...}
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5,
    "has_next": true,
    "has_previous": false
  }
}
```

## HTTP 状态码

### 成功状态码

- `200 OK`：请求成功
- `201 Created`：资源创建成功
- `204 No Content`：请求成功，无返回内容

### 客户端错误

- `400 Bad Request`：请求格式错误
- `401 Unauthorized`：未认证
- `403 Forbidden`：无权限
- `404 Not Found`：资源不存在
- `409 Conflict`：资源冲突
- `422 Unprocessable Entity`：验证失败
- `429 Too Many Requests`：请求频率超限

### 服务器错误

- `500 Internal Server Error`：服务器内部错误
- `502 Bad Gateway`：网关错误
- `503 Service Unavailable`：服务不可用
- `504 Gateway Timeout`：网关超时

## 错误码规范

### 错误码格式

```
<MODULE>_<CATEGORY>_<SPECIFIC>
```

例如：
- `AUTH_INVALID_TOKEN`：认证-无效 Token
- `DECISION_NOT_FOUND`：决策-未找到
- `DATA_SOURCE_UNAVAILABLE`：数据-源不可用

### 常见错误码

```python
class ErrorCode(Enum):
    # 通用错误
    INTERNAL_ERROR = "INTERNAL_ERROR"
    INVALID_REQUEST = "INVALID_REQUEST"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    
    # 认证错误
    AUTH_REQUIRED = "AUTH_REQUIRED"
    AUTH_INVALID_TOKEN = "AUTH_INVALID_TOKEN"
    AUTH_TOKEN_EXPIRED = "AUTH_TOKEN_EXPIRED"
    AUTH_INSUFFICIENT_PERMISSIONS = "AUTH_INSUFFICIENT_PERMISSIONS"
    
    # 决策错误
    DECISION_NOT_FOUND = "DECISION_NOT_FOUND"
    DECISION_INVALID_QUERY = "DECISION_INVALID_QUERY"
    DECISION_EXECUTION_FAILED = "DECISION_EXECUTION_FAILED"
    
    # 数据错误
    DATA_SOURCE_UNAVAILABLE = "DATA_SOURCE_UNAVAILABLE"
    DATA_INVALID_FORMAT = "DATA_INVALID_FORMAT"
    DATA_NOT_FOUND = "DATA_NOT_FOUND"
    
    # Skill 错误
    SKILL_NOT_FOUND = "SKILL_NOT_FOUND"
    SKILL_EXECUTION_FAILED = "SKILL_EXECUTION_FAILED"
    SKILL_INVALID_PARAMS = "SKILL_INVALID_PARAMS"
```

## 认证授权

### JWT Token

**Header**:
```
Authorization: Bearer <token>
```

### API Key（可选）

**Header**:
```
X-API-Key: <api_key>
```

### 请求示例

```python
import httpx

async def analyze_decision(query: str, token: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.ceoagent.com/api/v1/decision/analyze",
            json={"query": query},
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
        )
        return response.json()
```

## 请求验证

### Pydantic 模型验证

```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime

class DecisionRequest(BaseModel):
    """决策分析请求"""
    query: str = Field(
        ...,
        min_length=1,
        max_length=5000,
        description="决策查询问题"
    )
    context: Optional[Dict[str, Any]] = Field(
        default_factory=dict,
        description="上下文信息"
    )
    options: Optional[List[str]] = Field(
        default=None,
        min_items=1,
        max_items=10,
        description="可选决策方案"
    )
    include_analysis: bool = Field(
        default=True,
        description="是否包含详细分析"
    )
    
    @validator('query')
    def validate_query(cls, v):
        if not v.strip():
            raise ValueError("Query cannot be empty")
        return v.strip()
    
    @validator('options')
    def validate_options(cls, v):
        if v and len(set(v)) != len(v):
            raise ValueError("Options must be unique")
        return v

class DecisionResponse(BaseModel):
    """决策分析响应"""
    decision_id: str
    query: str
    recommendation: Dict[str, Any]
    skills_used: List[str]
    created_at: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "decision_id": "uuid",
                "query": "Should we expand?",
                "recommendation": {
                    "option": "Yes",
                    "confidence": 0.85
                },
                "skills_used": ["data_analysis", "risk_assessment"],
                "created_at": "2025-01-11T10:00:00Z"
            }
        }
```

## API 端点实现示例

### FastAPI 实现

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List

router = APIRouter(prefix="/api/v1", tags=["decision"])
security = HTTPBearer()

@router.post(
    "/decision/analyze",
    response_model=DecisionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="分析决策",
    description="基于查询和上下文分析决策，生成建议",
    responses={
        201: {"description": "决策分析成功"},
        400: {"description": "请求参数错误"},
        401: {"description": "未认证"},
        403: {"description": "无权限"},
        429: {"description": "请求频率超限"}
    }
)
async def analyze_decision(
    request: DecisionRequest,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    current_user: User = Depends(get_current_user)
):
    """分析决策端点"""
    
    # 权限检查
    if not check_permission(current_user, Permission.DECISION_CREATE):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    # 限流检查
    if not await rate_limiter.acquire(f"user:{current_user.id}"):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded"
        )
    
    try:
        # 执行决策分析
        result = await decision_service.analyze(
            query=request.query,
            context=request.context,
            options=request.options,
            user_id=current_user.id
        )
        
        # 记录审计日志
        await audit_logger.log(
            user_id=current_user.id,
            action="decision.analyze",
            resource_type="decision",
            resource_id=result.decision_id,
            details={"query": request.query},
            result="success"
        )
        
        return DecisionResponse(**result.dict())
    
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "DECISION_INVALID_QUERY",
                "message": "Invalid query format",
                "details": e.errors()
            }
        )
    except Exception as e:
        logger.error(f"Decision analysis failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "DECISION_EXECUTION_FAILED",
                "message": "Decision analysis failed"
            }
        )

@router.get(
    "/decisions",
    response_model=List[DecisionResponse],
    summary="获取决策列表",
    description="获取用户的决策列表，支持分页和过滤"
)
async def get_decisions(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    status: Optional[str] = Query(None, description="状态过滤"),
    current_user: User = Depends(get_current_user)
):
    """获取决策列表"""
    decisions = await decision_service.list_decisions(
        user_id=current_user.id,
        page=page,
        page_size=page_size,
        status=status
    )
    return [DecisionResponse(**d.dict()) for d in decisions]
```

## WebSocket API

### 连接建立

```python
@router.websocket("/ws/chat")
async def websocket_chat(
    websocket: WebSocket,
    token: str = Query(...)
):
    """WebSocket 聊天连接"""
    # 验证 Token
    user = await verify_token(token)
    if not user:
        await websocket.close(code=1008, reason="Unauthorized")
        return
    
    await websocket.accept()
    
    try:
        while True:
            # 接收消息
            data = await websocket.receive_json()
            
            # 处理消息（流式响应）
            async for chunk in process_message_stream(data):
                await websocket.send_json(chunk)
    
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected: {user.id}")
```

### 流式响应格式

```json
{
  "type": "chunk",
  "content": "部分响应内容",
  "index": 0
}

{
  "type": "done",
  "decision_id": "uuid",
  "complete_response": "..."
}
```

## API 文档

### OpenAPI/Swagger

FastAPI 自动生成 OpenAPI 文档：

```
/docs          # Swagger UI
/redoc         # ReDoc
/openapi.json  # OpenAPI JSON Schema
```

### 文档增强

```python
app = FastAPI(
    title="CEOAgent API",
    description="CEO 决策智能体 API 文档",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    contact={
        "name": "API Support",
        "email": "api@ceoagent.com"
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
    }
)
```

## 版本控制策略

### 向后兼容性

1. **添加新字段**：可选字段，不影响旧客户端
2. **添加新端点**：不影响现有端点
3. **弃用端点**：保留但标记为 deprecated，提供迁移指南

### 版本迁移

```python
@router.post("/decision/analyze")
async def analyze_decision_v1(request: DecisionRequestV1):
    """V1 版本（已弃用）"""
    # 转换到 V2 格式
    v2_request = convert_v1_to_v2(request)
    return await analyze_decision_v2(v2_request)

@router.post("/decision/analyze")
async def analyze_decision_v2(request: DecisionRequestV2):
    """V2 版本（当前）"""
    pass
```

## 测试

### API 测试示例

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_analyze_decision(client: AsyncClient, auth_token: str):
    """测试决策分析"""
    response = await client.post(
        "/api/v1/decision/analyze",
        json={
            "query": "Should we expand?",
            "options": ["Yes", "No"]
        },
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "decision_id" in data["data"]
    assert "recommendation" in data["data"]

@pytest.mark.asyncio
async def test_analyze_decision_unauthorized(client: AsyncClient):
    """测试未认证请求"""
    response = await client.post(
        "/api/v1/decision/analyze",
        json={"query": "Test"}
    )
    
    assert response.status_code == 401
```

## API 最佳实践

### 1. 使用合适的 HTTP 方法

- `GET`：获取资源
- `POST`：创建资源或执行操作
- `PUT`：完整更新资源
- `PATCH`：部分更新资源
- `DELETE`：删除资源

### 2. 合理的响应大小

- 列表端点支持分页
- 使用字段过滤减少响应大小
- 大文件使用流式传输

### 3. 幂等性

- `GET`、`PUT`、`DELETE` 应该是幂等的
- `POST` 操作考虑幂等性设计

### 4. 错误处理

- 提供详细的错误信息
- 使用标准错误码
- 记录错误日志

### 5. 性能优化

- 支持压缩（gzip）
- 实现缓存策略
- 异步处理耗时操作

## 参考文档

- [RESTful API 设计指南](https://restfulapi.net/)
- [OpenAPI 规范](https://swagger.io/specification/)
- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [SECURITY.md](./SECURITY.md) - 安全相关
- [PERFORMANCE.md](./PERFORMANCE.md) - 性能优化
