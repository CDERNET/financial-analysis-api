"""Excel file processing service."""

import logging
from io import BytesIO
from typing import Dict, List, Optional
import pandas as pd
from fastapi import HTTPException

from ..models.schemas import TrialBalanceItem, ProcessingResult
from ..utils import COLUMN_MAP, KEYWORDS, clean_text
from ..utils.text_processing import find_parent_code
from .tree_builder import TreeBuilder
from .database_service import DatabaseService


logger = logging.getLogger(__name__)


class ExcelProcessor:
    """Service for processing Excel and CSV files."""
    
    def __init__(self):
        """Initialize Excel processor with dependencies."""
        self.tree_builder = TreeBuilder()
        self.db_service = DatabaseService()
    
    def process_excel_file(
        self,
        file_content: bytes,
        filename: str,
        account_code_column: str,
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process Excel file and extract trial balance data.
        
        Args:
            file_content: File content as bytes
            filename: Name of the file
            account_code_column: Name of account code column
            separator: Hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result with success status and details
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            logger.info(f"Processing Excel file: {filename}")
            
            # Read Excel file based on extension
            if filename.lower().endswith('.xlsx'):
                excel_file = pd.ExcelFile(BytesIO(file_content), engine='openpyxl')
            elif filename.lower().endswith('.xls'):
                excel_file = pd.ExcelFile(BytesIO(file_content), engine='xlrd')
            elif filename.lower().endswith('.csv'):
                df = pd.read_csv(BytesIO(file_content)).fillna('').astype(str)
                return self._process_dataframe(df, account_code_column, separator, account_number, period_id)
            else:
                raise HTTPException(status_code=400, detail="Unsupported file format")
            
            # Process all sheets in Excel file
            for sheet_name in excel_file.sheet_names:
                logger.info(f"Processing sheet: {sheet_name}")
                df = excel_file.parse(sheet_name, header=None).fillna('').astype(str)
                return self._process_dataframe(df, account_code_column, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Excel processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"Excel processing failed: {e}")
    
    def _process_dataframe(
        self,
        df: pd.DataFrame,
        account_code_column: str,
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process DataFrame to extract and store trial balance data.
        
        Args:
            df: DataFrame to process
            account_code_column: Name of account code column
            separator: Hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            # Find header row by looking for keywords
            header_row = self._find_header_row(df)
            if header_row is None:
                raise HTTPException(status_code=400, detail="No valid header row found in file")
            
            # Set headers and extract data
            df.columns = df.iloc[header_row]
            df = df.iloc[header_row + 1:].reset_index(drop=True)
            
            # Map columns to standard names
            column_mapping = self._find_column_mapping(df)
            if 'AccountCode' not in column_mapping:
                raise HTTPException(status_code=400, detail="Account code column not found in file")
            
            # Clean and process data
            account_code_col = column_mapping['AccountCode']
            df[account_code_col] = df[account_code_col].astype(str).str.strip()
            
            # Build parent-child relationships
            all_codes = set(df[account_code_col].dropna().unique())
            df['parent_code'] = df[account_code_col].apply(
                lambda x: find_parent_code(x, all_codes, separator)
            )
            
            # Convert to trial balance items
            items = self._dataframe_to_items(df, column_mapping, account_number, period_id)
            
            # Insert into database
            inserted_count = self.db_service.insert_trial_balance_items(items)
            
            return ProcessingResult(
                success=True,
                message=f"Successfully processed {len(items)} records",
                inserted_count=inserted_count,
                account_number=account_number,
                period_id=period_id
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"DataFrame processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"Data processing failed: {e}")
    
    def _find_header_row(self, df: pd.DataFrame) -> Optional[int]:
        """
        Find the header row by looking for keyword matches.
        
        Args:
            df: DataFrame to search
            
        Returns:
            Row index of header, None if not found
        """
        for i, row in df.iterrows():
            normalized = [str(cell).strip().lower() for cell in row]
            match_count = sum(1 for cell in normalized if cell in [k.lower() for k in KEYWORDS])
            if match_count >= 3:  # Require at least 3 keyword matches
                logger.info(f"Found header row at index {i} with {match_count} matches")
                return i
        return None
    
    def _find_column_mapping(self, df: pd.DataFrame) -> Dict[str, str]:
        """
        Map DataFrame columns to standard column names.
        
        Args:
            df: DataFrame with columns to map
            
        Returns:
            Dictionary mapping standard names to actual column names
        """
        mapping = {}
        normalized_cols = {clean_text(str(col)): col for col in df.columns}
        
        for standard_name, synonyms in COLUMN_MAP.items():
            for synonym in synonyms:
                normalized_synonym = clean_text(synonym)
                if normalized_synonym in normalized_cols:
                    mapping[standard_name] = normalized_cols[normalized_synonym]
                    break
        
        logger.info(f"Column mapping found: {mapping}")
        return mapping
    
    def _dataframe_to_items(
        self,
        df: pd.DataFrame,
        column_mapping: Dict[str, str],
        account_number: int,
        period_id: int
    ) -> List[TrialBalanceItem]:
        """
        Convert DataFrame to TrialBalanceItem objects.
        
        Args:
            df: Source DataFrame
            column_mapping: Column name mapping
            account_number: Account number
            period_id: Period ID
            
        Returns:
            List of TrialBalanceItem objects
        """
        items = []
        
        for _, row in df.iterrows():
            try:
                item = TrialBalanceItem(
                    account_code=str(row.get(column_mapping.get('AccountCode', ''), '')).strip(),
                    account_name=str(row.get(column_mapping.get('AccountName', ''), '')).strip(),
                    debit=self._parse_numeric(row.get(column_mapping.get('Debit', ''), 0)),
                    credit=self._parse_numeric(row.get(column_mapping.get('Credit', ''), 0)),
                    debit_balance=self._parse_numeric(row.get(column_mapping.get('DebitBalance', ''), 0)),
                    credit_balance=self._parse_numeric(row.get(column_mapping.get('CreditBalance', ''), 0)),
                    parent_account_code=row.get('parent_code'),
                    account_number=account_number,
                    period_id=period_id
                )
                
                if item.account_code:  # Only add items with valid account codes
                    items.append(item)
                    
            except Exception as e:
                logger.warning(f"Failed to process row: {e}")
                continue
        
        logger.info(f"Converted {len(items)} rows to TrialBalanceItem objects")
        return items
    
    def _parse_numeric(self, value) -> float:
        """
        Parse numeric value handling different formats.
        
        Args:
            value: Value to parse
            
        Returns:
            Parsed float value
        """
        
        try:
            if isinstance(value, str):
                val = value.strip()            
                if ',' in val and '.' in val:
                    if val.rfind(',') > val.rfind('.'):
                        val = val.replace('.', '').replace(',', '.')
                    else:
                        val = val.replace(',', '')
                elif ',' in val:
                    val = val.replace('.', '').replace(',', '.')
                else:
                    val = val.replace(',', '')
                
                parsed_value = float(val)
                return parsed_value
            else:
                parsed_value = float(value)
                return parsed_value
        except (ValueError, TypeError) as e:
            return 0.0
