# Phase 1 MVP 任务分解

> **创建日期**: 2026-01-12
> **创建人**: 开发经理 (Dev Manager)
> **关联文档**: MASTER_PLAN.md, TASKS.md

---

## 一、Phase 1 概述

### 1.1 目标

实现可运行的 MVP API，能接受决策问题并返回结构化分析结果。

### 1.2 范围

| 包含 | 不包含 |
|------|--------|
| 决策分析 API | Skill 系统 |
| 结构化输出 | Tool Calling |
| 内存会话存储 | 数据库持久化 |
| 基础错误处理 | 用户认证 |
| 单元/集成测试 | WebSocket |

### 1.3 时间规划

| 阶段 | 天数 | 任务 |
|------|------|------|
| Day 1 | 1 | 项目骨架 + 配置 |
| Day 2 | 1 | Claude 客户端 + Prompt 管理 |
| Day 3 | 1 | AgentCore + 响应解析 |
| Day 4 | 1 | API 路由 + Memory |
| Day 5 | 1 | 测试 + 评估 |

---

## 二、任务详细设计

### #101 项目骨架搭建

**描述**: 创建符合 MASTER_PLAN 定义的项目目录结构

**产出**:
```
ceoagent/
├── src/
│   └── ceo_agent/
│       ├── __init__.py
│       ├── main.py
│       ├── config.py
│       ├── core/
│       │   └── __init__.py
│       └── api/
│           └── __init__.py
├── prompts/
│   └── v1/
├── tests/
│   └── __init__.py
├── evaluation/
├── pyproject.toml
├── requirements.txt
├── .env.example
└── .gitignore
```

**验收清单**:
- [ ] 目录结构完整
- [ ] pyproject.toml 配置正确
- [ ] requirements.txt 包含依赖
- [ ] .env.example 包含配置模板

---

### #102 配置管理模块

**描述**: 实现配置加载和验证

**技术方案**:
```python
# src/ceo_agent/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """应用配置"""
    # API 配置
    anthropic_api_key: str
    model_name: str = "claude-3-5-sonnet-20241022"
    
    # 服务配置
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    
    # 限制配置
    max_query_length: int = 10000
    request_timeout: int = 60
    max_retries: int = 3
    
    class Config:
        env_file = ".env"
```

**验收清单**:
- [ ] Pydantic Settings 验证
- [ ] 环境变量加载
- [ ] 默认值合理
- [ ] 敏感配置不硬编码

---

### #103 Claude API 客户端

**描述**: 封装 Anthropic Claude API 调用

**技术方案**:
```python
# src/ceo_agent/core/claude_client.py
from anthropic import Anthropic
from typing import AsyncIterator

class ClaudeClient:
    """Claude API 客户端"""
    
    def __init__(self, api_key: str, model: str):
        self.client = Anthropic(api_key=api_key)
        self.model = model
    
    async def complete(
        self,
        system_prompt: str,
        user_message: str,
        max_tokens: int = 4096
    ) -> tuple[str, dict]:
        """
        调用 Claude API
        
        Returns:
            (response_text, usage_stats)
        """
        pass
    
    async def complete_with_retry(
        self,
        system_prompt: str,
        user_message: str,
        max_retries: int = 3
    ) -> tuple[str, dict]:
        """带重试的 API 调用"""
        pass
```

**验收清单**:
- [ ] 异步调用支持
- [ ] 超时处理 (60s)
- [ ] 重试机制 (3次，指数退避)
- [ ] Token 使用统计
- [ ] 错误分类处理

---

### #104 Prompt 管理器

**描述**: 管理 Prompt 模板，支持变量替换

**技术方案**:
```python
# src/ceo_agent/core/prompt_manager.py
from pathlib import Path
from string import Template

class PromptManager:
    """Prompt 模板管理"""
    
    def __init__(self, prompts_dir: Path):
        self.prompts_dir = prompts_dir
        self._templates = {}
        self._load_templates()
    
    def _load_templates(self):
        """加载所有模板"""
        pass
    
    def get_system_prompt(self) -> str:
        """获取系统 Prompt"""
        pass
    
    def build_user_message(
        self,
        query: str,
        context: dict | None = None
    ) -> str:
        """构建用户消息"""
        pass
```

**验收清单**:
- [ ] 加载 prompts/v1/ 目录
- [ ] 支持 Template 变量替换
- [ ] 支持 JSON context 格式化
- [ ] 模板缓存

---

### #105 响应解析器

**描述**: 解析 Claude 返回的结构化响应

**技术方案**:
```python
# src/ceo_agent/core/response_parser.py
from pydantic import BaseModel
from typing import List

class SituationAnalysis(BaseModel):
    summary: str
    key_findings: List[str]

class RiskAssessment(BaseModel):
    overall_score: int  # 1-10
    risk_factors: List[dict]

class Recommendation(BaseModel):
    title: str
    investment_amount: str | None
    risk_level: str
    pros: List[str]
    cons: List[str]
    action_steps: List[str]

class AnalysisResult(BaseModel):
    situation_analysis: SituationAnalysis
    risk_assessment: RiskAssessment
    recommendations: List[Recommendation]
    final_recommendation: dict

class ResponseParser:
    """响应解析器"""
    
    def parse(self, response_text: str) -> AnalysisResult:
        """
        解析 Claude 响应
        
        Args:
            response_text: Claude 返回的文本
            
        Returns:
            结构化分析结果
            
        Raises:
            ParseError: 解析失败
        """
        pass
    
    def _extract_json(self, text: str) -> dict:
        """从文本中提取 JSON"""
        pass
    
    def _validate_structure(self, data: dict) -> bool:
        """验证数据结构完整性"""
        pass
```

**验收清单**:
- [ ] JSON 提取（支持 markdown code block）
- [ ] Pydantic 模型验证
- [ ] 容错处理（部分字段缺失）
- [ ] 错误信息清晰

---

### #106 AgentCore 核心逻辑

**描述**: 整合各模块，实现决策分析核心流程

**技术方案**:
```python
# src/ceo_agent/core/agent.py
from .claude_client import ClaudeClient
from .prompt_manager import PromptManager
from .response_parser import ResponseParser
from .memory import MemoryStore

class AgentCore:
    """Agent 核心"""
    
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
        pass
```

**验收清单**:
- [ ] 完整流程串联
- [ ] 会话上下文管理
- [ ] 错误处理链
- [ ] 执行时间统计

---

### #107 API 路由实现

**描述**: 实现 REST API 端点

**技术方案**:
```python
# src/ceo_agent/api/routes.py
from fastapi import APIRouter, HTTPException
from .schemas import AnalyzeRequest, AnalyzeResponse

router = APIRouter(prefix="/api/v1")

@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_decision(request: AnalyzeRequest):
    """决策分析端点"""
    pass

@router.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy"}
```

**验收清单**:
- [ ] POST /api/v1/analyze 实现
- [ ] 请求验证
- [ ] 响应格式正确
- [ ] 错误码正确
- [ ] OpenAPI 文档可访问

---

### #108 单元测试

**描述**: 编写核心模块单元测试

**测试范围**:

| 模块 | 测试文件 | 测试用例 |
|------|---------|---------|
| ClaudeClient | test_claude_client.py | 正常调用、超时、重试 |
| PromptManager | test_prompt_manager.py | 模板加载、变量替换 |
| ResponseParser | test_response_parser.py | 正常解析、容错、验证 |
| AgentCore | test_agent.py | 完整流程、错误处理 |
| API Routes | test_api.py | 端点测试、验证测试 |

**验收清单**:
- [ ] 测试覆盖率 > 80%
- [ ] Mock 外部依赖
- [ ] 所有测试通过

---

### #109 集成测试与评估

**描述**: 端到端测试和质量评估

**评估脚本**:
```python
# evaluation/run_eval.py

def calculate_score(response, expected):
    """计算评估得分"""
    score = 0
    
    # 完整性 (40分)
    if response.situation_analysis:
        score += 10
    if response.risk_score is not None:
        score += 10
    if len(response.recommendations) >= 2:
        score += 10
    if response.final_recommendation:
        score += 10
    
    # 准确性 (30分)
    # ...
    
    # 可行性 (30分)
    # ...
    
    return score
```

**验收清单**:
- [ ] API 端到端测试通过
- [ ] 10+ 测试用例
- [ ] 评估得分 > 60%
- [ ] 响应时间 < 30s

---

## 三、依赖关系

```
#101 项目骨架
  │
  ├─→ #102 配置管理 ─→ #103 Claude 客户端 ─┐
  │                                         │
  ├─→ #104 Prompt 管理 ─────────────────────┼─→ #106 AgentCore
  │                                         │
  └─→ #110 Memory 存储 ─────────────────────┘
                                            │
  #103 ─→ #105 响应解析 ────────────────────┘
                                            │
                                            ▼
                                      #107 API 路由
                                            │
                              ┌─────────────┼─────────────┐
                              │             │             │
                              ▼             ▼             ▼
                         #108 单元测试  #109 集成测试  #111 健康检查
```

---

## 四、验收标准

### Phase 1 整体验收

| 项目 | 标准 | 验证方法 |
|------|------|---------|
| 服务启动 | `uvicorn` 无错误启动 | 命令行 |
| API 可用 | `/analyze` 返回正确格式 | curl 测试 |
| 测试通过 | 所有测试通过 | `pytest` |
| 响应质量 | 评估得分 > 60% | `run_eval.py` |
| 响应时间 | P95 < 30s | 性能测试 |
| 文档 | `/docs` 可访问 | 浏览器 |

### 验收测试命令

```bash
# 1. 启动服务
uvicorn src.ceo_agent.main:app --host 0.0.0.0 --port 8000

# 2. 健康检查
curl http://localhost:8000/api/v1/health

# 3. 决策分析测试
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "Should we expand to new markets?"}'

# 4. 运行测试
pytest tests/ -v

# 5. 运行评估
python evaluation/run_eval.py
```

---

## 五、技术债务记录

| ID | 描述 | 影响 | 计划解决 |
|----|------|------|---------|
| TD-001 | 内存存储无持久化 | 重启丢失数据 | Phase 2 |
| TD-002 | 无用户认证 | 安全风险 | Phase 2 |
| TD-003 | 单进程部署 | 性能瓶颈 | Phase 2 |

---

## 六、检查清单

### 开始 Phase 1 前

- [x] Phase 0 文档验证完成
- [x] 架构方案确认
- [x] 任务分解完成
- [ ] CEO 确认启动

### Phase 1 完成时

- [ ] 所有任务 DONE
- [ ] 测试覆盖率 > 80%
- [ ] 评估得分 > 60%
- [ ] 文档更新
- [ ] QA 验证通过

---

## 更新日志

| 日期 | 修改内容 | 修改人 |
|------|---------|--------|
| 2026-01-12 | 创建 Phase 1 任务分解 | DevMgr |
