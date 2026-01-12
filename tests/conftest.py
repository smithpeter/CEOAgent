"""
Pytest configuration and fixtures
"""

import sys
from pathlib import Path

import pytest

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


@pytest.fixture
def project_root_path():
    """Return the project root path."""
    return Path(__file__).parent.parent
