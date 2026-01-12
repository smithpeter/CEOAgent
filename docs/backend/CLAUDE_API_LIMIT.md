# Claude API 调用限制解除指南

本文档说明如何解除或优化 Claude API 的调用限制处理。

## 📋 Claude API 限制类型

### 1. 速率限制 (Rate Limits)
- **请求频率限制**：每分钟/每小时的最大请求数
- **并发限制**：同时进行的请求数量
- **Token 限制**：每分钟/每小时的最大 token 使用量

### 2. 配额限制 (Quota Limits)
- **日/月配额**：基于 API 计划的使用限额

## 🔧 解除限制的方法

### 方法 1: 增加重试次数和延迟

在配置文件中调整重试参数：

```python
# src/ceo_agent/config.py
class Settings(BaseSettings):
    # Claude API 配置
    claude_max_retries: int = Field(
        default=5,  # 增加到 5 次（默认 3 次）
        ge=1,
        le=10,
        description="最大重试次数"
    )
    
    claude_retry_base_delay: float = Field(
        default=2.0,  # 基础延迟 2 秒（默认 1 秒）
        ge=0.5,
        le=10.0,
        description="重试基础延迟（秒）"
    )
    
    claude_retry_max_delay: float = Field(
        default=60.0,  # 最大延迟 60 秒
        ge=10.0,
        le=300.0,
        description="重试最大延迟（秒）"
    )
```

**使用方式**（在 `.env` 文件中）：
```bash
CLAUDE_MAX_RETRIES=5
CLAUDE_RETRY_BASE_DELAY=2.0
CLAUDE_RETRY_MAX_DELAY=60.0
```

### 方法 2: 使用指数退避 + 抖动策略

改进重试逻辑，使用更智能的退避策略：

```python
# src/ceo_agent/core/claude_client.py
import random
import asyncio
from anthropic import RateLimitError

async def _call_with_retry(
    self,
    system_prompt: str,
    messages: list[dict[str, str]],
    max_tokens: int,
    temperature: float,
    max_retries: int = 5,
    base_delay: float = 2.0,
    max_delay: float = 60.0,
) -> Any:
    """带重试的 API 调用 - 使用指数退避 + 抖动"""
    
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
            
        except RateLimitError as e:
            if attempt < max_retries - 1:
                # 获取 retry_after（如果 API 提供）
                retry_after = getattr(e, 'retry_after', None)
                
                if retry_after:
                    # 使用 API 建议的等待时间
                    wait_time = retry_after
                else:
                    # 指数退避：2^attempt 秒 (2, 4, 8, 16, 32...)
                    exponential_delay = base_delay * (2 ** attempt)
                    # 添加随机抖动（避免雷群效应）
                    jitter = random.uniform(0, exponential_delay * 0.1)
                    wait_time = min(exponential_delay + jitter, max_delay)
                
                logger.warning(
                    f"Rate limit exceeded (attempt {attempt + 1}/{max_retries}), "
                    f"retrying in {wait_time:.2f}s"
                )
                await asyncio.sleep(wait_time)
                continue
            else:
                raise ClaudeRateLimitError(
                    retry_after=getattr(e, 'retry_after', None)
                )
                
        except (APIError, asyncio.TimeoutError) as e:
            # 其他错误也重试，但延迟时间较短
            if attempt < max_retries - 1:
                delay = base_delay * (1.5 ** attempt)
                logger.warning(
                    f"API call failed (attempt {attempt + 1}/{max_retries}), "
                    f"retrying in {delay:.2f}s: {e}"
                )
                await asyncio.sleep(delay)
                continue
            raise
```

### 方法 3: 使用请求队列和限流器

实现请求队列，避免超过速率限制：

```python
# src/ceo_agent/core/claude_client.py
import asyncio
from collections import deque
from time import time

class ClaudeClient:
    def __init__(self, ...):
        # ... 其他初始化
        self._request_queue = asyncio.Queue()
        self._request_timestamps = deque()  # 记录最近请求的时间戳
        self._max_requests_per_minute = 50  # 根据你的 API 计划调整
        self._semaphore = asyncio.Semaphore(5)  # 最大并发数
        
    async def _wait_for_rate_limit(self):
        """等待直到可以发送请求"""
        now = time()
        minute_ago = now - 60
        
        # 移除一分钟前的请求记录
        while self._request_timestamps and self._request_timestamps[0] < minute_ago:
            self._request_timestamps.popleft()
        
        # 如果超过限制，等待
        if len(self._request_timestamps) >= self._max_requests_per_minute:
            wait_time = 60 - (now - self._request_timestamps[0])
            if wait_time > 0:
                logger.info(f"Rate limit approaching, waiting {wait_time:.2f}s")
                await asyncio.sleep(wait_time)
        
        # 记录当前请求
        self._request_timestamps.append(time())
    
    async def send_message(self, ...):
        """发送消息（带速率限制控制）"""
        # 等待直到可以发送
        await self._wait_for_rate_limit()
        
        # 控制并发数
        async with self._semaphore:
            return await self._call_with_retry(...)
```

### 方法 4: 升级 API 计划

如果频繁遇到限制，考虑升级 Anthropic API 计划：

1. **Pay-as-you-go** → **Pro Plan**
   - 更高的速率限制
   - 更高的配额

2. **联系 Anthropic 支持**
   - 申请更高的速率限制
   - 根据使用情况定制计划

访问：https://console.anthropic.com/settings/plans

### 方法 5: 使用多个 API Key 轮询

如果有多 mind API Key，可以实现轮询机制：

```python
# src/ceo_agent/core/claude_client.py
from typing import List
import random

class ClaudeClientPool:
    """多个 API Key 的客户端池"""
    
    def __init__(self, api_keys: List[str], ...):
        self.clients = [
            AsyncAnthropic(api_key=key, timeout=...)
            for key in api_keys
        ]
        self.current_index = 0
        
    def get_client(self) -> AsyncAnthropic:
        """轮询获取客户端（负载均衡）"""
        client = self.clients[self.current_index]
        self.current_index = (self.current_index + 1) % len(self.clients)
        return client
    
    # 或者随机选择
    def get_random_client(self) -> AsyncAnthropic:
        """随机选择客户端"""
        return random.choice(self.clients)
```

配置方式：
```bash
# .env - 多个 API Key（逗号分隔）
ANTHROPIC_API_KEYS=sk-ant-key1,sk-ant-key2,sk-ant-key3
```

## ⚙️ 完整配置示例

### 环境变量配置（`.env`）

```bash
# Claude API 配置
ANTHROPIC_API_KEY=sk-ant-your-api-key-here

# 重试配置
CLAUDE_MAX_RETRIES=5
CLAUDE_RETRY_BASE_DELAY=2.0
CLAUDE_RETRY_MAX_DELAY=60.0
CLAUDE_REQUEST_TIMEOUT=120

# 速率限制配置
CLAUDE_MAX_REQUESTS_PER_MINUTE=50
CLAUDE_MAX_CONCURRENT_REQUESTS=5

# 多个 API Key（可选）
ANTHROPIC_API_KEYS=sk-ant-key1,sk-ant-key2
```

### 代码配置（`config.py`）

```python
class Settings(BaseSettings):
    # ... 其他配置
    
    # Claude 重试配置
    claude_max_retries: int = Field(default=5, ge=1, le=10)
    claude_retry_base_delay: float = Field(default=2.0, ge=0.5, le=10.0)
    claude_retry_max_delay: float = Field(default=60.0, ge=10.0, le=300.0)
    
    # 速率限制配置
    claude_max_requests_per_minute: int = Field(default=50, ge=10, le=1000)
    claude_max_concurrent_requests: int = Field(default=5, ge=1, le=20)
    
    # 多个 API Key 支持
    anthropic_api_keys: str | None = Field(
        default=None,
        description="多个 API Key，逗号分隔"
    )
    
    @property
    def api_keys_list(self) -> List[str]:
        """获取 API Key 列表"""
        if self.anthropic_api_keys:
            return [key.strip() for key in self.anthropic_api_keys.split(',')]
        return [self.anthropic_api_key]
```

## 📊 监控和日志

添加详细的监控日志：

```python
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

async def send_message(self, ...):
    start_time = datetime.now()
    
    try:
        result = await self._call_with_retry(...)
        
        # 记录成功
        duration = (datetime.now() - start_time).total_seconds()
        logger.info(
            f"Claude API call succeeded. "
            f"Duration: {duration:.2f}s, "
            f"Tokens: {result.usage.input_tokens + result.usage.output_tokens}"
        )
        return result
        
    except ClaudeRateLimitError as e:
        # 记录限制错误
        duration = (datetime.now() - start_time).total_seconds()
        logger.warning(
            f"Claude API rate limit exceeded. "
            f"Duration: {duration:.2f}s, "
            f"Retry after: {e.details.get('retry_after', 'N/A')}s"
        )
        raise
```

## 🎯 最佳实践

1. **始终使用重试机制**：指数退避 + 抖动
2. **监听 retry_after 头**：如果 API 提供，优先使用
3. **实现请求队列**：避免突发请求超过限制
4. **监控使用情况**：记录请求频率和错误率
5. **考虑升级计划**：如果频繁超限，升级 API 计划
6. **实现降级策略**：限制时降低请求频率或返回缓存结果

## 🔍 检查当前限制

访问 Anthropic Console 查看你的限制：
- https://console.anthropic.com/settings/usage

## 📚 参考文档

- [Anthropic API 文档 - 速率限制](https://docs.anthropic.com/claude/reference/rate-limits)
- [Anthropic API 文档 - 错误处理](https://docs.anthropic.com/claude/reference/errors)
