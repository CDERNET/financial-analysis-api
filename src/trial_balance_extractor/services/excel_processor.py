"""Excel file processing service."""

import logging
from io import BytesIO
from typing import List, Optional
import pandas as pd
import re
from fastapi import HTTPException

from ..models.schemas import TrialBalanceItem, ProcessingResult
from ..utils import clean_text
from ..utils.text_processing import compute_balances, find_parent_code, normalize_account_code, parse_numeric_value
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
        headers: List[str],
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process Excel file and extract trial balance data.
        
        Args:
            file_content: File content as bytes
            filename: Name of the file
            headers: Comma-separated column headers
            separator: Hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result with success status and details
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            
            # Read Excel file based on extension
            if filename.lower().endswith('.xlsx') or filename.lower().endswith('.xlsm'):
                excel_file = pd.ExcelFile(BytesIO(file_content), engine='openpyxl')
            elif filename.lower().endswith('.xls'):
                excel_file = pd.ExcelFile(BytesIO(file_content), engine='xlrd')
            elif filename.lower().endswith('.csv'):
                df = pd.read_csv(BytesIO(file_content)).fillna('').astype(str)
                return self._process_dataframe(df, headers, separator, account_number, period_id)
            else:
                raise HTTPException(status_code=400, detail="Unsupported file format")
            
            # Process all sheets in Excel file
            selected_sheet = None
            header_row = None
 
            for sheet_name in excel_file.sheet_names:
                df = excel_file.parse(sheet_name, header=None).fillna('').astype(str)
                row_index = self._find_header_row(df, headers)
                if row_index is not None:
                    selected_sheet = sheet_name
                    header_row = row_index
                    break

            if not selected_sheet:
                raise HTTPException(status_code=400, detail="No sheet with matching headers found")

            logger.info(f"Processing selected sheet: {selected_sheet}")
            df = excel_file.parse(selected_sheet, header=None).fillna('').astype(str)
            return self._process_dataframe(df, headers, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Excel processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"Excel processing failed: {e}")
    
    def _process_dataframe(
        self,
        df: pd.DataFrame,
        headers: List[str],
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process DataFrame to extract and store trial balance data.
        
        Args:
            df: DataFrame to process
            headers: Comma-separated column headers
            separator: Hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            
            header_row_index = self._find_header_row(df,headers)
            if header_row_index is None:
                raise HTTPException(status_code=400, detail="No valid header row found in file")
            
            # Set headers and extract data
            df.columns = df.iloc[header_row_index]
            df.columns = [re.sub(r"\s+", " ", c).strip() for c in df.columns]
            df = df.iloc[header_row_index + 1:].reset_index(drop=True)
            # Clean and process data
            account_code_col = headers[0]
            logger.info(f"Using account code column: {df.columns.tolist()}")
            df[account_code_col] = df[account_code_col].apply(lambda x: normalize_account_code(x, separator))
            # Build parent-child relationships
            all_codes = set(df[account_code_col].dropna().unique())
            logger.info(f"Total unique account codes found: {len(all_codes)}")
            df['parent_code'] = df[account_code_col].apply(
                lambda x: find_parent_code(x, all_codes, separator)
            )
            
            # Convert to trial balance items
            items = self._dataframe_to_items(df, headers, account_number, period_id)
            
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
    
    def _find_header_row(self, df: pd.DataFrame, headers: List[str]) -> Optional[int]:
        """
        Find the header row by looking for matches with provided headers.
        """
        normalized_headers = [clean_text(h).lower() for h in headers]

        for i, row in df.iterrows():
            normalized = [clean_text(str(cell)).lower() for cell in row]
            match_count = sum(1 for cell in normalized if cell in normalized_headers)

            if match_count >= 2:  # eşik: en az 2 header eşleşirse
                logger.info(f"Found header row at index {i} with {match_count} matches")
                return i
        return None
    def _is_number_like(self,value) -> bool:
        """Hücre değeri sayı mı? (int, float veya string-sayı)"""
        if pd.isna(value):
            return False
        if isinstance(value, (int, float)):
            return True
        text = str(value).strip()
        if text == "":
            return False
        try:
            float(text.replace(".", "").replace(",", "."))  # 1.234,56 veya 1234.56 formatlarını da yakalar
            return True
        except ValueError:
            return False


    def _is_data_row(self,row, headers):
        
        # Tüm hücreler boşsa atla
        if all((str(cell).strip() == "" or pd.isna(cell)) for cell in row.values): 
            return False
        # Satırda header anahtar kelimelerinden en az 2 tane varsa atla
        header_set = {str(h).strip().upper() for h in headers if pd.notna(h)}
        header_hits = sum(str(cell).strip().upper() in header_set for cell in row.values if str(cell).strip() != "")

        if header_hits >= 2: 
            return False
        # Satırda en az bir sayısal değer varsa veri olarak kabul et
        if any(self._is_number_like(cell) for cell in row.values):
            return True
        
        # Aksi halde veri değildir 
        return False

    def _dataframe_to_items(
        self,
        df: pd.DataFrame,
        headers:List[str],
        account_number: int,
        period_id: int
    ) -> List[TrialBalanceItem]:
        """
        Convert DataFrame to TrialBalanceItem objects.
        
        Args:
            df: Source DataFrame
            headers: list of headers
            account_number: Account number
            period_id: Period ID
            
        Returns:
            List of TrialBalanceItem objects
        """
        items = []
        is_data_row_count = 0
        total_df_rows = len(df)
        for _, row in df.iterrows():
            # Header satırıysa atla
            if not self._is_data_row(row, headers):
                is_data_row_count += 1
                logger.info(f"Skipping non-data row: {row.to_dict()}")
                continue
            try:
               
                account_code = str(row.get(headers[0], '')).strip()
                account_name = str(row.get(headers[1], '')).strip()
                debit  = parse_numeric_value(row.get(headers[2], 0))
                credit = parse_numeric_value(row.get(headers[3], 0))
                db_raw = row.get(headers[4], None) if len(headers)>4 else None
                cb_raw = row.get(headers[5], None) if len(headers)>5 else None 
                debit_balance, credit_balance = compute_balances(debit, credit, db_raw, cb_raw)
                item = TrialBalanceItem(
                    account_code=account_code,
                    account_name=account_name,
                    debit=debit,
                    credit=credit,
                    debit_balance=debit_balance,
                    credit_balance=credit_balance,
                    parent_account_code=row.get('parent_code'),
                    account_number=account_number,
                    period_id=period_id
                )              
                
                if item.account_code:  # Only add items with valid account codes
                    items.append(item)
                else:
                 is_data_row_count += 1
 
                    
            except Exception as e:
                logger.error(f"Failed to process row: {e} - Row data: {row.to_dict()}")
                continue
        
        
        calculated_total = is_data_row_count + len(items)  # data rows + skipped empty
        if calculated_total != total_df_rows:
                raise ValueError(
                    f"Row count mismatch! Total: {total_df_rows} rows, "
                    f"Skipped: {is_data_row_count} rows ,"
                    f"Converted: {len(items)} rows,"
                    f"(Skipped+Converted:{calculated_total})."
                )

        logger.info(
                f"Converted {len(items)} rows to TrialBalanceItem objects "
                f"(skipped {is_data_row_count} data rows."
            )
        return items
   

        