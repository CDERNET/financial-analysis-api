"""FastAPI dependencies for database access."""

from typing import Optional

from .connection import get_db_pool
from .repository import FinancialStatementRepository


async def get_repository() -> Optional[FinancialStatementRepository]:
    """FastAPI dependency that returns a FinancialStatementRepository.
    Returns None if database is not configured."""
    pool = get_db_pool()
    if pool is None:
        return None
    return FinancialStatementRepository(pool)
