# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CEOAgent is an AI-powered CEO decision support system that helps CEOs with investment decisions, risk assessment, and strategic planning.

**Current Status:** Phase 0 - Scenario Validation (no source code yet)

## Development Commands

```bash
# Environment setup
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
pip install -e ".[dev]"
cp .env.example .env  # Add ANTHROPIC_API_KEY

# Run server (Phase 1+)
uvicorn src.ceo_agent.main:app --reload

# Testing
pytest                              # All tests
pytest tests/test_agent.py -v       # Single file
pytest tests/test_agent.py::test_name -v  # Single test
pytest --cov=src/ceo_agent          # With coverage

# Code quality
ruff check .                        # Lint
ruff check --fix .                  # Auto-fix
ruff format .                       # Format
mypy src/ceo_agent                  # Type check (strict mode)
```

## Key Documents

**MASTER_PLAN.md is the authoritative development plan.** It supersedes DEVELOPMENT_PLAN.md, EXECUTION_PLAN.md, and TECHNICAL_BLUEPRINT.md.

Read order: START_HERE.md → MASTER_PLAN.md → scenarios/*.md

## Architecture

```
Phase 1 MVP:

FastAPI → AgentCore
           ├── PromptManager    # Prompt templates (prompts/v1/)
           ├── ClaudeClient     # Anthropic SDK wrapper
           ├── ResponseParser   # Structured output parsing
           └── MemoryStore      # In-memory conversation

Phase 2+: Skill system, Tool Calling, PostgreSQL, Redis
Phase 3+: Weaviate (vector DB), RAG, ReAct
Phase 4+: Multi-Agent, Neo4j (knowledge graph)
```

## Code Patterns

- Python 3.11+, strict type hints (mypy strict mode)
- Pydantic v2 for all data validation
- async/await for all I/O operations
- Google-style docstrings

### Skill Pattern (Phase 2+)

```python
class MySkill(BaseSkill):
    name: str = "my_skill"
    description: str = "..."
    parameters: Type[BaseModel]

    async def execute(self, params: MyParams) -> SkillResult:
        ...
```

## API Endpoints

```
POST /api/v1/analyze   # Decision analysis (main endpoint)
POST /api/v1/chat      # Conversation (Phase 2)
GET  /api/v1/health    # Health check
```

## Scenarios (Phase 0)

Validate prompts in claude.ai before building MVP:
- `scenarios/01_investment_decision.md` - Investment decisions
- `scenarios/02_risk_assessment.md` - Risk evaluation
- `scenarios/03_strategy_planning.md` - Strategic planning
