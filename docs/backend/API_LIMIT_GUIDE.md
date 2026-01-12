# API 调用限制配置指南

本文档说明项目中所有 API 调用限制的配置方法和解除/调整方式。

## 📊 限制类型概览

项目中有以下几层 API 调用限制：

1. **应用层速率限制**：FastAPI 应用内部的限流
2. **Nginx Ingress 限流**：Kubernetes 网关层的限流
3. **Claude API 限制**：Anthropic API 的速率限制
4. **Token Bucket 限流器**：应用内的令牌桶算法限流
5. **SlowAPI 限流**：基于 IP/用户的限流中间件

---

## 1. 应用层速率限制

### 当前配置

```python
# src/ceo_agent/config.py
rate_limit_per_minute: int = Field(default=10, ge=1, le=100)
```

**默认值**：10 次/分钟

### 解除/调整方法

#### 方法 1: 通过环境变量配置

在 `.env` 文件中添加：

```bash
# 应用层速率限制（每分钟请求数）
RATE_LIMIT_PER_MINUTE=100  # 增加到 100 次/分钟（默认 10）
```

#### 方法 2: 修改配置文件

```python
# src/ceo_agent/config.py
rate_limit_per_minute: int = Field(
    default=100,  # 修改默认值
    ge=1,
    le=1000,  # 提高上限
    description="每分钟最大请求数"
)
```

---

## 2. Nginx Ingress 限流

### 当前配置

```yaml
# k8s/base/ingress.yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

**默认值**：100 次/分钟

### 解除/调整方法

#### 方法 1: 修改 Ingress 配置

```yaml
# k8s/base/ingress.yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "1000"  # 增加到 1000
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    # 或者禁用限流（不推荐生产环境）
    # nginx.ingress.kubernetes.io/rate-limit: "0"
```

#### 方法 2: 按路径配置不同限制

```yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "1000"
  nginx.ingress.kubernetes.io/rate-limit-rps: "100"  # 每秒请求数
  nginx.ingress.kubernetes.io/rate-limit-connections: "50"  # 并发连接数
```

#### 方法 3: 完全禁用（仅开发环境）

```yaml
annotations:
  # 注释掉或删除限流配置
  # nginx.ingress.kubernetes.io/rate-limit: "100"
```

---

## 3. Token Bucket 限流器

### 当前实现

```python
# 从 SECURITY.md 中的实现
rate_limiter = RateLimiter(rate=10, capacity=100)  # 每秒 10 个请求，容量 100
```

### 解除/调整方法

#### 方法 1: 修改限流器参数

```python
# src/ceo_agent/middleware/rate_limiter.py
from collections import defaultdict
import time

class RateLimiter:
    def __init__(self, rate: int = 100, capacity: int = 1000):  # 增加参数
        self.rate = rate  # 每秒补充的 token 数
        self.capacity = capacity  # 桶容量
        self.tokens = defaultdict(lambda: capacity)
        self.last_refill = defaultdict(lambda: time.time())

# 使用示例 - 更高的限制
rate_limiter = RateLimiter(
    rate=100,      # 每秒 100 个请求（默认 10）
    capacity=1000  # 容量 1000（默认 100）
)
```

#### 方法 2: 按用户类型设置不同限制

```python
class RateLimiter:
    def __init__(self):
        # VIP 用户：更高的限制
        self.vip_rate = RateLimiter(rate=100, capacity=1000)
        # 普通用户：标准限制
        self.normal_rate = RateLimiter(rate=10, capacity=100)
    
    async def acquire(self, key: str, is_vip: bool = False) -> bool:
        limiter = self.vip_rate if is_vip else self.normal_rate
        return await limiter.acquire(key)
```

#### 方法 3: 禁用限流器（仅开发环境）

```python
class RateLimiter:
    def __init__(self, enabled: bool = True):
        self.enabled = enabled
    
    async def acquire(self, key: str) -> bool:
        if not self.enabled:
            return True  # 直接通过
        # ... 原有的限流逻辑
```

---

## 4. SlowAPI 限流（基于 IP/用户）

### 当前配置

```python
# SECURITY.md 中的实现
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/api/v1/decision/analyze")
@limiter.limit("10/minute")  # 每分钟 10 次
async def analyze_decision(request: Request, ...):
    pass
```

### 解除/调整方法

#### 方法 1: 提高限制值

```python
@router.post("/api/v1/decision/analyze")
@limiter.limit("100/minute")  # 增加到 100 次/分钟
# 或
@limiter.limit("10/second")   # 每秒 10 次
async def analyze_decision(request: Request, ...):
    pass
```

#### 方法 2: 移除限流装饰器

```python
# 完全移除 @limiter.limit 装饰器
@router.post("/api/v1/decision/analyze")
async def analyze_decision(request: Request, ...):
    pass
```

#### 方法 3: 条件限流

```python
def conditional_limiter():
    """根据环境决定是否限流"""
    from ceo_agent.config import get_settings
    settings = get_settings()
    
    if settings.app_env == "development":
        return limiter.limit("1000/minute")  # 开发环境宽松
    else:
        return limiter.limit("10/minute")    # 生产环境严格

@router.post("/api/v1/decision/analyze")
@conditional_limiter()
async def analyze_decision(request: Request, ...):
    pass
```

---

## 5. Claude API 限制

详细配置请参考：[CLAUDE_API_LIMIT_GUIDE.md](./CLAUDE_API_LIMIT_GUIDE.md)

### 快速配置

```bash
# .env 文件
CLAUDE_MAX_RETRIES=5
CLAUDE_RETRY_BASE_DELAY=2.0
CLAUDE_RETRY_MAX_DELAY=60.0
CLAUDE_MAX_REQUESTS_PER_MINUTE=50
CLAUDE_MAX_CONCURRENT_REQUESTS=5
```

---

## 🔧 完整配置示例

### 开发环境配置（宽松限制）

```bash
# .env.development
ENVIRONMENT=development

# 应用层限制 - 宽松
RATE_LIMIT_PER_MINUTE=1000

# Claude API 配置
CLAUDE_MAX_RETRIES=3
CLAUDE_RETRY_BASE_DELAY=1.0
CLAUDE_MAX_REQUESTS_PER_MINUTE=100
CLAUDE_MAX_CONCURRENT_REQUESTS=10
```

```python
# src/ceo_agent/middleware/rate_limiter.py
# 开发环境禁用限流
if settings.app_env == "development":
    rate_limiter = RateLimiter(enabled=False)
else:
    rate_limiter = RateLimiter(rate=10, capacity=100)
```

```yaml
# k8s/base/ingress.yaml (开发环境)
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "0"  # 禁用
```

### 生产环境配置（合理限制）

```bash
# .env.production
ENVIRONMENT=production

# 应用层限制
RATE_LIMIT_PER_MINUTE=100

# Claude API 配置
CLAUDE_MAX_RETRIES=5
CLAUDE_RETRY_BASE_DELAY=2.0
CLAUDE_RETRY_MAX_DELAY=60.0
CLAUDE_MAX_REQUESTS_PER_MINUTE=50
CLAUDE_MAX_CONCURRENT_REQUESTS=5
```

```python
# 生产环境使用严格限制
rate_limiter = RateLimiter(rate=10, capacity=100)
```

```yaml
# k8s/base/ingress.yaml (生产环境)
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

---

## 📋 环境变量完整列表

在 `env.server.example` 中添加完整的限制配置：

```bash
# ========== API 调用限制配置 ==========

# 应用层速率限制
RATE_LIMIT_PER_MINUTE=10

# Claude API 重试配置
CLAUDE_MAX_RETRIES=3
CLAUDE_RETRY_BASE_DELAY=1.0
CLAUDE_RETRY_MAX_DELAY=60.0

# Claude API 速率限制
CLAUDE_MAX_REQUESTS_PER_MINUTE=50
CLAUDE_MAX_CONCURRENT_REQUESTS=5

# Token Bucket 配置
TOKEN_BUCKET_RATE=10
TOKEN_BUCKET_CAPACITY=100

# SlowAPI 配置（在代码中配置）
# SLOWAPI_ENABLED=true
# SLOWAPI_DEFAULT_LIMIT=10/minute
```

---

## 🎯 解除所有限制（仅开发环境）

如果需要完全解除所有限制用于开发测试：

### 1. 环境变量配置

```bash
# .env
ENVIRONMENT=development
RATE_LIMIT_PER_MINUTE=999999
CLAUDE_MAX_REQUESTS_PER_MINUTE=999999
```

### 2. 代码修改

```python
# src/ceo_agent/config.py
class Settings(BaseSettings):
    # ... 其他配置
    
    @property
    def is_development(self) -> bool:
        return self.app_env == "development"
    
    @property
    def effective_rate_limit(self) -> int:
        """获取有效速率限制"""
        if self.is_development:
            return 999999  # 开发环境几乎无限制
        return self.rate_limit_per_minute
```

### 3. Ingress 配置

```yaml
# k8s/base/ingress.yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "0"  # 0 表示禁用
```

### 4. 禁用限流中间件

```python
# src/ceo_agent/main.py
from ceo_agent.config import get_settings

settings = get_settings()

if settings.is_development:
    # 开发环境：不添加限流中间件
    pass
else:
    # 生产环境：添加限流中间件
    app.add_middleware(RateLimitMiddleware)
```

---

## 📊 限制优先级

当多个限制同时存在时，**最严格的限制会生效**：

```
用户请求
  ↓
Nginx Ingress (100/分钟) ← 第一层
  ↓
SlowAPI 限流 (10/分钟) ← 第二层
  ↓
Token Bucket (10/秒) ← 第三层
  ↓
应用层限制 (10/分钟) ← 第四层
  ↓
Claude API 限制 (API 端限制) ← 最终限制
```

**建议**：统一配置，避免多层限制冲突。

---

## 🔍 检查和监控

### 查看当前限制配置

```python
from ceo_agent.config import get_settings

settings = get_settings()
print(f"应用层限制: {settings.rate_limit_per_minute}/分钟")
```

### 监控 API 调用情况

```python
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class APICallMonitor:
    """API 调用监控"""
    
    def __init__(self):
        self.call_count = 0
        self.start_time = datetime.now()
    
    def record_call(self):
        self.call_count += 1
        elapsed = (datetime.now() - self.start_time).total_seconds()
        rate = self.call_count / elapsed * 60  # 每分钟
        
        logger.info(
            f"API calls: {self.call_count} total, "
            f"{rate:.2f} calls/minute"
        )
```

---

## ⚠️ 注意事项

1. **生产环境**：不要完全禁用限流，防止滥用
2. **测试环境**：可以放宽限制，便于测试
3. **监控**：始终监控 API 使用情况
4. **成本**：提高限制可能增加 API 调用成本
5. **安全**：限流是安全防护措施之一，谨慎调整

---

## 📚 相关文档

- [CLAUDE_API_LIMIT_GUIDE.md](./CLAUDE_API_LIMIT_GUIDE.md) - Claude API 限制详细指南
- [SECURITY.md](./SECURITY.md) - 安全配置（包含限流实现）
- [API_DESIGN.md](./API_DESIGN.md) - API 设计规范
- [BACKEND_DEVELOPMENT.md](./BACKEND_DEVELOPMENT.md) - 后端开发指南
