"""Database service for data operations."""

import logging
import json
import os
from typing import List, Dict, Any, Optional
from decimal import Decimal
from datetime import datetime

from ..config import get_settings
from ..models.schemas import TrialBalanceItem, TreeNode


logger = logging.getLogger(__name__)


class DatabaseService:
    """Service for data operations using file-based storage."""
    
    def __init__(self):
        """Initialize database service with settings."""
        self.settings = get_settings()
        self.data_dir = os.path.join(os.getcwd(), "data")
        os.makedirs(self.data_dir, exist_ok=True)
    
    def _get_data_file_path(self, account_number: int, period_id: int) -> str:
        """Get the file path for storing data."""
        return os.path.join(self.data_dir, f"trial_balance_{account_number}_{period_id}.json")
    
    def _load_data(self, account_number: int, period_id: int) -> List[Dict[str, Any]]:
        """Load data from file."""
        file_path = self._get_data_file_path(account_number, period_id)
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Failed to load data from {file_path}: {e}")
                return []
        return []
    
    def _save_data(self, account_number: int, period_id: int, data: List[Dict[str, Any]]) -> None:
        """Save data to file."""
        file_path = self._get_data_file_path(account_number, period_id)
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        except Exception as e:
            logger.error(f"Failed to save data to {file_path}: {e}")
            raise Exception(f"Failed to save data: {e}")
    
    def insert_trial_balance_items(self, items: List[TrialBalanceItem]) -> int:
        """
        Insert trial balance items into file storage.
        
        Args:
            items: List of trial balance items to insert
            
        Returns:
            Number of items inserted
            
        Raises:
            Exception: If file operation fails
        """
        if not items:
            logger.warning("No items to insert")
            return 0
        
        try:
            # Group items by account_number and period_id
            grouped_items = {}
            for item in items:
                key = (item.account_number, item.period_id)
                if key not in grouped_items:
                    grouped_items[key] = []
                grouped_items[key].append({
                    "AccountCode": item.account_code,
                    "AccountName": item.account_name,
                    "Debit": float(item.debit) if item.debit is not None else None,
                    "Credit": float(item.credit) if item.credit is not None else None,
                    "DebitBalance": float(item.debit_balance) if item.debit_balance is not None else None,
                    "CreditBalance": float(item.credit_balance) if item.credit_balance is not None else None,
                    "ParentAccountCode": item.parent_account_code,
                    "AccountNumber": item.account_number,
                    "PeriodId": item.period_id,
                    "CreatedAt": datetime.now().isoformat()
                })
            
            inserted_count = 0
            for (account_number, period_id), item_list in grouped_items.items():
                # Load existing data
                existing_data = self._load_data(account_number, period_id)
                
                # Add new items
                existing_data.extend(item_list)
                
                # Save updated data
                self._save_data(account_number, period_id, existing_data)
                inserted_count += len(item_list)
                
            logger.info(f"Successfully inserted {inserted_count} trial balance items")
            return inserted_count
                
        except Exception as e:
            logger.error(f"Failed to insert trial balance items: {e}")
            raise Exception(f"File insertion failed: {e}")
    
    def get_account_tree_data(
        self, 
        account_number: int, 
        period_id: int, 
        root_code: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get account tree data from file storage.
        
        Args:
            account_number: Account number to filter by
            period_id: Period ID to filter by
            root_code: Optional root account code for filtering
            
        Returns:
            List of account data dictionaries
            
        Raises:
            Exception: If file operation fails
        """
        try:
            # Load data from file
            data = self._load_data(account_number, period_id)
            
            if root_code:
                # Filter hierarchical data starting from root_code
                def get_children(parent_code: str, all_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
                    """Recursively get all children of a parent account."""
                    children = []
                    for item in all_data:
                        if item.get("ParentAccountCode") == parent_code:
                            children.append(item)
                            children.extend(get_children(item["AccountCode"], all_data))
                    return children
                
                # Find root item and its children
                filtered_data = []
                for item in data:
                    if item.get("AccountCode") == root_code:
                        filtered_data.append(item)
                        break
                
                if filtered_data:
                    filtered_data.extend(get_children(root_code, data))
                
                data = filtered_data
            
            logger.info(f"Retrieved {len(data)} account records")
            return data
                
        except Exception as e:
            logger.error(f"Failed to get account tree data: {e}")
            raise Exception(f"File query failed: {e}")
    
    def check_connection(self) -> bool:
        """
        Check if data directory is accessible.
        
        Returns:
            True if data directory is accessible, False otherwise
        """
        try:
            # Test if we can write to data directory
            test_file = os.path.join(self.data_dir, "test_connection.tmp")
            with open(test_file, 'w') as f:
                f.write("test")
            os.remove(test_file)
            logger.info("Data directory access test successful")
            return True
        except Exception as e:
            logger.error(f"Data directory access test failed: {e}")
            return False
