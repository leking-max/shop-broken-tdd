"""Shared fixtures.

Keep this file small: a fixture that hides data makes a test harder to read.
"""

import pytest


@pytest.fixture
def stock() -> dict[str, int]:
    """A tiny warehouse: two healthy SKUs and one that is about to run out."""
    return {"SKU-1": 12, "SKU-2": 3, "SKU-3": 40}


@pytest.fixture
def prices() -> dict[str, int]:
    """Unit prices in kopecks for the fixtures above."""
    return {"SKU-1": 1_990, "SKU-2": 49_900, "SKU-3": 250}
