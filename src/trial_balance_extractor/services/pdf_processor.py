"""PDF processing service with OCR capabilities."""

import logging
from typing import List, Dict, Tuple
import fitz  # PyMuPDF
import pandas as pd
from fastapi import HTTPException

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
            df = self._extract_pdf_table_data(file_content, headers)
            
            if df.empty:
                raise HTTPException(status_code=400, detail="No table data found in PDF")
            
            # Process the extracted data
            return self._process_pdf_dataframe(df,headers, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF processing failed: {e}")

    def _normalize(self, s: str) -> str:
        if s is None:
            return ""
        return (
            str(s).strip().lower()
            .replace(".", "")
            .replace(":", "")
            .replace(",", "")
            .replace("ı", "i")
            .replace("İ", "i")
        )

    def _find_headers_positions(self, blocks: List[Dict], headers: List[str]) -> Tuple[Dict[str, float], float]:
        """
        Sayfadaki header span'larını tüm bloklarda arar, header->X haritasını döndürür.
        Ayrıca bulunan header'ların en küçük Y'sini 'header_y' olarak verir.
        En az bir header bulunduysa header_y döner; hiç yoksa ( {}, 40.0 ).
        """
        header_positions: Dict[str, float] = {}
        norm_expected = {self._normalize(h): h for h in headers}
        found_y_vals = []

        for block in blocks:
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    txt = span.get("text", "").strip()
                    txt_norm = self._normalize(txt)
                    if txt_norm in norm_expected:
                        original = norm_expected[txt_norm]
                        # İlk gören kazanır (sağlaması için tekrar yazmıyoruz)
                        header_positions.setdefault(original, span.get("bbox", [0, 0, 0, 0])[0])
                        found_y_vals.append(span.get("bbox", [0, 0, 0, 0])[1])

        header_y = min(found_y_vals) if found_y_vals else 40.0
        return header_positions, header_y
    
    def _extract_pdf_table_data(self, pdf_content: bytes, headers: List[str]) -> pd.DataFrame:
        try:
            doc = fitz.open(stream=pdf_content, filetype="pdf")
            all_data_rows = []

            for page_num, page in enumerate(doc):
                blocks = page.get_text("dict")["blocks"]

                # 1) Header X konumlarını ve header_y'yi TUM bloklardan çıkar
                header_positions, header_y = self._find_headers_positions(blocks, headers)
                if len(header_positions) < len(headers):
                    logger.warning(f"Not all headers found on page {page_num + 1} {header_positions} {len(headers)}")
                    # Header'ların bir kısmı bile bulunsa y'yi yine de kullanıp denemek isteyebilirsin,
                    # ama güvenilir hizalama olmayacağı için sayfayı atlamak daha doğru.
                    continue

                # 2) Header'in ALTINDA kalan metinleri topla
                spans = self._extract_text_spans(blocks, header_y)
                if not spans:
                    logger.warning(f"No text spans found on page {page_num + 1}")
                    continue

                # 3) Satır gruplama + en yakın header X konumuna sütun atama
                page_data = self._group_spans_to_rows(spans, headers, header_positions)
                all_data_rows.extend(page_data)

            doc.close()

            if not all_data_rows:
                logger.warning("No data rows extracted from PDF")
                return pd.DataFrame()

            return pd.DataFrame(all_data_rows, columns=headers)

        except Exception as e:
            logger.error(f"PDF table extraction failed: {e}")
            raise Exception(f"Failed to extract table from PDF: {e}")
        
    def _find_header_position(self, blocks: List[Dict], headers: List[str]) -> float:
        """
        Find the Y position of header row in PDF.
        
        Args:
            blocks: Text blocks from PDF
            headers: Expected headers
            
        Returns:
            Y position of header row, None if not found
        """
        for block in blocks:
            if block.get("type") != 0:  # Only text blocks
                continue   
            for line in block.get("lines", []):
                
                for span in line.get("spans", []):
                    text = span.get("text", "").strip()
                    if any(text.lower() == header.lower() for header in headers):
                        y_coordinate = span.get("bbox", [0, 0, 0, 0])[1]
                        return y_coordinate
        
        # Fallback to a default position
        return 40.0
    
    def _extract_text_spans(self, blocks: List[Dict], header_y: float) -> List[Dict]:
        """
        Extract text spans from PDF blocks below header position.
        
        Args:
            blocks: Text blocks from PDF
            header_y: Y position of header
            
        Returns:
            List of text span dictionaries
        """
        spans = []
        
        for block in blocks:
            if block.get("type") != 0:  # Only text blocks
                continue
                
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    x = span.get("bbox", [0])[0]
                    y = span.get("bbox", [0])[1]
                    text = span.get("text", "").strip()
                    
                    # Only include spans below header and above page bottom
                    if text and header_y < y < 780:
                        spans.append({"x": x, "y": y, "text": text})
        
        return spans
    
    def _get_header_positions(self, spans: List[Dict], headers: List[str]) -> Dict[str, float]:
        """
        Get X positions for each header.
        
        Args:
            spans: Text spans from PDF
            headers: Expected headers
            
        Returns:
            Dictionary mapping headers to X positions
        """
        header_positions = {}
        for header in headers:
            for span in spans:
                if span["text"].strip().lower() == header.strip().lower():
                    header_positions[header] = span["x"]
                    break
        
        return header_positions
    
    def _group_spans_to_rows(
        self, 
        spans: List[Dict], 
        headers: List[str], 
        header_positions: Dict[str, float]
    ) -> List[List[str]]:
        """
        Group text spans into rows and assign to columns.
        
        Args:
            spans: Text spans from PDF
            headers: Column headers
            header_positions: X positions of headers
            
        Returns:
            List of data rows
        """
        # Sort spans by Y position (row) then X position (column)
        spans.sort(key=lambda s: s["y"])
        
        # Group spans by Y position (same row)
        grouped_lines = []
        current_group = []
        current_y = None
        tolerance = 5  # Y position tolerance for same row
        
        for span in spans:
            if current_y is None:
                current_y = span["y"]
                
            if abs(span["y"] - current_y) <= tolerance:
                current_group.append(span)
            else:
                if current_group:
                    grouped_lines.append(current_group)
                current_group = [span]
                current_y = span["y"]
        
        if current_group:
            grouped_lines.append(current_group)
        
        # Process each row group
        data_rows = []
        
        for group in grouped_lines:
            # Skip if this group contains header text
            if any(span['text'].lower() in [h.lower() for h in headers] for span in group):
                continue
            
            # Sort group by X position
            group.sort(key=lambda s: s["x"])
            
            # Assign spans to columns based on X position proximity to headers
            row_data = {header: "" for header in headers}
            
            for span in group:
                # Find closest header by X position
                closest_header = min(
                    header_positions.items(),
                    key=lambda item: abs(item[1] - span["x"])
                )[0]
                
                # Concatenate text if multiple spans map to same column
                if row_data[closest_header]:
                    row_data[closest_header] += " " + span["text"]
                else:
                    row_data[closest_header] = span["text"]
            
            # Convert to list in header order
            row_list = [row_data.get(header, "") for header in headers]
            data_rows.append(row_list)
        
        return data_rows
    
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
            items = self._pdf_dataframe_to_items(df, headers, account_number, period_id)
            
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
    
    
    def _pdf_dataframe_to_items(
        self,
        df: pd.DataFrame,
        headers: List[str],
        account_number: int,
        period_id: int
    ) -> List[TrialBalanceItem]:
        """
        Convert PDF DataFrame to TrialBalanceItem objects.
        
        Args:
            df: Source DataFrame
            headers: list of headers
            account_number: Account number
            period_id: Period ID
            
        Returns:
            List of TrialBalanceItem objects
        """
        items = []
        for _, row in df.iterrows():
            try:
                account_code = str(row.get(headers[0], '')).strip()
                account_name = str(row.get(headers[1], '')).strip()
                debit  = parse_numeric_value(row.get(headers[2], 0))
                credit = parse_numeric_value(row.get(headers[3], 0))
                if debit == 0 and credit == 0:
                   continue
                db_raw = row.get(headers[4], None) if len(headers)>4 else None
                cb_raw = row.get(headers[5], None) if len(headers)>5 else None 
                debit_balance, credit_balance = compute_balances(debit, credit, db_raw, cb_raw)
                logger.info(f"Computed balances for {account_code}: Debit={debit}, Credit={credit}, DB_raw={db_raw}, CB_raw={cb_raw}, Debit Balance={debit_balance}, Credit Balance={credit_balance}")
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
            except Exception as e:
                logger.warning(f"Failed to process PDF row: {e}")
                continue
        
        return items
    
