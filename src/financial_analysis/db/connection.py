"""Database connection pool management using asyncpg."""

import logging
from typing import Optional

import asyncpg

from ..config import get_settings

logger = logging.getLogger(__name__)

_pool: Optional[asyncpg.Pool] = None


async def init_db_pool() -> Optional[asyncpg.Pool]:
    """Initialize the asyncpg connection pool. Called during app startup."""
    global _pool
    settings = get_settings()

    if not settings.database_url:
        logger.warning(
            "DATABASE_URL not configured; database features disabled."
        )
        return None

    try:
        _pool = await asyncpg.create_pool(
            dsn=settings.database_url,
            min_size=settings.db_pool_min_size,
            max_size=settings.db_pool_max_size,
            command_timeout=30,
        )
        logger.info("Database connection pool initialized.")
    except Exception as e:
        logger.error(f"Failed to initialize database pool: {e}")
        _pool = None

    return _pool


async def close_db_pool() -> None:
    """Close the asyncpg connection pool. Called during app shutdown."""
    global _pool
    if _pool:
        await _pool.close()
        _pool = None
        logger.info("Database connection pool closed.")


def get_db_pool() -> Optional[asyncpg.Pool]:
    """Return the current connection pool (None if DB is disabled)."""
    return _pool
