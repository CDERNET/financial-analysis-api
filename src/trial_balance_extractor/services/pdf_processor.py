"""PDF processing service with OCR capabilities."""

import logging
import fitz  # PyMuPDF
import pandas as pd
from fastapi import HTTPException
from typing import List, Optional
from ..models.schemas import TrialBalanceItem, ProcessingResult
from ..utils.text_processing import compute_balances, find_parent_code, parse_numeric_value
from .tree_builder import TreeBuilder
from .database_service import DatabaseService


logger = logging.getLogger(__name__)

class PDFProcessor:
    """Service for processing PDF files with OCR."""
    
    def __init__(self):
        """Initialize PDF processor with dependencies."""
        self.tree_builder = TreeBuilder()
        self.db_service = DatabaseService()
    
   
    def process_pdf_file(
        self,
        file_content: bytes,
        headers: List[str],
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process PDF file and extract trial balance data.
        
        Args:
            file_content: PDF file content as bytes
            headers: List of column headers to extract
            separator: Account hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result with success status and details
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            
            # Extract table data from PDF
            df = self.extract_pdf_data(file_content, headers)
            
            if df.empty:
                raise HTTPException(status_code=400, detail="No table data found in PDF")
            
            # Process the extracted data
            return self._process_pdf_dataframe(df,headers, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF processing failed: {e}")

    def _process_pdf_dataframe(
        self,
        df: pd.DataFrame,
        headers: List[str],
        separator: str,
        account_number: int,
        period_id: int
    ) -> ProcessingResult:
        """
        Process extracted PDF DataFrame.
        
        Args:
            df: Extracted DataFrame
            separator: Account hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result
        """
        try:
           
            # Build parent relationships
            account_code_col = headers[0]
            df[account_code_col] = df[account_code_col].astype(str).str.strip()
            
            all_codes = set(df[account_code_col].dropna().unique())
            df['parent_code'] = df[account_code_col].apply(
                lambda x: find_parent_code(x, all_codes, separator)
            )
            
            # Convert to trial balance items
            items = self._dataframe_to_items(df, headers, account_number, period_id)
            
            # Insert into database
            inserted_count = self.db_service.insert_trial_balance_items(items)
            
            return ProcessingResult(
                success=True,
                message=f"Successfully processed PDF with {len(items)} records",
                inserted_count=inserted_count,
                account_number=account_number,
                period_id=period_id
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF DataFrame processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF data processing failed: {e}")
    
    def extract_pdf_data(self,pdf_bytes: bytes, headers: List[str]) -> pd.DataFrame:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        all_data_rows = []

        for page in doc:
            blocks = page.get_text("dict")['blocks']
            spans = []
            header_y = None
            for block in blocks:
                if block.get("type") != 0:
                    continue
                for line in block.get("lines", []):
                    for span in line.get("spans", []):
                        text = span.get("text", "").strip()
                        y = span.get("bbox", [0])[1]
                        if text in [h for h in headers]:
                            header_y = y
                            break
                    if header_y:
                        break
                if header_y:
                    break
            if header_y is None:
                header_y = 40

            header_y = header_y - 0.00000000000625
            logging.debug(f"Header Y: {header_y}")
            for block in blocks:
                if block.get("type") != 0:
                    continue
                for line in block.get("lines", []):
                    for span in line.get("spans", []):
                        x = span.get("bbox", [0])[0]
                        y = span.get("bbox", [0])[1]
                        text = span.get("text", "").strip()
                        if text and header_y < y < 780:
                            spans.append({"x": x, "y": y, "text": text})

            header_x_positions = {}
            for header in headers:
                for span in spans:
                    if span["text"].strip().lower() == header.strip().lower():
                        header_x_positions[header] = span["x"]
                        break

            if len(header_x_positions) < len(headers):
                continue

            spans.sort(key=lambda s: s["y"])
            grouped_lines = []
            current_group = []
            current_y = None
            tolerance = 5

            for span in spans:
                if current_y is None:
                    current_y = span["y"]
                if abs(span["y"] - current_y) <= tolerance:
                    current_group.append(span)
                else:
                    grouped_lines.append(current_group)
                    current_group = [span]
                    current_y = span["y"]
            if current_group:
                grouped_lines.append(current_group)

            for i, group in enumerate(grouped_lines):
                if any(span['text'].lower() in [h.lower() for h in headers] for span in group):
                    continue

                group.sort(key=lambda s: s["x"])
                span_info = [(s["text"], s["x"], s["y"]) for s in group]
                sorted_headers = sorted(header_x_positions.items(), key=lambda kv: kv[1])
                col_buckets = {h: [] for h in headers}

                for text, x, y in span_info:
                    header, header_x = min(sorted_headers, key=lambda h: abs(h[1] - x))
                    y_conflict_entries = [s for s in col_buckets[header] if abs(s[2] - y) < 1 and abs(s[1] - x) < 100]

                    if y_conflict_entries:
                        conflict_text, conflict_x, conflict_y = y_conflict_entries[0]

                        other_headers = [(h, abs(hx - x)) for h, hx in sorted_headers if h != header]
                        if not other_headers:
                            col_buckets[header].append((text, x, y))
                            continue

                        alt_header, _ = min(other_headers, key=lambda item: item[1])

                        dist_text_to_header = abs(header_x_positions[header] - x)
                        dist_text_to_alt = abs(header_x_positions[alt_header] - x)
                        dist_conflict_to_header = abs(header_x_positions[header] - conflict_x)
                        dist_conflict_to_alt = abs(header_x_positions[alt_header] - conflict_x)

                        if dist_text_to_header <= dist_text_to_alt:
                            col_buckets[header].append((text, x, y))
                            col_buckets[alt_header].append((conflict_text, conflict_x, conflict_y))
                        else:
                            col_buckets[alt_header].append((text, x, y))
                            col_buckets[header].append((conflict_text, conflict_x, conflict_y))

                        col_buckets[header] = [s for s in col_buckets[header] if s != (conflict_text, conflict_x, conflict_y)]
                    else:
                        col_buckets[header].append((text, x, y))

                row_dict = {h: None for h in headers}
                for h in headers:
                    if col_buckets[h]:
                        spans = col_buckets[h]
                        if len(spans) == 1:
                            row_dict[h] = spans[0][0]
                        else:
                            sorted_spans = sorted(spans, key=lambda s: s[2])
                            min_y_text = sorted_spans[0][0]
                            max_y_text = sorted_spans[-1][0]
                            if min_y_text == max_y_text:
                                row_dict[h] = min_y_text
                            else:
                                row_dict[h] = f"{min_y_text} {max_y_text}"

                if len(headers) >= 2:
                    kod_header = headers[0]
                    aciklama_header = headers[1]
                    if not row_dict[kod_header] and row_dict[aciklama_header] and all_data_rows:
                        prev_row = all_data_rows[-1]
                        aciklama_index = headers.index(aciklama_header)
                        prev_row[aciklama_index] = (prev_row[aciklama_index] or "") + " " + row_dict[aciklama_header]
                        continue

                    if row_dict[aciklama_header] is None and row_dict[kod_header] and " " in row_dict[kod_header]:
                        parts = row_dict[kod_header].split(" ", 1)
                        row_dict[kod_header] = parts[0]
                        row_dict[aciklama_header] = parts[1]

                all_data_rows.append([row_dict[h] for h in headers])

        df = pd.DataFrame(all_data_rows, columns=headers)
        return df

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
        account_number: Optional[int] = None,
        period_id: Optional[int] = None
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
            logger.info(f"Processing row: {row.to_dict()}")
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
                    account_number=account_number if account_number is not None else 0,
                    period_id=period_id if period_id is not None else 0
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

    def process_pdf_file_no_save(
        self,
        file_content: bytes,
        headers: List[str],
        separator: str,
        account_number: Optional[int] = None,
        period_id: Optional[int] = None
    ) -> ProcessingResult:
        """
        Process PDF file and extract trial balance data without saving to database.
        
        Args:
            file_content: PDF file content as bytes
            headers: List of column headers to extract
            separator: Account hierarchy separator
            account_number: Account number (optional for preview)
            period_id: Period ID (optional for preview)
            
        Returns:
            Processing result with extracted data (without database insertion)
            
        Raises:
            HTTPException: If processing fails
        """
        try:
            
            # Extract table data from PDF
            df = self.extract_pdf_data(file_content, headers)
            
            if df.empty:
                raise HTTPException(status_code=400, detail="No table data found in PDF")
            
            # Process the extracted data
            return self._process_pdf_dataframe_no_save(df, headers, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF processing failed: {e}")

    def _process_pdf_dataframe_no_save(
        self,
        df: pd.DataFrame,
        headers: List[str],
        separator: str,
        account_number: Optional[int] = None,
        period_id: Optional[int] = None
    ) -> ProcessingResult:
        """
        Process extracted PDF DataFrame without saving to database.
        
        Args:
            df: Extracted DataFrame
            headers: List of column headers
            separator: Account hierarchy separator
            account_number: Account number
            period_id: Period ID
            
        Returns:
            Processing result with extracted data (without database insertion)
        """
        try:
           
            # Build parent relationships
            account_code_col = headers[0]
            df[account_code_col] = df[account_code_col].astype(str).str.strip()
            
            all_codes = set(df[account_code_col].dropna().unique())
            df['parent_code'] = df[account_code_col].apply(
                lambda x: find_parent_code(x, all_codes, separator)
            )
            
            # Convert to trial balance items
            items = self._dataframe_to_items(df, headers, account_number, period_id)
            
            # Return result without database insertion
            return ProcessingResult(
                success=True,
                message=f"Successfully processed PDF with {len(items)} records (no database save)",
                inserted_count=0,  # No database insertion
                account_number=account_number if account_number is not None else 0,
                period_id=period_id if period_id is not None else 0,
                data=[item.model_dump() for item in items]  # Include the processed data in response
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF DataFrame processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF data processing failed: {e}")
   