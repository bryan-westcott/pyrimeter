"""PyTest tests."""

import pytest
from loguru import logger


@pytest.mark.smoke
def smoke() -> None:
    """Run quick smoke test.

    Note: replace this code with actual test.
    """
    logger.warning("PLACEHOLDER SMOKE TEST, REPLACE WITH ACTUAL TEST!")
