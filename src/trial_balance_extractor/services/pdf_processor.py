"""PDF processing service with OCR capabilities."""

import logging
import re
import unicodedata


from typing import List, Dict, Tuple
import fitz  # PyMuPDF
import pandas as pd
from fastapi import HTTPException

from ..models.schemas import TrialBalanceItem, ProcessingResult
from ..utils.text_processing import compute_balances, find_parent_code, parse_numeric_value
from .tree_builder import TreeBuilder
from .database_service import DatabaseService


logger = logging.getLogger(__name__)
NUMERIC_RE = r"""^\s*[\(\-]?\d{1,3}(?:[.\s,]\d{3})*(?:[.,]\d+)?[%₺$€]?\)?\s*$"""

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
    
    #-------------------------yardımcılar
    def _norm(self,s: str) -> str:
        """
        Başlık ismi normalizasyonu: Türkçe karakterleri ASCII'ye çeker, boşluk/noktalama atar, üst-case.
        Örn: 'Hesap Adı' -> 'HESAPADI', 'Borç Toplamı' -> 'BORCTOPLAMI'
        """
        s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii")
        s = re.sub(r"\s+", "", s)
        s = re.sub(r"[^\w]", "", s)
        return s.upper()
    def _assign_to_zone(self,span: Dict, zones: List[Dict]) -> str:
        """
        Numeric: x1'e en yakın R sınırı olan zonu seç (x1 >= L - küçük bir tolerans ile).
        Text: mevcut L-R kapsama / merkeze yakın kuralı.
        """
        x0, x1 = span["x0"], span["x1"]
        txt = span["text"]

        if self._is_numeric(txt):
            tol = 6.0  # küçük bir tolerans: başlık sınırına çok yakın taşmaları yakalar
            viable = [z for z in zones if x1 >= z["L"] - tol]
            if not viable:
                viable = zones
            chosen = min(viable, key=lambda z: abs(x1 - z["R"]))
            return chosen["name"]

        # metinler için eski mantık
        p = (x0 + x1) / 2
        for z in zones:
            if z["L"] <= p <= z["R"]:
                return z["name"]
        nearest = min(zones, key=lambda z: abs(p - (z["L"] + z["R"]) / 2))
        return nearest["name"]
    def _group_rows(self,spans: List[Dict], y_tol: float = 5.0):
        """
        spans: [{x0,x1,y0,y1,text}]
        y_mid ile satır gruplama. y_tol = 5.0 -> font/ölçek için güvenli.
        """
        sorted_spans = sorted(spans, key=lambda s: (((s["y0"] + s["y1"]) / 2), s["x0"]))
        rows = []
        current = None
        for s in sorted_spans:
            y_mid = (s["y0"] + s["y1"]) / 2
            if current is None or abs(current["y_mid"] - y_mid) > y_tol:
                current = {"y_mid": y_mid, "cells": [s]}
                rows.append(current)
            else:
                current["cells"].append(s)
        return rows  
    def _is_numeric(self,text: str) -> bool:
        t = text.strip().replace("\u00A0", " ")
        if any(ch.isalpha() for ch in t):
            return False
        return re.match(NUMERIC_RE, t) is not None
    def _build_zones(self,header_boxes: List[Dict], padding: float = 6.0):
        """
        header_boxes: [{name, x0, x1, y0, y1}]
        return: [{name, L, R, center}]
        """
        headers_sorted = sorted(header_boxes, key=lambda h: ((h["x0"] + h["x1"]) / 2, h["x0"]))
        centers = [(h["x0"] + h["x1"]) / 2 for h in headers_sorted]
        min_left = min(h["x0"] for h in headers_sorted) - padding
        max_right = max(h["x1"] for h in headers_sorted) + padding

        zones = []
        for i, h in enumerate(headers_sorted):
            L = (centers[i - 1] + centers[i]) / 2 if i > 0 else min_left
            R = (centers[i] + centers[i + 1]) / 2 if i < len(headers_sorted) - 1 else max_right
            zones.append({"name": h["name"], "L": L, "R": R, "center": centers[i]})
        return zones

    #--------------------------------Yardımcılar sonu
    def _extract_pdf_table_data(self, pdf_content: bytes, headers: List[str]) -> pd.DataFrame:
        """
        Sağ kenarı esas alan numeric kararı ve header merkezlerinden çıkan kolon bölgeleriyle
        veriyi doğru başlık altına atar. headers: endpoint'ten gelen hedef başlık sırası.
        """
        try:
            doc = fitz.open(stream=pdf_content, filetype="pdf")
            all_rows = []
           
            # Hedef başlıkları ve normalize hallerini tut
            header_order = [h.strip() for h in headers]
            norm_targets = {self._norm(h): h for h in header_order}
            target_norm_set = set(norm_targets.keys())
            for page in doc:
                page_dict = page.get_text("dict")
                blocks = page_dict.get("blocks", [])

                # 1) Header span'larını bul (bbox) — normalize ederek karşılaştır
                header_boxes: List[Dict] = []
                header_y_top = None  # header satırının üst y0'ı

                for block in blocks:
                    if block.get("type") != 0:
                        continue
                    for line in block.get("lines", []):
                        for span in line.get("spans", []):
                            txt = span.get("text", "").strip()
                            if not txt:
                                continue
                            n = self._norm(txt)
                            if n in target_norm_set:
                                x0, y0, x1, y1 = span["bbox"]
                                header_boxes.append({"name": norm_targets[n], "x0": x0, "x1": x1, "y0": y0, "y1": y1})
                                header_y_top = y0 if header_y_top is None else min(header_y_top, y0)

                # Eğer hiçbir header bulunamazsa sayfayı atla
                if not header_boxes:
                    logging.debug("Sayfada hedef başlık bulunamadı, atlandı.")
                    continue

                # 2) Kolon bölgelerini üret
                zones = self._build_zones(header_boxes, padding=6.0)

                # Zone -> hedef başlık adı (zaten header_boxes name'i hedef adı)
                zone_to_header = {z["name"]: z["name"] for z in zones}

                # 3) Veri span’larını topla (header satırının altı)
                if header_y_top is None:
                    header_y_top = 40.0  # fallback
                usable_spans = []
                page_bottom = page.rect.br.y
                for block in blocks:
                    if block.get("type") != 0:
                        continue
                    for line in block.get("lines", []):
                        for span in line.get("spans", []):
                            txt = span.get("text", "").strip()
                            if not txt:
                                continue
                            x0, y0, x1, y1 = span["bbox"]
                            if (y0 > header_y_top) and (y0 < (page_bottom - 5)):  # header altı
                                usable_spans.append({"x0": x0, "x1": x1, "y0": y0, "y1": y1, "text": txt})

                # 4) Header satırlarını veri olarak alma
                lower_headers = {h.lower() for h in header_order}
                usable_spans = [s for s in usable_spans if s["text"].strip().lower() not in lower_headers]

                # 5) Satırlara grupla
                rows = self._group_rows(usable_spans, y_tol=5.0)

                # 6) Her satır için kolon ataması
                for r in rows:
                    col_texts = {h: [] for h in header_order}
                    for s in r["cells"]:
                        zone_name = self._assign_to_zone(s, zones)  # sayfadaki header adı
                        target_header = zone_to_header.get(zone_name, zone_name)
                        if target_header in col_texts:
                            col_texts[target_header].append(s["text"].strip())

                    # Çok parçalı metinleri birleştir (aynı kolonda)
                    row_out = [(" ".join(col_texts[h])).strip() if col_texts[h] else None for h in header_order]

                    # Opsiyonel: "Kod/Açıklama" yapışması düzeltmesi (ilk iki kolon için)
                    if len(header_order) >= 2:
                        kod_idx, ack_idx = 0, 1
                        # Açıklama var, kod yok ve önceki satır varsa -> açıklamayı üst satıra ekle (satır kırılması)
                        if (row_out[kod_idx] is None) and (row_out[ack_idx]) and all_rows:
                            all_rows[-1][ack_idx] = ((all_rows[-1][ack_idx] or "") + " " + row_out[ack_idx]).strip()
                            continue
                        # Kod dolu, açıklama boş; kod içinde boşlukla ayrılmışsa -> böl
                        if (row_out[ack_idx] is None) and (row_out[kod_idx]) and (" " in row_out[kod_idx]):
                            parts = row_out[kod_idx].split(" ", 1)
                            if len(parts) == 2:
                                row_out[kod_idx] = parts[0].strip()
                                row_out[ack_idx] = parts[1].strip()

                    all_rows.append(row_out)
              
            df = pd.DataFrame(all_rows, columns=headers)
            return df
        except Exception as e:
            logger.error(f"PDF table extraction failed: {e}")
            raise Exception(f"Failed to extract table from PDF: {e}")
        
   
 

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
   
