# US-002: 风险评估

> **文档编号**: US-002
> **版本**: 1.0
> **创建日期**: 2026-01-12
> **关联 PRD**: PRD_decision_analysis.md

---

## 用户故事

**作为** 一位中小企业 CEO，
**我希望** 能够获得企业当前面临的风险综合评估报告，
**以便** 识别潜在风险并提前制定应对策略。

---

## 场景描述

### 场景背景

李总是一家 SaaS 企业的 CEO，公司处于快速成长期。最近公司现金流连续 3 个月为负，负债率偏高，同时外部竞争加剧。李总需要全面了解企业当前面临的风险，以便在董事会会议上汇报并制定应对措施。

### 使用流程

```
1. 李总准备风险评估所需的信息
   - 公司基本信息（行业、规模、阶段）
   - 财务健康指标
   - 外部环境因素
         │
         ▼
2. 提交风险评估请求
         │
         ▼
3. 系统返回结构化风险评估报告
   - 总体风险评分
   - 各领域风险分析
   - 风险矩阵
   - 缓解策略
   - 监控计划
         │
         ▼
4. 李总基于报告制定风险应对计划
```

### 示例输入

```json
{
  "query": "请评估我们公司当前面临的主要风险",
  "context": {
    "company_profile": {
      "industry": "科技/SaaS",
      "size": "中型企业",
      "headcount": 200,
      "stage": "成长期"
    },
    "financial_health": {
      "monthly_cash_flow": -50,
      "cash_flow_trend": "连续3个月为负",
      "debt_ratio": 65,
      "industry_avg_debt_ratio": 45,
      "gross_margin": 68,
      "industry_avg_gross_margin": 72,
      "ar_turnover_days": 75,
      "industry_avg_ar_turnover_days": 45
    },
    "risk_areas": ["财务风险", "市场风险", "运营风险", "人才风险"],
    "external_factors": {
      "competition": "头部企业开始价格战",
      "economy": "不确定性增加",
      "supply_chain": "关键供应商价格上涨15%"
    }
  }
}
```

### 示例输出

```json
{
  "success": true,
  "data": {
    "analysis_id": "ana_20260112_002",
    "query": "请评估我们公司当前面临的主要风险",
    "result": {
      "situation_analysis": {
        "summary": "公司财务状况堪忧，现金流连续为负，负债率远超行业平均。在竞争加剧和经济不确定的环境下，需要立即采取风险缓解措施。",
        "key_findings": [
          "现金流连续 3 个月为负，月均亏损 50 万",
          "负债率 65% 远超行业平均 45%",
          "应收账款周转天数 75 天，资金占用严重"
        ]
      },
      "risk_assessment": {
        "overall_score": 8,
        "risk_level": "high",
        "risk_breakdown": [
          {
            "category": "财务风险",
            "score": 9,
            "key_factors": ["现金流持续为负", "负债率过高", "应收账款周转慢"],
            "probability": "high",
            "impact": "severe",
            "trend": "worsening"
          },
          {
            "category": "市场风险",
            "score": 7,
            "key_factors": ["竞争加剧", "价格战压力", "客户预算收紧"],
            "probability": "high",
            "impact": "moderate",
            "trend": "stable"
          },
          {
            "category": "运营风险",
            "score": 6,
            "key_factors": ["供应商成本上涨", "运营效率待提升"],
            "probability": "medium",
            "impact": "moderate",
            "trend": "stable"
          },
          {
            "category": "人才风险",
            "score": 5,
            "key_factors": ["核心人才流失风险", "招聘难度增加"],
            "probability": "medium",
            "impact": "moderate",
            "trend": "stable"
          }
        ],
        "risk_matrix": {
          "high_probability_high_impact": [
            "现金流枯竭导致运营中断",
            "无法偿还到期债务"
          ],
          "high_probability_low_impact": [
            "部分客户流失给竞争对手",
            "供应商价格继续上涨"
          ],
          "low_probability_high_impact": [
            "核心技术人员集体离职",
            "重大客户合同终止"
          ],
          "low_probability_low_impact": [
            "办公场地租金上涨",
            "非核心供应商更换"
          ]
        }
      },
      "recommendations": [
        {
          "title": "紧急措施：改善现金流",
          "risk_addressed": "财务风险 - 现金流",
          "priority": "urgent",
          "timeline": "30天内",
          "action_steps": [
            "立即启动应收账款催收专项",
            "与银行协商短期信贷额度",
            "暂停所有非必要资本支出",
            "评估是否需要裁员或降薪"
          ],
          "resources_needed": "财务团队 + 销售团队",
          "expected_outcome": "30 天内回收 200 万应收账款"
        },
        {
          "title": "短期措施：优化成本结构",
          "risk_addressed": "财务风险 - 负债率",
          "priority": "high",
          "timeline": "60天内",
          "action_steps": [
            "进行全面成本审计",
            "识别并削减低 ROI 支出",
            "重新谈判供应商合同",
            "优化人员配置"
          ],
          "resources_needed": "财务团队 + 各部门负责人",
          "expected_outcome": "月度支出降低 15-20%"
        },
        {
          "title": "中期措施：提升竞争力",
          "risk_addressed": "市场风险",
          "priority": "medium",
          "timeline": "90天内",
          "action_steps": [
            "分析竞品价格策略，制定差异化定位",
            "强化产品核心优势，避免价格战",
            "提升客户成功团队能力，提高留存率"
          ],
          "resources_needed": "产品团队 + 销售团队",
          "expected_outcome": "客户留存率提升至 90%"
        }
      ],
      "final_recommendation": {
        "choice": "分阶段实施风险缓解计划",
        "reasoning": "财务风险已达到危险水平，必须立即行动。建议按优先级分三阶段实施：第一阶段（30天）聚焦现金流改善；第二阶段（60天）优化成本结构；第三阶段（90天）提升市场竞争力。同时建议每周召开风险监控会议。"
      },
      "monitoring_plan": {
        "key_indicators": [
          { "name": "月度现金流", "current": -50, "target": ">0", "frequency": "weekly" },
          { "name": "应收账款周转天数", "current": 75, "target": "<50", "frequency": "monthly" },
          { "name": "负债率", "current": 65, "target": "<55", "frequency": "monthly" },
          { "name": "客户流失率", "current": "unknown", "target": "<10%", "frequency": "monthly" }
        ],
        "review_frequency": "weekly",
        "escalation_triggers": [
          "现金储备低于 2 个月运营成本",
          "单月客户流失率超过 5%",
          "负债率超过 70%"
        ]
      }
    }
  },
  "metadata": {
    "model": "claude-3-5-sonnet-20241022",
    "tokens_used": 2890,
    "execution_time_ms": 9200
  }
}
```

---

## 验收标准 (Acceptance Criteria)

### 风险评估输出

- [ ] **AC-1**: 当用户请求风险评估时，系统应返回总体风险评分（1-10 分）和风险等级（low/medium/medium-high/high/critical）
- [ ] **AC-2**: 当返回风险分析时，必须覆盖用户指定的所有风险领域，每个领域包含：评分、关键因素、发生概率、影响程度、趋势
- [ ] **AC-3**: 当返回风险矩阵时，必须按照概率-影响四象限分类风险事件
- [ ] **AC-4**: 当返回缓解策略时，高优先级风险必须有对应的缓解措施，每个措施包含：优先级、时间线、具体行动步骤、所需资源
- [ ] **AC-5**: 当返回监控计划时，必须包含关键监控指标、监控频率和升级触发条件

### 风险评分逻辑

- [ ] **AC-6**: 当财务指标严重偏离行业平均时（如负债率超出行业平均 50%），对应风险评分应 >= 8
- [ ] **AC-7**: 当多个风险因素同时恶化时，总体风险评分应反映叠加效应
- [ ] **AC-8**: 当风险趋势为 "worsening" 时，缓解策略的优先级应标记为 "urgent" 或 "high"

### 输入处理

- [ ] **AC-9**: 当用户未指定风险领域时，系统应默认评估：财务风险、市场风险、运营风险
- [ ] **AC-10**: 当财务数据不完整时，系统应在响应中说明数据缺失可能影响评估准确性

---

## 优先级

| 维度 | 评估 | 说明 |
|------|------|------|
| **业务价值** | 高 | 风险评估是 CEO 核心需求之一 |
| **紧急程度** | 高 | MVP 核心功能 |
| **综合优先级** | **P0** | 必须在 MVP 中实现 |

---

## 依赖

### 技术依赖

| 依赖项 | 类型 | 说明 |
|--------|------|------|
| US-001 基础分析能力 | 内部依赖 | 共享分析框架 |
| Claude API | 外部服务 | 核心 LLM 能力 |

### 任务依赖

| 依赖任务 | 说明 |
|---------|------|
| Phase 0 风险评估场景验证 | Prompt 模板需要验证通过 |
| US-001 基础架构 | API 路由和响应解析器 |

---

## 备注

### 风险评分标准参考

| 评分范围 | 风险等级 | 说明 |
|---------|---------|------|
| 1-2 | Low | 风险可控，无需特别关注 |
| 3-4 | Medium | 需要监控，制定预案 |
| 5-6 | Medium-High | 需要主动管理，执行缓解措施 |
| 7-8 | High | 需要立即行动，高优先级处理 |
| 9-10 | Critical | 危机状态，需要紧急响应 |

### 后续迭代

- Phase 2: 支持历史风险数据对比
- Phase 2: 风险预警自动推送
- Phase 3: 接入实时财务数据

---

## 变更记录

| 版本 | 日期 | 修改内容 | 修改人 |
|------|------|---------|--------|
| 1.0 | 2026-01-12 | 初始版本 | PM |
