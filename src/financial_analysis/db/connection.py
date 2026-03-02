"""Database connection pool management using asyncpg."""

import asyncio
import logging
from pathlib import Path
from typing import Optional

import asyncpg

from ..config import get_settings

logger = logging.getLogger(__name__)

_pool: Optional[asyncpg.Pool] = None

_INIT_SQL_PATH = Path(__file__).resolve().parent.parent.parent.parent / "docker" / "init.sql"


async def _ensure_tables(pool: asyncpg.Pool) -> None:
    """Run init.sql to create tables if they don't exist."""
    if not _INIT_SQL_PATH.exists():
        logger.warning(f"init.sql not found at {_INIT_SQL_PATH}, skipping table creation.")
        return
    sql = _INIT_SQL_PATH.read_text(encoding="utf-8")
    async with pool.acquire() as conn:
        await conn.execute(sql)
    logger.info("Database tables ensured (CREATE IF NOT EXISTS).")


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
        _pool = await asyncio.wait_for(
            asyncpg.create_pool(
                dsn=settings.database_url,
                min_size=settings.db_pool_min_size,
                max_size=settings.db_pool_max_size,
                command_timeout=30,
            ),
            timeout=15,
        )
        logger.info("Database connection pool initialized.")
        await _ensure_tables(_pool)
    except asyncio.TimeoutError:
        logger.error(
            f"Database connection timed out (15s): {settings.database_url}"
        )
        _pool = None
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
