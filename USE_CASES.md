# CEOAgent 用例定义与验证文档

## 文档目的

本文档从**项目使用者**视角，详细定义所有用例（Use Cases），包括用户故事、验收标准、测试场景，确保系统能够达到项目目标。

---

## 1. 用例分类体系

### 1.1 用例优先级

- **P0（核心用例）**：MVP 必须实现，直接影响项目目标
- **P1（重要用例）**：第一版本实现，提升核心价值
- **P2（增强用例）**：后续版本实现，优化体验

### 1.2 用例分类

```
CEOAgent 用例体系
├── 决策支持用例
│   ├── UC-001: 快速决策分析
│   ├── UC-002: 深度数据分析
│   ├── UC-003: 多方案对比
│   └── UC-004: 风险评估
├── 智能交互用例
│   ├── UC-005: 自然语言对话
│   ├── UC-006: 上下文理解
│   └── UC-007: 多模态输入
├── 知识管理用例
│   ├── UC-008: 知识检索
│   ├── UC-009: 历史决策查询
│   └── UC-010: 学习反馈
└── 系统管理用例
    ├── UC-011: 数据源配置
    ├── UC-012: 权限管理
    └── UC-013: 报告导出
```

---

## 2. 核心用例详细定义

### UC-001: 快速决策分析 ⭐ P0

#### 2.1 用户故事

**作为** CEO  
**我想要** 快速启动一次决策分析并获得建议  
**以便于** 在有限时间内做出重要决策

#### 2.2 用例描述

**触发条件：**
- 用户打开"决策分析中心"
- 点击"创建新分析"按钮

**前置条件：**
- 用户已登录
- 系统已配置基础数据源（可选）

**基本流程：**
1. 用户选择决策类型（投资/战略/危机/资源配置）
2. 用户输入基本信息（标题、优先级、预算范围）
3. 用户输入财务数据（手动输入或上传文件）
4. 用户确认并提交分析请求
5. 系统显示分析进度（实时更新）
6. 系统生成决策分析结果
7. 用户查看结果（态势分析、风险评分、方案建议）

**异常流程：**
- **异常1**：数据格式错误
  - 系统提示错误位置
  - 提供修正建议
  - 用户修正后重新提交

- **异常2**：分析超时（> 5分钟）
  - 系统提示超时
  - 提供重试选项
  - 保存已输入数据

#### 2.3 验收标准

**功能性标准：**
- [ ] 用户能在 3 步内完成输入
- [ ] 分析结果在 5 分钟内生成（90% 用例）
- [ ] 结果包含：态势分析、风险评分、至少 2 个方案
- [ ] 支持文件上传（Excel、CSV）

**性能标准：**
- [ ] 页面加载时间 < 2 秒
- [ ] 分析响应时间 < 5 分钟（P95）
- [ ] 支持并发 10+ 用户同时分析

**可用性标准：**
- [ ] 移动端可用（响应式设计）
- [ ] 错误提示清晰明确
- [ ] 进度显示实时更新

#### 2.4 测试场景

**场景 1.1：正常流程 - 投资决策**
```
Given: 用户已登录，打开决策分析中心
When: 
  1. 选择决策类型 "投资决策"
  2. 输入标题 "Q3 扩张投资"
  3. 输入预算范围 "500万-1000万"
  4. 上传财务数据文件（Excel）
  5. 点击"开始分析"
Then:
  1. 系统显示"分析中..."进度条
  2. 30秒后显示"态势分析完成"
  3. 2分钟后显示完整结果
  4. 结果包含：
     - 态势分析摘要（150字以内）
     - 风险评分（7/10）
     - 3个投资方案
     - 推荐方案标识
```

**场景 1.2：异常流程 - 数据格式错误**
```
Given: 用户在步骤3上传文件
When: 上传格式错误的文件（如 PDF 非 Excel）
Then:
  1. 系统立即提示"文件格式错误"
  2. 提示"请上传 Excel (.xlsx) 或 CSV (.csv) 文件"
  3. 提供示例文件下载链接
  4. 用户可以重新上传
```

**场景 1.3：边界条件 - 极大数据集**
```
Given: 用户上传包含 10万行数据的 Excel 文件
When: 点击"开始分析"
Then:
  1. 系统提示"数据量较大，预计分析时间 8-10 分钟"
  2. 用户可选择：
     - 继续分析
     - 使用数据采样（前1000行）
     - 取消
```

---

### UC-002: 深度数据分析 ⭐ P1

#### 2.1 用户故事

**作为** 数据分析师  
**我想要** 对数据进行深度分析（趋势、异常、预测）  
**以便于** 为 CEO 提供更详细的数据洞察

#### 2.2 用例描述

**基本流程：**
1. 用户选择数据源（财务/市场/运营）
2. 用户选择分析维度（时间序列、同比、环比）
3. 用户选择分析方法（趋势分析、异常检测、预测模型）
4. 系统执行分析
5. 系统生成可视化图表和洞察报告
6. 用户可下载详细报告（PDF/Excel）

#### 2.3 验收标准

- [ ] 支持多种图表类型（折线图、柱状图、热力图）
- [ ] 自动识别异常值并标注
- [ ] 支持数据导出（Excel、PDF）
- [ ] 图表支持交互（hover、筛选、缩放）

---

### UC-005: 自然语言对话 ⭐ P0

#### 2.1 用户故事

**作为** CEO  
**我想要** 用自然语言提问并获得即时回答  
**以便于** 快速获取决策支持，无需学习复杂界面

#### 2.2 用例描述

**基本流程：**
1. 用户打开"智能对话"页面
2. 用户在输入框输入问题（如："帮我分析一下 Q3 的投资机会"）
3. 系统显示"正在思考..."
4. 系统流式输出回答（逐字显示）
5. 系统提供相关图表和数据引用
6. 用户可以继续追问或开始新话题

**对话示例：**
```
用户: 帮我分析一下 Q3 的投资机会

AI: [思考中...]
    根据您 Q3 的财务数据，我发现了以下投资机会：
    
    1. 现金流较为充裕（当前储备 800万），可以考虑扩张投资
    2. Q3 收入下滑（1100万 vs Q2 1350万），需要谨慎评估
    
    [显示财务趋势图表]
    
    基于这些数据，我建议：
    - 如果选择投资，预算控制在 500-800万
    - 优先考虑轻资产扩张（避免现金流压力）
    
    需要我生成详细的分析报告吗？

用户: 生成报告，重点分析风险

AI: [正在生成报告...]
    已为您生成包含风险评估的详细报告：
    - 总体风险评分：7/10（中等风险）
    - 主要风险因子：
      1. 现金流风险（高）- Q3 现金流明显下滑
      2. 市场风险（中）- 行业整体增速放缓
      3. 竞争风险（低）- 主要竞品表现稳定
    ...
```

#### 2.3 验收标准

**功能性标准：**
- [ ] 支持中文自然语言理解
- [ ] 响应时间 < 10 秒（首次响应）
- [ ] 支持上下文记忆（至少 10 轮对话）
- [ ] 支持引用历史数据（"上次分析的结果"）

**可用性标准：**
- [ ] 流式输出（类似 ChatGPT）
- [ ] 支持 Markdown 渲染（标题、列表、代码块）
- [ ] 支持图表内嵌显示
- [ ] 支持语音输入（可选，移动端）

#### 2.4 测试场景

**场景 5.1：正常对话**
```
Given: 用户打开对话界面
When: 输入 "分析 Q3 财务数据"
Then:
  1. 3秒内显示"正在分析..."
  2. 10秒内开始流式输出结果
  3. 结果包含：
     - 文字分析
     - 财务趋势图表
     - 关键指标摘要
```

**场景 5.2：上下文记忆**
```
Given: 用户已询问 "分析 Q3 财务数据"
When: 继续追问 "风险如何？"
Then:
  1. AI 理解"风险"指的是 Q3 财务数据的风险
  2. 不要求用户重新输入财务数据
  3. 直接基于之前的分析给出风险评估
```

**场景 5.3：多轮对话**
```
Given: 用户已完成一次投资决策分析
When: 
  1. 用户问："上次分析的结果如何？"
  2. 用户问："能否对比一下方案A和方案B？"
Then:
  1. AI 能引用之前的分析结果
  2. AI 能对比具体方案
  3. 保持对话连贯性
```

---

### UC-008: 知识检索 ⭐ P1

#### 2.1 用户故事

**作为** CEO  
**我想要** 检索相关的历史决策案例和行业知识  
**以便于** 参考类似情况做出决策

#### 2.2 用例描述

**基本流程：**
1. 用户在知识库页面输入查询（如："类似的投资案例"）
2. 系统进行语义检索（RAG）
3. 系统返回相关文档、案例、报告
4. 用户点击查看详情
5. 用户可以引用到当前决策分析中

#### 2.3 验收标准

- [ ] 支持语义搜索（不只是关键词匹配）
- [ ] 检索结果按相关性排序
- [ ] 显示结果来源和引用
- [ ] 支持筛选（按类型、时间、来源）

---

## 3. 用例优先级矩阵

| 用例ID | 用例名称 | 优先级 | 难度 | 价值 | 预计工时 |
|--------|---------|--------|------|------|----------|
| UC-001 | 快速决策分析 | P0 | 高 | 极高 | 3周 |
| UC-005 | 自然语言对话 | P0 | 高 | 极高 | 2周 |
| UC-004 | 风险评估 | P0 | 中 | 高 | 1周 |
| UC-003 | 多方案对比 | P1 | 中 | 高 | 1周 |
| UC-008 | 知识检索 | P1 | 高 | 中 | 2周 |
| UC-002 | 深度数据分析 | P1 | 中 | 中 | 1.5周 |
| UC-006 | 上下文理解 | P1 | 高 | 中 | 1周 |
| UC-009 | 历史决策查询 | P2 | 低 | 中 | 0.5周 |
| UC-013 | 报告导出 | P2 | 低 | 中 | 0.5周 |

---

## 4. 用例验收测试用例

### 4.1 测试用例模板

```gherkin
Feature: UC-001 快速决策分析
  As a CEO
  I want to quickly start a decision analysis
  So that I can make informed decisions

  Background:
    Given I am logged in as CEO
    And I am on the "Decision Center" page

  Scenario: 成功完成一次投资决策分析
    Given I have financial data ready (Excel file)
    When I select "Investment Decision" as decision type
    And I enter title "Q3 Expansion Investment"
    And I enter budget range "500万-1000万"
    And I upload the financial data file
    And I click "Start Analysis"
    Then I should see "Analysis in progress..." message
    And I should see progress indicator updating
    And within 5 minutes, I should see analysis results
    And the results should contain:
      | Section            | Required |
      | Situation Analysis | Yes      |
      | Risk Score         | Yes      |
      | Recommendations    | Yes (≥2) |
      | Action Steps       | Yes      |
    And I should be able to export the report

  Scenario: 处理数据格式错误
    Given I have an invalid file (PDF instead of Excel)
    When I upload the file
    Then I should see error message "Invalid file format"
    And I should see hint "Please upload Excel (.xlsx) or CSV (.csv)"
    And I should be able to upload another file
```

### 4.2 自动化测试用例

```python
# tests/e2e/test_uc001_quick_decision.py

import pytest
from playwright.sync_api import Page, expect

@pytest.mark.e2e
def test_quick_decision_analysis(page: Page):
    """测试 UC-001: 快速决策分析"""
    
    # Given: 用户已登录
    page.goto("/login")
    page.fill("#username", "ceo@example.com")
    page.fill("#password", "password")
    page.click("button[type=submit]")
    
    # When: 创建新分析
    page.goto("/decision-center")
    page.click("text=创建新分析")
    
    # 步骤1: 选择决策类型
    page.click("text=投资决策")
    page.click("button:has-text('下一步')")
    
    # 步骤2: 输入信息
    page.fill("#title", "Q3 扩张投资")
    page.fill("#budget-min", "500")
    page.fill("#budget-max", "1000")
    page.click("button:has-text('下一步')")
    
    # 步骤3: 上传文件
    page.set_input_files("#file-upload", "test_data/financial_data.xlsx")
    page.click("button:has-text('开始分析')")
    
    # Then: 验证结果
    expect(page.locator("text=分析中...")).to_be_visible()
    
    # 等待结果（最多5分钟）
    expect(page.locator(".analysis-result")).to_be_visible(timeout=300000)
    
    # 验证必需内容
    expect(page.locator(".situation-analysis")).to_be_visible()
    expect(page.locator(".risk-score")).to_be_visible()
    expect(page.locator(".recommendation-card")).to_have_count(greater_than_or_equal=2)
    
    # 验证可以导出
    expect(page.locator("button:has-text('导出报告')")).to_be_visible()
```

---

## 5. 用例验证方法

### 5.1 验证层次

```
验证层次
├── 单元测试（Unit Test）
│   └── 测试单个功能模块（Skill、API）
├── 集成测试（Integration Test）
│   └── 测试模块间交互（Agent → Skill → LLM）
├── 系统测试（System Test）
│   └── 测试完整用例流程（端到端）
└── 用户验收测试（UAT）
    └── 真实用户验证（可用性测试）
```

### 5.2 验证指标

**功能正确性：**
- ✅ 用例执行成功率 ≥ 95%
- ✅ 异常处理覆盖率 100%
- ✅ 边界条件测试通过率 100%

**性能指标：**
- ✅ 响应时间满足要求（见各用例验收标准）
- ✅ 并发支持（10+ 用户同时使用）
- ✅ 错误率 < 1%

**用户体验：**
- ✅ 任务完成率 ≥ 80%（用户测试）
- ✅ 用户满意度 ≥ 4.0/5.0（NPS）
- ✅ 平均学习时间 < 10 分钟

---

## 6. 用例执行计划

### 6.1 MVP 阶段（Week 1-8）

**目标：** 实现核心用例（P0）

**用例清单：**
- [ ] UC-001: 快速决策分析
- [ ] UC-005: 自然语言对话
- [ ] UC-004: 风险评估

**验收标准：**
- 所有 P0 用例测试通过率 100%
- 用户验收测试通过（至少 5 名目标用户）

### 6.2 V1.0 阶段（Week 9-12）

**目标：** 实现重要用例（P1）

**用例清单：**
- [ ] UC-003: 多方案对比
- [ ] UC-008: 知识检索
- [ ] UC-002: 深度数据分析
- [ ] UC-006: 上下文理解

### 6.3 V1.1 阶段（Week 13+）

**目标：** 增强功能（P2）

**用例清单：**
- [ ] UC-009: 历史决策查询
- [ ] UC-013: 报告导出
- [ ] UC-010: 学习反馈

---

## 7. 用例测试数据

### 7.1 测试数据集

**财务数据样例：**
```json
{
  "quarterly_financials": {
    "Q1": {
      "revenue": 12000000,
      "profit": 1800000,
      "cash_flow": 1500000
    },
    "Q2": {
      "revenue": 13500000,
      "profit": 2100000,
      "cash_flow": 1800000
    },
    "Q3": {
      "revenue": 11000000,
      "profit": 950000,
      "cash_flow": 400000
    }
  },
  "current_cash_reserve": 8000000
}
```

**决策场景样例：**
```json
{
  "decision_type": "investment",
  "title": "Q3 扩张投资决策",
  "budget_range": {
    "min": 5000000,
    "max": 10000000
  },
  "investment_target": "区域分公司扩张",
  "expected_return_period": "12-18个月"
}
```

### 7.2 预期输出样例

**决策分析结果：**
```json
{
  "situation_analysis": {
    "summary": "公司 Q3 财务表现下滑，但现金流储备充足（800万），适合进行适度扩张投资。",
    "key_findings": [
      "Q3 收入下降 18.5%，需关注市场趋势",
      "现金流下滑明显，但储备充足",
      "利润下降 54.8%，成本控制需要加强"
    ]
  },
  "risk_assessment": {
    "overall_score": 7,
    "risk_factors": [
      {
        "name": "现金流风险",
        "level": "high",
        "reason": "Q3 现金流大幅下滑（从 180万降至 40万）"
      },
      {
        "name": "市场风险",
        "level": "medium",
        "reason": "行业整体增速放缓 5%"
      }
    ]
  },
  "recommendations": [
    {
      "title": "方案A：保守型投资",
      "investment_amount": "500万",
      "expected_return": "15-20%",
      "risk_level": "low",
      "pros": ["风险可控", "现金流压力小"],
      "cons": ["增长较慢"]
    }
  ]
}
```

---

## 8. 用例追踪与迭代

### 8.1 用例状态

- **待开始（To Do）**：用例已定义，未开始开发
- **进行中（In Progress）**：正在开发或测试
- **待验收（Pending Review）**：开发完成，等待验收
- **已通过（Passed）**：验收通过，用例可用
- **需修复（Need Fix）**：验收未通过，需要修复
- **已废弃（Deprecated）**：用例不再需要

### 8.2 用例迭代记录

**版本历史：**
```
UC-001 v1.0 (2025-01-XX)
  - 初始版本
  - 支持基础决策分析流程
  
UC-001 v1.1 (2025-02-XX)
  - 增加批量分析支持
  - 优化移动端体验
  
UC-001 v1.2 (2025-03-XX)
  - 增加实时协作功能
  - 优化分析速度（减少 30% 响应时间）
```

---

## 9. 用例与需求映射

### 9.1 需求覆盖矩阵

| 需求ID | 需求描述 | 覆盖用例 | 状态 |
|--------|---------|---------|------|
| REQ-001 | 决策建议生成 | UC-001, UC-005 | ✅ |
| REQ-002 | 数据分析能力 | UC-002 | ✅ |
| REQ-003 | 风险评估 | UC-004 | ✅ |
| REQ-004 | 自然语言交互 | UC-005, UC-006 | ✅ |
| REQ-005 | 知识检索 | UC-008 | ✅ |
| REQ-006 | 历史决策记录 | UC-009 | ⏳ |

---

## 10. 下一步行动

1. **用例评审**
   - [ ] 内部评审所有用例定义
   - [ ] 收集用户反馈（焦点小组）
   - [ ] 调整用例优先级

2. **测试准备**
   - [ ] 准备测试数据
   - [ ] 搭建测试环境
   - [ ] 编写自动化测试用例

3. **开发跟踪**
   - [ ] 在项目管理工具中创建用例任务
   - [ ] 设置验收标准
   - [ ] 定期跟踪进度

---

## 参考资源

- [用户故事模板](https://www.atlassian.com/agile/project-management/user-stories)
- [验收标准指南](https://www.agilealliance.org/glossary/acceptance-criteria/)
- [BDD 测试框架](https://cucumber.io/docs/bdd/)

---

## 更新日志

- 2025-01-XX: 创建用例定义文档初版
- 待更新...