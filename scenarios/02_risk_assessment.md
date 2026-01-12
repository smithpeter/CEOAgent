# 场景验证：风险评估

## 场景名称：企业风险综合评估

### 1. 场景描述

**一句话描述：**
> 帮助 CEO 评估当前企业面临的主要风险，量化风险等级，并提供风险缓解建议

**触发条件：**
- 季度/年度风险评估会议
- 重大决策前的风险审查
- 外部环境发生重大变化时

**使用频率：** 每月 1-2 次

---

### 2. 输入定义

**必需输入：**

| 字段 | 类型 | 示例 | 说明 |
|------|------|------|------|
| company_profile | object | {industry, size, stage} | 公司基本信息 |
| financial_health | object | {cash_flow, debt_ratio, profit_margin} | 财务健康指标 |
| risk_areas | list | ["market", "operational", "financial"] | 需评估的风险领域 |

**可选输入：**

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| external_factors | object | null | 外部环境因素 |
| historical_incidents | list | [] | 历史风险事件 |
| risk_tolerance | string | "moderate" | 风险承受能力 |

---

### 3. 预期输出

```json
{
  "overall_risk_score": 7,
  "risk_level": "medium-high",
  "risk_breakdown": [
    {
      "category": "财务风险",
      "score": 8,
      "key_factors": ["现金流紧张", "负债率偏高"],
      "probability": "high",
      "impact": "severe",
      "trend": "worsening"
    },
    {
      "category": "市场风险",
      "score": 6,
      "key_factors": ["竞争加剧", "市场增速放缓"],
      "probability": "medium",
      "impact": "moderate",
      "trend": "stable"
    }
  ],
  "risk_matrix": {
    "high_probability_high_impact": [...],
    "high_probability_low_impact": [...],
    "low_probability_high_impact": [...],
    "low_probability_low_impact": [...]
  },
  "mitigation_strategies": [
    {
      "risk": "现金流紧张",
      "strategy": "加速应收账款回收",
      "priority": "urgent",
      "timeline": "30天内",
      "resources_needed": "财务团队"
    }
  ],
  "monitoring_plan": {
    "key_indicators": [...],
    "review_frequency": "monthly"
  }
}
```

---

### 4. 成功标准

**功能性标准：**
- [ ] 输出包含总体风险评分（1-10）
- [ ] 至少评估 3 个风险类别
- [ ] 每个风险有概率和影响评估
- [ ] 提供具体的缓解策略

**质量标准：**
- [ ] 风险识别全面（覆盖主要风险领域）
- [ ] 评分有数据支撑
- [ ] 缓解策略可执行

---

### 5. 手动验证

#### 测试 Prompt

```
你是一位专业的企业风险管理顾问。请基于以下信息，为 CEO 提供全面的风险评估报告。

## 公司信息
- 行业：科技/SaaS
- 规模：中型企业（200人）
- 发展阶段：成长期

## 财务状况
- 月现金流：-50万（持续3个月为负）
- 资产负债率：65%（行业平均 45%）
- 毛利率：68%（行业平均 72%）
- 应收账款周转天数：75天（行业平均 45天）

## 需评估的风险领域
- 财务风险
- 市场风险
- 运营风险
- 人才风险

## 外部环境
- 行业竞争加剧，头部企业开始价格战
- 经济环境不确定性增加
- 关键供应商价格上涨 15%

## 请提供

### 1. 总体风险评分（1-10）及风险等级

### 2. 各领域风险分析
每个领域包含：
- 风险评分
- 关键风险因素
- 发生概率（高/中/低）
- 影响程度（严重/中等/轻微）
- 趋势（恶化/稳定/改善）

### 3. 风险矩阵
按概率和影响分类

### 4. 风险缓解策略
每个高优先级风险的：
- 缓解措施
- 优先级
- 时间线
- 所需资源

### 5. 监控计划
- 关键监控指标
- 复查频率
```

**输出：**
```
[待填写 - 执行测试后粘贴 Claude 回复]
```

**评估：**
```
[待填写]
```

---

### 6. 验证状态

**当前状态：** ⏳ 待验证

**下一步：**
1. 在 Claude 对话界面执行上述 Prompt
2. 评估输出质量
3. 根据结果调整 Prompt
4. 记录最终版本
