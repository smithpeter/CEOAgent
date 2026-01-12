# Tests

This directory contains tests for the CEOAgent project.

## Running Tests

### Run all tests
```bash
pytest tests/ -v
```

### Run with coverage
```bash
pytest tests/ -v --cov=. --cov-report=html
```

### Run specific test file
```bash
pytest tests/test_basic.py -v
```

## Test Structure

- `test_basic.py` - Basic tests for project structure and imports
- `conftest.py` - Pytest configuration and fixtures

## Adding New Tests

1. Create new test files with `test_` prefix (e.g., `test_api.py`)
2. Follow pytest conventions
3. Use fixtures from `conftest.py` when needed
4. Mark async tests with `@pytest.mark.asyncio`
