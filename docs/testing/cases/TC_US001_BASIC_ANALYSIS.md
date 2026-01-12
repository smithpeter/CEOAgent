# US-001 测试用例：基础投资分析请求

> **创建日期**: 2026-01-12
> **创建人**: 测试工程师 (QA)
> **关联用户故事**: US_001_basic_analysis.md
> **测试类型**: 功能测试、接口测试

---

## 一、测试概述

### 1.1 测试范围

| 范围 | 说明 |
|------|------|
| 功能 | 决策分析 API 端点 |
| 端点 | POST /api/v1/decision/analyze |
| 验收标准 | AC-1 到 AC-11 (共 11 条) |

### 1.2 测试环境

| 环境 | 配置 |
|------|------|
| 运行环境 | Python 3.11+, pytest |
| 依赖服务 | Claude API (Mock) |
| 测试数据 | evaluation/test_cases/ |

---

## 二、测试用例清单

### 2.1 功能验收测试 (AC-1 ~ AC-5)

#### TC-US001-01: 正常分析请求

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-01 |
| **关联AC** | AC-1, AC-2 |
| **优先级** | P0 |
| **前置条件** | API 服务运行正常，Claude API 可用 |
| **测试数据** | 见下方请求示例 |

**测试步骤**:
1. 发送 POST 请求到 `/api/v1/decision/analyze`
2. 请求体包含有效的 query 和 context
3. 等待响应返回

**请求示例**:
```json
{
  "query": "我们公司Q3业绩下滑，现在有一个扩张投资机会，需要500-1000万，应该如何决策？",
  "context": {
    "company_financials": {
      "Q1": {"revenue": 1200, "profit": 180, "cash_flow": 150},
      "Q2": {"revenue": 1350, "profit": 210, "cash_flow": 180},
      "Q3": {"revenue": 1100, "profit": 95, "cash_flow": 40},
      "cash_reserve": 800
    }
  }
}
```

**预期结果**:
- [ ] HTTP 状态码 = 200
- [ ] 响应时间 < 30 秒
- [ ] `success` = true
- [ ] `data.result.situation_analysis` 存在且非空
- [ ] `data.result.risk_assessment` 存在且非空
- [ ] `data.result.recommendations` 存在且非空
- [ ] `data.result.final_recommendation` 存在且非空
- [ ] `metadata.execution_time_ms` 存在

---

#### TC-US001-02: 风险评分验证

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-02 |
| **关联AC** | AC-3 |
| **优先级** | P0 |
| **前置条件** | TC-US001-01 通过 |

**测试步骤**:
1. 执行 TC-US001-01 获取响应
2. 验证风险评分字段

**预期结果**:
- [ ] `data.result.risk_assessment.overall_score` 存在
- [ ] 风险评分 ≥ 1 且 ≤ 10
- [ ] 风险评分为整数
- [ ] `data.result.risk_assessment.risk_factors` 为数组
- [ ] 每个风险因素包含 `name`, `level`, `reason`

---

#### TC-US001-03: 方案数量验证

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-03 |
| **关联AC** | AC-4 |
| **优先级** | P0 |
| **前置条件** | TC-US001-01 通过 |

**测试步骤**:
1. 执行 TC-US001-01 获取响应
2. 验证推荐方案数量和结构

**预期结果**:
- [ ] `data.result.recommendations` 长度 ≥ 2
- [ ] 每个方案包含 `title`
- [ ] 每个方案包含 `risk_level` (low/medium/high)
- [ ] 每个方案包含 `pros` 数组
- [ ] 每个方案包含 `cons` 数组
- [ ] 每个方案包含 `action_steps` 数组

---

#### TC-US001-04: 最终建议验证

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-04 |
| **关联AC** | AC-5 |
| **优先级** | P0 |
| **前置条件** | TC-US001-01 通过 |

**测试步骤**:
1. 执行 TC-US001-01 获取响应
2. 验证最终建议结构

**预期结果**:
- [ ] `data.result.final_recommendation.choice` 存在且非空
- [ ] `data.result.final_recommendation.reasoning` 存在且非空
- [ ] `choice` 与 `recommendations` 中某个方案对应

---

### 2.2 输入验证测试 (AC-6 ~ AC-8)

#### TC-US001-05: 空查询验证

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-05 |
| **关联AC** | AC-6 |
| **优先级** | P0 |
| **测试类型** | 异常测试 |

**测试步骤**:
1. 发送请求，query 为空字符串
2. 验证错误响应

**请求示例**:
```json
{
  "query": ""
}
```

**预期结果**:
- [ ] HTTP 状态码 = 400
- [ ] `success` = false
- [ ] `error.code` = "INVALID_INPUT"
- [ ] `error.message` 包含 "query field is required"

---

#### TC-US001-06: 空查询验证 (null)

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-06 |
| **关联AC** | AC-6 |
| **优先级** | P0 |
| **测试类型** | 异常测试 |

**测试步骤**:
1. 发送请求，不包含 query 字段
2. 验证错误响应

**请求示例**:
```json
{
  "context": {}
}
```

**预期结果**:
- [ ] HTTP 状态码 = 400 或 422
- [ ] `success` = false
- [ ] 错误信息指明 query 字段缺失

---

#### TC-US001-07: 超长查询验证

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-07 |
| **关联AC** | AC-7 |
| **优先级** | P0 |
| **测试类型** | 边界测试 |

**测试步骤**:
1. 发送请求，query 长度 = 10001 字符
2. 验证错误响应

**请求示例**:
```json
{
  "query": "A" * 10001
}
```

**预期结果**:
- [ ] HTTP 状态码 = 400
- [ ] `success` = false
- [ ] `error.code` = "INVALID_INPUT"
- [ ] `error.message` 包含 "exceeds maximum length"

---

#### TC-US001-08: 边界长度查询 (10000字符)

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-08 |
| **关联AC** | AC-7 |
| **优先级** | P1 |
| **测试类型** | 边界测试 |

**测试步骤**:
1. 发送请求，query 长度 = 10000 字符
2. 验证请求成功处理

**预期结果**:
- [ ] HTTP 状态码 = 200
- [ ] `success` = true

---

#### TC-US001-09: Context 格式错误

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-09 |
| **关联AC** | AC-8 |
| **优先级** | P1 |
| **测试类型** | 异常测试 |

**测试步骤**:
1. 发送请求，context 为非 JSON 对象
2. 验证错误响应

**请求示例**:
```json
{
  "query": "测试问题",
  "context": "invalid string"
}
```

**预期结果**:
- [ ] HTTP 状态码 = 400 或 422
- [ ] `success` = false
- [ ] 错误信息指明 context 格式问题

---

### 2.3 错误处理测试 (AC-9 ~ AC-11)

#### TC-US001-10: Claude API 超时

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-10 |
| **关联AC** | AC-9 |
| **优先级** | P0 |
| **测试类型** | 异常测试 |
| **测试方式** | Mock Claude API 模拟超时 |

**测试步骤**:
1. Mock Claude API 返回延迟 > 60 秒
2. 发送正常请求
3. 验证超时响应

**预期结果**:
- [ ] HTTP 状态码 = 504
- [ ] `success` = false
- [ ] `error.code` = "TIMEOUT"

---

#### TC-US001-11: Claude API 错误

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-11 |
| **关联AC** | AC-10 |
| **优先级** | P0 |
| **测试类型** | 异常测试 |
| **测试方式** | Mock Claude API 返回 500 |

**测试步骤**:
1. Mock Claude API 返回 500 错误
2. 发送正常请求
3. 验证错误响应

**预期结果**:
- [ ] HTTP 状态码 = 502
- [ ] `success` = false
- [ ] `error.code` = "LLM_ERROR"
- [ ] `error.message` 包含原始错误信息

---

#### TC-US001-12: 响应解析失败

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-12 |
| **关联AC** | AC-11 |
| **优先级** | P0 |
| **测试类型** | 异常测试 |
| **测试方式** | Mock Claude API 返回无效格式 |

**测试步骤**:
1. Mock Claude API 返回无法解析的响应
2. 发送正常请求
3. 验证错误响应

**预期结果**:
- [ ] HTTP 状态码 = 500
- [ ] `success` = false
- [ ] `error.code` = "PARSE_ERROR"

---

### 2.4 性能测试

#### TC-US001-13: 响应时间测试

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-13 |
| **关联AC** | AC-1 |
| **优先级** | P0 |
| **测试类型** | 性能测试 |

**测试步骤**:
1. 执行 10 次正常请求
2. 记录每次响应时间
3. 计算 P95 响应时间

**预期结果**:
- [ ] P95 响应时间 < 30 秒
- [ ] 所有请求响应时间 < 60 秒
- [ ] 无超时错误

---

### 2.5 端到端测试

#### TC-US001-14: 完整业务流程

| 项目 | 内容 |
|------|------|
| **用例ID** | TC-US001-14 |
| **优先级** | P0 |
| **测试类型** | E2E 测试 |

**测试步骤**:
1. 使用真实 Claude API
2. 发送投资决策分析请求
3. 验证完整响应结构
4. 验证响应内容业务合理性

**测试数据**: 使用 US-001 文档中的示例输入

**预期结果**:
- [ ] 响应成功
- [ ] 态势分析与输入数据相关
- [ ] 风险评分合理（考虑到 Q3 下滑）
- [ ] 方案建议可执行
- [ ] 最终建议有明确理由

---

## 三、测试用例追踪

### 3.1 验收标准覆盖

| AC编号 | 测试用例 | 状态 |
|--------|---------|------|
| AC-1 | TC-US001-01, TC-US001-13 | ⏳ |
| AC-2 | TC-US001-01 | ⏳ |
| AC-3 | TC-US001-02 | ⏳ |
| AC-4 | TC-US001-03 | ⏳ |
| AC-5 | TC-US001-04 | ⏳ |
| AC-6 | TC-US001-05, TC-US001-06 | ⏳ |
| AC-7 | TC-US001-07, TC-US001-08 | ⏳ |
| AC-8 | TC-US001-09 | ⏳ |
| AC-9 | TC-US001-10 | ⏳ |
| AC-10 | TC-US001-11 | ⏳ |
| AC-11 | TC-US001-12 | ⏳ |

### 3.2 测试用例统计

| 类型 | 数量 |
|------|------|
| 功能测试 | 4 |
| 输入验证 | 5 |
| 错误处理 | 3 |
| 性能测试 | 1 |
| E2E 测试 | 1 |
| **总计** | **14** |

---

## 四、自动化测试代码框架

### 4.1 pytest 测试结构

```python
# tests/test_api_analyze.py
import pytest
from httpx import AsyncClient

class TestAnalyzeEndpoint:
    """决策分析 API 测试"""
    
    @pytest.mark.asyncio
    async def test_normal_analysis_request(self, client: AsyncClient):
        """TC-US001-01: 正常分析请求"""
        response = await client.post(
            "/api/v1/analyze",
            json={
                "query": "我们公司Q3业绩下滑...",
                "context": {...}
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] == True
        assert "situation_analysis" in data["data"]["result"]
        assert "risk_assessment" in data["data"]["result"]
        assert "recommendations" in data["data"]["result"]
        assert "final_recommendation" in data["data"]["result"]
    
    @pytest.mark.asyncio
    async def test_risk_score_range(self, client: AsyncClient):
        """TC-US001-02: 风险评分范围验证"""
        response = await client.post(
            "/api/v1/analyze",
            json={"query": "测试问题"}
        )
        
        data = response.json()
        score = data["data"]["result"]["risk_assessment"]["overall_score"]
        assert 1 <= score <= 10
    
    @pytest.mark.asyncio
    async def test_empty_query(self, client: AsyncClient):
        """TC-US001-05: 空查询验证"""
        response = await client.post(
            "/api/v1/analyze",
            json={"query": ""}
        )
        
        assert response.status_code == 400
        data = response.json()
        assert data["success"] == False
        assert data["error"]["code"] == "INVALID_INPUT"
    
    @pytest.mark.asyncio
    async def test_query_exceeds_max_length(self, client: AsyncClient):
        """TC-US001-07: 超长查询验证"""
        response = await client.post(
            "/api/v1/analyze",
            json={"query": "A" * 10001}
        )
        
        assert response.status_code == 400
        data = response.json()
        assert "exceeds maximum length" in data["error"]["message"]
```

### 4.2 Mock 配置

```python
# tests/conftest.py
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
def mock_claude_success():
    """Mock 成功的 Claude API 响应"""
    mock_response = {
        "situation_analysis": {
            "summary": "测试摘要",
            "key_findings": ["发现1", "发现2"]
        },
        "risk_assessment": {
            "overall_score": 7,
            "risk_factors": [...]
        },
        "recommendations": [
            {"title": "方案A", ...},
            {"title": "方案B", ...}
        ],
        "final_recommendation": {
            "choice": "方案A",
            "reasoning": "推荐理由"
        }
    }
    
    with patch("ceo_agent.core.claude_client.ClaudeClient.complete") as mock:
        mock.return_value = (json.dumps(mock_response), {"total_tokens": 1000})
        yield mock

@pytest.fixture
def mock_claude_timeout():
    """Mock Claude API 超时"""
    with patch("ceo_agent.core.claude_client.ClaudeClient.complete") as mock:
        mock.side_effect = TimeoutError("Request timeout")
        yield mock
```

---

## 五、验证结论

✅ **测试用例设计完成**

- 14 个测试用例覆盖所有 11 条验收标准
- 包含功能测试、输入验证、错误处理、性能测试、E2E 测试
- 提供 pytest 自动化测试代码框架
- 测试追踪矩阵完整

---

## 更新日志

| 日期 | 修改内容 | 修改人 |
|------|---------|--------|
| 2026-01-12 | 创建 US-001 测试用例 | QA |
