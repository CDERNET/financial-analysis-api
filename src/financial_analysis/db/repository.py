"""Repository for database operations on FinancialStatement tables."""

import json
import logging
from pathlib import Path
from typing import List, Dict, Any
from decimal import Decimal

import asyncpg

logger = logging.getLogger(__name__)


class FinancialStatementRepository:
    """Handles INSERT operations for FinancialStatement and
    FinancialStatementDetail."""

    def __init__(self, pool: asyncpg.Pool):
        self._pool = pool

    async def insert_beyanname_items(
        self,
        identity_number: str,
        year: str,
        period: str,
        read_type: int,
        items: List[Dict[str, Any]],
    ) -> int:
        """Insert parsed beyanname items into FinancialStatement table.

        Period = YYYY + Q + ReadType (6 digits).
        Value -> both OriginalValue and CorrectedValue.
        Deletes existing records for same IdentityNumber+Period first.
        """
        if not items:
            return 0

        period_int = int(f"{year}{period}{read_type}")

        rows = []
        for item in items:
            code = item.get("Code")
            if code is None:
                continue
            value = Decimal(str(item.get("Value") or 0))
            rows.append((
                str(identity_number),
                period_int,
                str(code),
                value,
                value,
            ))

        if not rows:
            return 0

        async with self._pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    'DELETE FROM public."FinancialStatement" '
                    'WHERE "IdentityNumber" = $1 AND "Period" = $2',
                    str(identity_number),
                    period_int,
                )
                await conn.executemany(
                    'INSERT INTO public."FinancialStatement" '
                    '("IdentityNumber", "Period", "Code", '
                    '"OriginalValue", "CorrectedValue") '
                    "VALUES ($1, $2, $3, $4, $5)",
                    rows,
                )

        logger.info(
            f"Inserted {len(rows)} rows into FinancialStatement "
            f"(IdentityNumber={identity_number}, Period={period_int})"
        )
        return len(rows)

    async def get_definitions(self) -> List[Dict[str, Any]]:
        """Fetch all item definitions from FinancialStatementItemDefinition."""
        async with self._pool.acquire() as conn:
            rows = await conn.fetch(
                'SELECT "Code", "Name", "ParentCode", "SequenceNumber", '
                '"Sign", "IsLeaf", "BalanceSheet", "Description", '
                '"Description2", "Description3", "Status" '
                'FROM public."FinancialStatementItemDefinition" '
                'ORDER BY "Code"'
            )
        return [dict(r) for r in rows]

    async def get_definitions_tree(self) -> List[Dict[str, Any]]:
        """Fetch definitions and build hierarchical tree."""
        definitions = await self.get_definitions()

        by_code = {}
        for d in definitions:
            d["children"] = []
            by_code[d["Code"]] = d

        roots = []
        for d in definitions:
            parent = d.get("ParentCode")
            if parent and parent in by_code:
                by_code[parent]["children"].append(d)
            else:
                roots.append(d)

        return roots

    async def insert_mizan_items(
        self,
        items: List[Dict[str, Any]],
    ) -> int:
        """Insert parsed mizan items into FinancialStatementDetail table.

        Deletes existing records for same IdentityNumber+Period first.
        """
        if not items:
            return 0

        first = items[0]
        identity_number = str(first.get("account_number", ""))
        period_id = int(first.get("period_id", 0))

        rows = []
        for item in items:
            rows.append((
                str(item.get("account_number", "")),
                int(item.get("period_id", 0)),
                str(item.get("account_code", "")),
                item.get("account_name") or None,
                item.get("parent_account_code") or None,
                Decimal(str(item.get("debit", 0))),
                Decimal(str(item.get("credit", 0))),
                Decimal(str(item.get("debit_balance", 0)))
                if item.get("debit_balance") is not None
                else None,
                Decimal(str(item.get("credit_balance", 0)))
                if item.get("credit_balance") is not None
                else None,
            ))

        async with self._pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    'DELETE FROM public."FinancialStatementDetail" '
                    'WHERE "IdentityNumber" = $1 AND "Period" = $2',
                    identity_number,
                    period_id,
                )
                await conn.executemany(
                    'INSERT INTO public."FinancialStatementDetail" '
                    '("IdentityNumber", "Period", "Code", "Description", '
                    '"ParentCode", "Debit", "Credit", '
                    '"DebitBalance", "CreditBalance") '
                    "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
                    rows,
                )

        logger.info(
            f"Inserted {len(rows)} rows into FinancialStatementDetail "
            f"(IdentityNumber={identity_number}, Period={period_id})"
        )
        return len(rows)


async def seed_item_definitions(pool: asyncpg.Pool) -> None:
    """Seed FinancialStatementItemDefinition table from JSON if empty."""
    async with pool.acquire() as conn:
        count = await conn.fetchval(
            'SELECT COUNT(*) FROM public."FinancialStatementItemDefinition"'
        )
        if count > 0:
            logger.info(
                f"FinancialStatementItemDefinition already has {count} rows, "
                "skipping seed."
            )
            return

    json_path = (
        Path(__file__).resolve().parent.parent
        / "data"
        / "financial_item_definitions.json"
    )
    with open(json_path, "r", encoding="utf-8") as f:
        definitions = json.load(f)

    rows = []
    for item in definitions:
        rows.append((
            str(item["Code"]),
            str(item["Name"]),
            item.get("ParentCode"),
            int(item.get("SequenceNumber", 0)),
            int(item.get("Sign", 1)),
            int(item.get("IsLeaf", 0)),
            int(item.get("BalanceSheet", 0)),
            item.get("Description"),
            item.get("Description2"),
            item.get("Description3"),
            int(item.get("Status", 1)),
        ))

    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.executemany(
                'INSERT INTO public."FinancialStatementItemDefinition" '
                '("Code", "Name", "ParentCode", "SequenceNumber", '
                '"Sign", "IsLeaf", "BalanceSheet", "Description", '
                '"Description2", "Description3", "Status") '
                "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)",
                rows,
            )

    logger.info(
        f"Seeded {len(rows)} rows into FinancialStatementItemDefinition"
    )
