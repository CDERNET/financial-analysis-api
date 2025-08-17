"""Database service for MSSQL operations."""

import logging
from typing import List, Dict, Any, Optional
from decimal import Decimal
import pyodbc

from ..config import get_settings
from ..models.schemas import TrialBalanceItem, TreeNode


logger = logging.getLogger(__name__)


class DatabaseService:
    """Service for database operations with MSSQL."""
    
    def __init__(self):
        """Initialize database service with settings."""
        self.settings = get_settings()
    
    def get_connection(self) -> pyodbc.Connection:
        """
        Get database connection.
        
        Returns:
            Database connection object
            
        Raises:
            Exception: If connection fails
        """
        try:
            connection_string = self.settings.get_database_url()
            return pyodbc.connect(connection_string)
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise Exception(f"Failed to connect to database: {e}")
    
    def insert_trial_balance_items(self, items: List[TrialBalanceItem]) -> int:
        """
        Insert trial balance items into database.
        
        Args:
            items: List of trial balance items to insert
            
        Returns:
            Number of items inserted
            
        Raises:
            Exception: If database operation fails
        """
        if not items:
            logger.warning("No items to insert")
            return 0
        
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                inserted_count = 0
                for item in items:
                    cursor.execute("""
                        INSERT INTO CustomerDetailedTrialBalance (
                            AccountCode, AccountName,
                            Debit, Credit, DebitBalance, CreditBalance,
                            ParentAccountCode, AccountNumber, PeriodId
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        item.account_code,
                        item.account_name,
                        item.debit,
                        item.credit, 
                        item.debit_balance,
                        item.credit_balance,
                        item.parent_account_code,
                        item.account_number,
                        item.period_id
                    ))
                    inserted_count += 1
                
                conn.commit()
                logger.info(f"Successfully inserted {inserted_count} trial balance items")
                return inserted_count
                
        except Exception as e:
            logger.error(f"Failed to insert trial balance items: {e}")
            raise Exception(f"Database insertion failed: {e}")
    
    def get_account_tree_data(
        self, 
        account_number: int, 
        period_id: int, 
        root_code: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get account tree data from database.
        
        Args:
            account_number: Account number to filter by
            period_id: Period ID to filter by
            root_code: Optional root account code for filtering
            
        Returns:
            List of account data dictionaries
            
        Raises:
            Exception: If database query fails
        """
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                
                if root_code:
                    # Get hierarchical data starting from root_code
                    query = """
                        WITH RecursiveTree AS (
                            SELECT * FROM CustomerDetailedTrialBalance
                            WHERE AccountNumber = ? AND PeriodId = ? AND AccountCode = ?
                            UNION ALL
                            SELECT child.* FROM CustomerDetailedTrialBalance child
                            INNER JOIN RecursiveTree parent ON child.ParentAccountCode = parent.AccountCode
                            WHERE child.AccountNumber = ? AND child.PeriodId = ?
                        )
                        SELECT * FROM RecursiveTree
                    """
                    cursor.execute(query, account_number, period_id, root_code, account_number, period_id)
                else:
                    # Get all data for the account and period
                    query = """
                        SELECT * FROM CustomerDetailedTrialBalance 
                        WHERE AccountNumber = ? AND PeriodId = ?
                    """
                    cursor.execute(query, account_number, period_id)
                
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                
                # Convert results to dictionaries and handle Decimal conversion
                data = []
                for row in rows:
                    row_dict = {}
                    for col, val in zip(columns, row):
                        if isinstance(val, Decimal):
                            row_dict[col] = float(val)
                        else:
                            row_dict[col] = val
                    data.append(row_dict)
                
                logger.info(f"Retrieved {len(data)} account records")
                return data
                
        except Exception as e:
            logger.error(f"Failed to get account tree data: {e}")
            raise Exception(f"Database query failed: {e}")
    
    def check_connection(self) -> bool:
        """
        Check if database connection is working.
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                logger.info("Database connection test successful")
                return True
        except Exception as e:
            logger.error(f"Database connection test failed: {e}")
            return False
