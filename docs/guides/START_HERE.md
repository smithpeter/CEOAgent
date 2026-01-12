# CEOAgent 快速开始

> **预计时间**：10 分钟（首次设置）/ 1 分钟（后续启动）

---

## 前置要求

- [x] Python 3.11+ 已安装
- [x] Anthropic API Key（[获取地址](https://console.anthropic.com/)）

**验证 Python 版本**：
```bash
python3 --version  # 需要 3.11 或更高
```

---

## 第一步：设置环境（5 分钟）

```bash
# 1. 进入项目目录
cd /Users/zouyongming/dev/ceoagent

# 2. 创建虚拟环境
python3 -m venv venv

# 3. 激活虚拟环境
source venv/bin/activate  # macOS/Linux
# 或 venv\Scripts\activate  # Windows

# 4. 安装依赖
pip install -r requirements.txt

# 5. 复制环境配置
cp .env.example .env

# 6. 编辑 .env，填入你的 API Key
# 打开 .env 文件，设置 ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
```

---

## 第二步：验证 API（2 分钟）

创建测试脚本 `test_api.py`：

```python
import os
from anthropic import Anthropic

# 加载环境变量
from dotenv import load_dotenv
load_dotenv()

# 创建客户端
client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# 测试调用
response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=100,
    messages=[{"role": "user", "content": "Hello, Claude!"}]
)

print("API 连接成功!")
print(f"响应: {response.content[0].text}")
```

运行测试：
```bash
python test_api.py
```

如果看到 "API 连接成功!"，说明配置正确。

---

## 第三步：开始开发

### 选项 A：场景验证（推荐先做）

直接在 Claude 对话界面测试 Prompt：

1. 打开 [Claude](https://claude.ai)
2. 复制 `scenarios/01_investment_decision.md` 中的测试 Prompt
3. 发送并评估输出质量
4. 记录结果，迭代优化

### 选项 B：开始写代码

参考 `MASTER_PLAN.md` 的 Phase 1 任务列表，从创建项目结构开始。

---

## 项目结构（Phase 1）

```
src/ceo_agent/
├── __init__.py
├── main.py              # FastAPI 入口
├── config.py            # 配置管理
├── core/
│   ├── agent.py         # AgentCore
│   ├── claude_client.py # Claude API
│   └── prompt_manager.py
└── api/
    ├── routes.py        # API 路由
    └── schemas.py       # 数据模型
```

---

## 常见问题

### Q: API Key 无效

确保 `.env` 文件中的 `ANTHROPIC_API_KEY` 格式正确（以 `sk-ant-` 开头）。

### Q: 模块找不到

确保虚拟环境已激活：
```bash
source venv/bin/activate
```

### Q: 网络超时

如果在国内，可能需要配置代理：
```bash
export HTTPS_PROXY=http://127.0.0.1:7890  # 根据你的代理端口调整
```

---

## 下一步

1. 阅读 `MASTER_PLAN.md` 了解完整开发计划
2. 完成 Phase 0 场景验证
3. 开始 Phase 1 MVP 开发

---

## 相关文档

| 文档 | 说明 |
|------|------|
| `MASTER_PLAN.md` | 唯一权威的开发计划 |
| `CLAUDE.md` | Claude Code 使用指南 |
| `scenarios/` | 场景验证文档 |
