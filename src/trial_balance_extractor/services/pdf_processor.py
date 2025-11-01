"""PDF processing service with OCR capabilities."""

import logging
import fitz  # PyMuPDF
import pandas as pd
import re
from fastapi import HTTPException
from typing import List, Optional, Dict, Tuple

from ..models.schemas import TrialBalanceItem, ProcessingResult
from ..utils.text_processing import compute_balances, find_parent_code, parse_numeric_value
from .tree_builder import TreeBuilder
from .database_service import DatabaseService

logger = logging.getLogger(__name__)
Rect = Dict[str, float]  # {"x1":..., "y1":..., "x2":..., "y2":...}


class PDFProcessor:
    """Service for processing PDF files with OCR."""
    
    def __init__(self):
        """Initialize PDF processor with dependencies."""
        self.tree_builder = TreeBuilder()
        self.db_service = DatabaseService()
    
    # --------------------------------------------------
    # Yardımcı metotlar
    # --------------------------------------------------
    def _is_number_like(self, value) -> bool:
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

    def _is_data_row(self, row, headers):
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
        headers: List[str],
        account_number: Optional[int] = None,
        period_id: Optional[int] = None
    ) -> List[TrialBalanceItem]:
        """
        Convert DataFrame to TrialBalanceItem objects.
        """
        items = []
        is_data_row_count = 0
        total_df_rows = len(df)
        for _, row in df.iterrows():
            # Header satırıysa atla
            if not self._is_data_row(row, headers):
                is_data_row_count += 1
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

        return items
    
    def _normalize_money_text(self, raw: str) -> str | None:
        """
        Parasal metinse normalize edip sayıyı döndürür.
        Binlik ayraçlar kaldırılır, ondalık ayraç '.' haline getirilir.
        Örnek:
            "1.234,56" → "1234.56"
            "1,234.56" → "1234.56"
            "5244,83"  → "5244.83"
        """
        if not raw:
            return None

        t = raw.strip()
        t = re.sub(r"(?i)[₺$€]|(tl|try|usd|eur)", "", t).strip()
        t = t.replace(" ", "")

        if "," in t and "." in t:
            # "1.234,56" → "." binlik, "," ondalık
            cleaned = t.replace(".", "").replace(",", ".")
        elif "," in t:
            # "5244,83" → "," ondalık
            cleaned = t.replace(",", ".")
        else:
            cleaned = t

        # Geriye sadece rakamlar ve en fazla bir nokta kalmalı
        if re.fullmatch(r"\d+(\.\d+)?", cleaned):
            return cleaned
        return None
    
    # ----------------- geometry helpers -----------------
    def _to_rect(self, bbox: Tuple[float, float, float, float]) -> Rect:
        x1, y1, x2, y2 = bbox
        return {"x1": float(x1), "y1": float(y1), "x2": float(x2), "y2": float(y2)}

    def _rect_center_x(self, r: Rect) -> float:
        return (r["x1"] + r["x2"]) / 2.0

    def _intersection_area(self, r1: Rect, r2: Rect) -> float:
        x_left = max(r1["x1"], r2["x1"])
        y_top = max(r1["y1"], r2["y1"])
        x_right = min(r1["x2"], r2["x2"])
        y_bottom = min(r1["y2"], r2["y2"])
        if x_right <= x_left or y_bottom <= y_top:
            return 0.0
        return (x_right - x_left) * (y_bottom - y_top)

    def _build_column_bands(
        self,
        headers_pos: Dict[str, Tuple[float, Tuple[float, float, float, float]]],
        item_bboxes: List[Tuple[float, float, float, float]],
        y_pad: float = 0.0
    ) -> List[Tuple[str, Dict[str, float]]]:
            """
            Header bbox'larından X ekseni boyunca kolon şeritleri (band) çıkarır.
            Mizan tipik düzenine göre optimize edildi:
            - 1. kolon (Hesap Kodu) çok geniş olmamalı (max 75 px)
            - 1. -> 2. geçişte merkez yerine 1. header'ın SAĞI ile 2. header'ın SOLU'nun ortası kullanılabilir
            - Diğer kolonlar yine merkezlerin ortasından bölünür
            """
            if not headers_pos:
                return []

            # (name, rect, center_x, left_x, right_x)
            hdrs = []
            for name, (_xpos, hbbox) in headers_pos.items():
                r = self._to_rect(hbbox)
                cx = self._rect_center_x(r)
                hdrs.append((name, r, cx, r["x1"], r["x2"]))

            # soldan sağa
            hdrs.sort(key=lambda t: t[1]["x1"])

            # Y aralığını belirle
            if item_bboxes:
                all_y1 = [self._to_rect(b)["y1"] for b in item_bboxes]
                all_y2 = [self._to_rect(b)["y2"] for b in item_bboxes]
                y1 = min(all_y1) - y_pad
                y2 = max(all_y2) + y_pad
            else:
                # item yoksa header'ın altından uzun bir bant
                headers_y2 = [t[1]["y2"] for t in hdrs]
                base = max(headers_y2) if headers_y2 else 0.0
                y1, y2 = base, base + 10000.0

            bands: List[Tuple[str, Dict[str, float]]] = []

            # 1. kolon için max genişlik (mizanlarda çoğu kez yeterli)
            MAX_FIRST_COL_WIDTH = 75.0

            for i, (name, hrect, cx, left_x, right_x) in enumerate(hdrs):
                # TEK header varsa
                if len(hdrs) == 1:
                    bands.append((
                        name,
                        {"x1": left_x, "y1": y1, "x2": right_x, "y2": y2}
                    ))
                    break

                # İLK kolon
                if i == 0:
                    # Başlangıç: kendi solundan
                    x1b = left_x

                    # 2. header
                    _n2, hrect2, cx2, left_x2, right_x2 = hdrs[i+1]

                    # Normalde merkezlerin ortası:
                    x2_candidate = (cx + cx2) / 2.0

                    # Ama mizan tipinde 1. kolon dar olmalı → 1. header'ın SAĞI ile 2. header'ın SOLU'nun ortasını deneyelim
                    # Bu genellikle "Hesap Kodu" / "Hesap Açıklaması" ayrımını daha iyi yapıyor
                    between_by_edges = (right_x + left_x2) / 2.0

                    # hangisi daha dar ise onu al
                    x2b = min(x2_candidate, between_by_edges)

                    # yine de çok genişse kes
                    if (x2b - x1b) > MAX_FIRST_COL_WIDTH:
                        x2b = x1b + MAX_FIRST_COL_WIDTH

                # SON kolon
                elif i == len(hdrs) - 1:
                    # sol sınır = öncekiyle merkezlerin ortası
                    _pn, _pr, pcx, _pl, _prx = hdrs[i-1]
                    x1b = (pcx + cx) / 2.0
                    # sağ sınır = kendi header'ının sağı
                    x2b = right_x

                # ORTA kolonlar
                else:
                    # önceki ve sonraki header'ların merkezlerinin ortaları
                    _pn, _pr, pcx, _pl, _prx = hdrs[i-1]
                    _nn, _nr, ncx, _nl, _nrx = hdrs[i+1]

                    x1b = (pcx + cx) / 2.0
                    x2b = (cx + ncx) / 2.0

                # güvenlik
                if x2b < x1b:
                    x1b, x2b = x2b, x1b

                bands.append((
                    name,
                    {
                        "x1": float(x1b),
                        "y1": float(y1),
                        "x2": float(x2b),
                        "y2": float(y2),
                    }
                ))

            # son olarak soldan sağa sırala
            bands.sort(key=lambda t: t[1]["x1"])
            return bands

    def _choose_header_for_item(self, bands: List[Tuple[str, Rect]], item_r: Rect) -> Optional[str]:
        """En büyük kesişim alanına sahip band'ın adını döndürür; eğer hiç kesişim yoksa None döner."""
        best_name, best_area = None, 0.0
        for name, band_r in bands:
            area = self._intersection_area(item_r, band_r)
            if area > best_area:
                best_area = area
                best_name = name
        # Eğer maksimum alan 0 veya çok küçükse -> hiç örtüşme yok
        if best_area <= 0.0:
            return None
        return best_name
    
    # --------------------------------------------------
    # ana parse metotları
    # --------------------------------------------------
    def _extract_pdf_data(self, pdf_bytes: bytes, headers: List[str]) -> pd.DataFrame:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        all_data_rows = []

        header_x_positions, header_y = self._get_header_Info(doc, headers)
        header_texts_lower = {h.lower().strip() for h in headers}

        for page in doc:
            blocks = page.get_text("dict")["blocks"]
            data_list = self._get_groupped_data(blocks, header_y)

            # önceki satırın açıklama X’i (devam satırını yakalamak için)
            last_desc_x1 = None
            last_desc_x2 = None

           
            for data in data_list:
                # header satırını atla
                if any(str(g["text"]).strip().lower() in header_texts_lower for g in data):
                    continue

                item_bboxes = [s["bbox"] for s in data if "bbox" in s]
                bands = self._build_column_bands(header_x_positions, item_bboxes, y_pad=4.0)

                row_dict = {h: "" for h in headers}
                data_info = []

                first_col_name = headers[0] if headers else None
                second_col_name = headers[1] if len(headers) > 1 else None
                money_cols = set(headers[2:])  # borç, alacak, bakiyeler

                for s in data:
                    item_r = self._to_rect(tuple(s["bbox"]))
                    chosen_header = self._choose_header_for_item(bands, item_r)
                    text_val = str(s["text"]).strip()

                    data_info.append({
                        "text": s["text"],
                        "x": s["x"],
                        "y": s["y"],
                        "bbox": s["bbox"],
                        "header": chosen_header
                    })

                    # 0) header yok ama kod formatında → zorla 1. kolon
                    if (
                        chosen_header is None
                        and first_col_name
                        and not row_dict.get(first_col_name)
                        and re.fullmatch(r"\d+(?:\.\d+)*", text_val)
                    ):
                        row_dict[first_col_name] = text_val
                        continue

                    if chosen_header is None:
                        continue

                    existing_val = row_dict.get(chosen_header, "").strip()

                    # 1) 1. kolon dolu + harfli span → 2. kolona zorla
                    if (
                        first_col_name
                        and chosen_header == first_col_name
                        and existing_val
                        and re.search(r"[A-Za-zÇĞİÖŞÜçğıöşü]", text_val)
                    ):
                        if second_col_name:
                            second_val = row_dict.get(second_col_name, "").strip()
                            if not second_val:
                                row_dict[second_col_name] = text_val
                                continue
                        # 2. kolon da doluysa hiç yazma
                        continue

                    # normal yazma
                    if existing_val:
                        row_dict[chosen_header] = f"{existing_val} {text_val}".strip()
                    else:
                        row_dict[chosen_header] = text_val

                #logger.info(f"data_info={data_info}")

                # --------------------------------------------------------
                # BURASI YENİ: Devam satırı kontrolü
                # --------------------------------------------------------
                is_first_empty = (not row_dict.get(first_col_name)) if first_col_name else True

                has_money = any(
                    row_dict.get(col) for col in money_cols
                )

                desc_text = row_dict.get(second_col_name, "") if second_col_name else ""

                # devam satırı sayılabilmesi için:
                # - hesap kodu boş
                # - parasal alan yok (yani bu satırda tutar yok)
                # - açıklama dolu
                # - önceki satır varsa ve onun açıklaması varsa
                is_continuation = (
                    is_first_empty
                    and not has_money
                    and desc_text
                    and len(all_data_rows) > 0
                    and second_col_name in all_data_rows[-1]
                    and all_data_rows[-1].get(second_col_name)
                )

                # ayrıca X hizasına da bakalım: aynı açıklama kolonuna yakın mı?
                if is_continuation:
                    # bu satırdaki açıklamanın x merkezini bul
                    # data_info içinden, header'ı açıklama olanı alalım
                    cur_desc_center = None
                    for d in data_info:
                        if d["header"] == second_col_name:
                            bx1, by1, bx2, by2 = d["bbox"]
                            cur_desc_center = (bx1 + bx2) / 2.0
                            break

                    x_ok = True
                    if last_desc_x1 is not None and last_desc_x2 is not None and cur_desc_center is not None:
                        # açıklama band aralığının biraz dışına çıkıyorsa continuation olmasın
                        x_ok = (last_desc_x1 - 15) <= cur_desc_center <= (last_desc_x2 + 15)

                    if x_ok:
                        # önceki satırın açıklamasının sonuna ekle
                        prev_desc = all_data_rows[-1][second_col_name]
                        all_data_rows[-1][second_col_name] = f"{prev_desc} {desc_text}".strip()
                        # bu satırı DF’e eklemiyoruz!
                        continue

                # devam satırı değilse normal ekle
                if any(v for v in row_dict.values()):
                    all_data_rows.append(row_dict)

                    # son açıklamanın x aralığını kaydet
                    if second_col_name and row_dict.get(second_col_name):
                        # o satırdaki açıklamayı data_info'dan bulup x1/x2'sini al
                        for d in data_info:
                            if d["header"] == second_col_name:
                                bx1, by1, bx2, by2 = d["bbox"]
                                last_desc_x1 = bx1
                                last_desc_x2 = bx2
                                break

        df = pd.DataFrame(all_data_rows, columns=headers)
        return df

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

    # ----------------------------
    # YENİ: İlk sayfadan başlık X'leri ve header_y tespiti
    # ----------------------------
    def _get_header_Info(self, doc: fitz.Document, headers: List[str]) -> tuple[dict, float]:
        """
        İlk sayfadan:
        - her header'ın X pozisyonunu (sol x) ve bbox değerini
        - verinin hangi Y'den sonra başladığını (header_y)
        tespit eder ve döndürür.
        """
        if len(doc) == 0:
            return {}, 40.0  # emniyet

        page0 = doc[0]
        blocks = page0.get_text("dict")["blocks"]

        def norm(t: str) -> str:
            return " ".join(t.strip().lower().split())

        header_set_norm = [norm(h) for h in headers]

        header_line_y_candidates = []
        header_spans = []

        for block in blocks:
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                line_spans = line.get("spans", [])
                hits = []
                for s in line_spans:
                    text = s.get("text", "").strip()
                    if not text:
                        continue
                    if norm(text) in header_set_norm:
                        hits.append(s)

                if hits:
                    y_vals = [s["bbox"][1] for s in line_spans if s.get("text")]
                    if y_vals:
                        header_line_y_candidates.append(min(y_vals))
                    for s in line_spans:
                        t = s.get("text", "").strip()
                        if norm(t) in header_set_norm:
                            header_spans.append(s)

        if header_line_y_candidates:
            header_y_base = min(header_line_y_candidates)
        else:
            header_y_base = 40.0

        if header_spans:
            header_tol = max((s["bbox"][3] - s["bbox"][1]) for s in header_spans)
        else:
            header_tol = 0.0
        header_y = header_y_base + header_tol + 2.0  # ekstra 2 birim boşluk

        # X pozisyonlarını topla (sol x en küçük olanı tercih et)
        header_x_positions: dict[str, tuple[float, list]] = {}
        if header_spans:
            for s in header_spans:
                t = s.get("text", "").strip()
                x = s["bbox"][0]
                try:
                    idx = header_set_norm.index(norm(t))
                    key = headers[idx]
                    if key not in header_x_positions or x < header_x_positions[key][0]:
                        header_x_positions[key] = (x, s["bbox"])
                except ValueError:
                    continue

        if header_x_positions:
            header_x_positions = dict(
                sorted(header_x_positions.items(), key=lambda kv: kv[1][0])
            )

        return header_x_positions, header_y
    
    def _get_groupped_data(self, blocks, header_y):
        def _safe_x(val):
            # x her zaman float olsun
            if isinstance(val, (int, float)):
                return float(val)
            if isinstance(val, str):
                v = val.strip().replace(",", ".")
                try:
                    return float(v)
                except Exception:
                    return 0.0
            return 0.0

        spans = []
        for block in blocks:    
            if block.get("type") != 0:
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    x = span.get("bbox", [0])[0]
                    y = span.get("bbox", [0])[1]
                    text = span.get("text", "").strip()
                    bbox = span.get("bbox")
                    if text and header_y  < y < 780:
                        spans.append({"x": x, "y": y, "text": text, "bbox": bbox})

        # y sonra x'e göre sırala
        spans.sort(key=lambda s: (s["y"], s["x"]))
        
       
        # y'ye göre grupla
        grouped_lines = []
        current_group = []
        current_y = None
        x_tol = 2  # aynı x kabul toleransı
        
        def merge_into_group(group, span, x_tol=2):
            """Aynı x'e sahip eleman varsa metni birleştirir, yoksa ekler."""
            for g in group:
                if abs(g["x"] - span["x"]) <= x_tol:
                    g["text"] = (g["text"] + " " + span["text"]).strip()
                    return
            group.append(span)
        logger.info(f"spans: {spans}")       
        for s in spans:
            if current_y is None:
                current_y = s["y"]

            # aynı satırdaysa (Y farkı 5'dan küçükse)
            if abs(s["y"] - current_y) <= 9.98:
                merge_into_group(current_group, s, x_tol)
            else:
                # önceki satırı kaydet
                if current_group:
                    grouped_lines.append(current_group)
                # yeni satır başlat
                current_group = []
                merge_into_group(current_group, s, x_tol)
                current_y = s["y"]

        # son satırı da ekle
        if current_group:
            grouped_lines.append(current_group)
       
        # --- şimdi ek satırları bir öncekiyle birleştir (tek elemanlı satırlar) ---
        i = 1
        while i < len(grouped_lines):
            curr = grouped_lines[i]
            prev = grouped_lines[i - 1]
            if len(curr) == 1:  # tek elemanlı grup
                s = curr[0]
                for p in prev:
                    if abs(p["x"] - s["x"]) <= x_tol:
                        p["text"] = (p["text"] + " " + s["text"]).strip()
                        grouped_lines.pop(i)
                        i -= 1
                        break
            i += 1
       
        # parasal filtre
        filtered_grouped = []
        for group in grouped_lines:
            new_group = []
            for idx, span in enumerate(group):
                text = span.get("text", "")

                # İlk iki span daima korunur
                if idx < 2:
                    new_group.append(span)
                    continue

                # 2. indexten sonrası: yalnızca parasal olanlar
                norm = self._normalize_money_text(text)
                if norm is not None:
                    span["text"] = norm  # normalize edilmiş hali yaz
                    new_group.append(span)
                # değilse atla
            if new_group:
                filtered_grouped.append(new_group)

        # her grubu x'e göre sırala
        filtered_grouped = [
            sorted(group, key=lambda s: _safe_x(s["x"])) for group in filtered_grouped
        ]
        return filtered_grouped
    
    
    #----------------------------------------------------
    # public metot
    #----------------------------------------------------
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
        """
        try:
            # Extract table data from PDF
            df = self._extract_pdf_data(file_content, headers)
            
            if df.empty:
                raise HTTPException(status_code=400, detail="No table data found in PDF")
            
            # Process the extracted data
            return self._process_pdf_dataframe_no_save(df, headers, separator, account_number, period_id)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF processing failed: {e}")
            raise HTTPException(status_code=500, detail=f"PDF processing failed: {e}")
