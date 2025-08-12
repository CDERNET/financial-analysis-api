# -*- coding: utf-8 -*-
from fastapi import FastAPI, UploadFile, File, Form, Query, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from enum import Enum
from io import BytesIO
import fitz  # PyMuPDF
import pandas as pd
import uvicorn
import logging
import re
import unicodedata
import pyodbc
from datetime import datetime
from decimal import Decimal

logging.basicConfig(level=logging.DEBUG)

# ----------------------------- MSSQL CONFIG -----------------------------------
MSSQL_CONFIG = {
    "server": "mssql",  # docker-compose servisi
    "database": "MizanDB",
    "username": "sa",
    "password": "Password123!",
    "driver": "{ODBC Driver 18 for SQL Server}"
}

def get_mssql_connection():
    conn_str = (
        f"DRIVER={MSSQL_CONFIG['driver']};"
        f"SERVER={MSSQL_CONFIG['server']};"
        f"DATABASE={MSSQL_CONFIG['database']};"
        f"UID={MSSQL_CONFIG['username']};"
        f"PWD={MSSQL_CONFIG['password']};"
        f"TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str)

# ----------------------------- API APP ----------------------------------------
class OutputFormat(str, Enum):
    excel = "excel"
    json = "json"

app = FastAPI(
    title="MIZAN OCR API",
    description="MIZAN PDF/Excel'den başlık bazlı veri çıkarımı ve ağaç yapısına dönüştürme",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --------------------------- DESTEK TABLOLAR ----------------------------------

COLUMN_MAP = {
    "AccountCode": ["Hesap Kodu", "Kod", "T.D. Hesap No", "MainAccount", "KODLAR", "Hesap"],
    "AccountName": ["Hesap Adı", "Adı", "HESAP İSMİ", "hesabı", "Acıklama", "Açıklama"],
    "Debit": ["Borç", "Toplam Borç", "Borç Toplamı", "TL BORÇ", "Borc"],
    "Credit": ["Alacak", "Toplam Alac.", "Alacak Toplamı", "TL ALACAK"],
    "DebitBalance": ["Borç Bakiye", "Bakiye Borç", "TL BORÇ BAKİYE", "Borcbakıye", "Bak. Borç", "BAK. BORÇ"],
    "CreditBalance": ["Alacak Bakiye", "Bakiye Alac.", "TL ALACAK BAKİYE", "Alacakbakıye", "Bak. Alacak", "BAK. ALACAK"]
}

KEYWORDS = [x for values in COLUMN_MAP.values() for x in values]

# --------------------------- YARDIMCI FONK. -----------------------------------

def clean_text(text):
    if not isinstance(text, str):
        text = str(text)
    text = unicodedata.normalize("NFKD", text)
    text = re.sub(r'\s+', '', text)
    return text.upper()

def find_parent_code(code: str, all_codes: set, separator: str) -> Optional[str]:
    if not isinstance(code, str):
        return None
    parts = code.split(separator)
    while parts:
        parts = parts[:-1]
        candidate = separator.join(parts)
        if candidate in all_codes:
            return candidate
    # Ayraç yoksa/yanlışsa: kısaltarak ara
    for i in range(len(code) - 1, 0, -1):
        candidate = code[:i]
        if candidate in all_codes:
            return candidate
    return None

def find_column_mapping(df: pd.DataFrame, column_map: dict) -> dict:
    mapping = {}
    norm_cols = {clean_text(str(col)): col for col in df.columns}
    for standard, synonyms in column_map.items():
        for syn in synonyms:
            norm = clean_text(syn)
            if norm in norm_cols:
                mapping[standard] = norm_cols[norm]
                break
    return mapping

def build_tree(data: List[dict], kod_kolon_adi: str, parent_kolon_adi: str = "parent_kodu") -> List[dict]:
    items = {row[kod_kolon_adi]: dict(row) for row in data if kod_kolon_adi in row}
    tree = []
    for item in items.values():
        item["children"] = []
    for item in items.values():
        parent_key = item.get(parent_kolon_adi)
        if parent_key and parent_key in items:
            items[parent_key]["children"].append(item)
        else:
            tree.append(item)
    return tree

def float_safe(val):
    try:
        if isinstance(val, str):
            v = val.replace('.', '').replace(',', '.')
            return float(v)
        return float(val)
    except (ValueError, TypeError):
        return 0.0

def flatten_tree(tree: List[dict], mapping: dict, account_number: int, period_id: int) -> List[dict]:
    result = []
    def recurse(nodes):
        for node in nodes:
            flat_node = {
                "AccountCode": node.get(mapping.get("AccountCode", ""), ""),
                "AccountName": node.get(mapping.get("AccountName", ""), ""),
                "Debit": float_safe(node.get(mapping.get("Debit", ""), 0)),
                "Credit": float_safe(node.get(mapping.get("Credit", ""), 0)),
                "DebitBalance": float_safe(node.get(mapping.get("DebitBalance", ""), 0)),
                "CreditBalance": float_safe(node.get(mapping.get("CreditBalance", ""), 0)),
                "ParentAccountCode": node.get("parent_kodu"),
                "AccountNumber": account_number,
                "PeriodId": period_id
            }
            result.append(flat_node)
            recurse(node.get("children", []))
    recurse(tree)
    return result

def insert_into_mssql(flat_data: List[dict]):
    if not flat_data:
        return
    conn = get_mssql_connection()
    cursor = conn.cursor()
    for row in flat_data:
        cursor.execute("""
            INSERT INTO CustomerDetailedTrialBalance (
                AccountCode, AccountName,
                Debit, Credit, DebitBalance, CreditBalance,
                ParentAccountCode, AccountNumber, PeriodId
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            row["AccountCode"], row["AccountName"],
            row["Debit"], row["Credit"], row["DebitBalance"], row["CreditBalance"],
            row["ParentAccountCode"], row["AccountNumber"], row["PeriodId"]
        ))
    conn.commit()
    cursor.close()
    conn.close()

# -------------------------- VERİ İŞLEME (Excel ham DF) ------------------------

def process_dataframe(df: pd.DataFrame, kod_kolon_adi: str, ayrac: str, account_number: int, period_id: int):
    """
    Header satırını veri içinde arar, DF'i başlıklandırır, parent-child kurar ve DB'ye yazar.
    """
    for i, row in df.iterrows():
        normalized = [cell.strip().lower() for cell in row]
        match_count = sum(1 for cell in normalized if cell in [k.lower() for k in KEYWORDS])
        if match_count >= 3:
            header_row = i
            df.columns = df.iloc[header_row]
            df = df.iloc[header_row + 1:].reset_index(drop=True)

            mapping = find_column_mapping(df, COLUMN_MAP)
            if "AccountCode" not in mapping:
                return JSONResponse(content={"error": "AccountCode column not found."}, status_code=400)

            kod_kolon_real = mapping["AccountCode"]
            df[kod_kolon_real] = df[kod_kolon_real].astype(str).str.strip()
            all_codes = set(df[kod_kolon_real].dropna().unique())
            df["parent_kodu"] = df[kod_kolon_real].apply(lambda x: find_parent_code(x, all_codes, ayrac))

            data_list = df.to_dict(orient="records")
            tree = build_tree(data_list, kod_kolon_real)
            flat_data = flatten_tree(tree, mapping, account_number, period_id)
            logging.debug(f"Tree structure (flat) sample: {flat_data[:3]} | total: {len(flat_data)}")
            insert_into_mssql(flat_data)
            return JSONResponse(content={"message": f"{len(flat_data)} rows inserted into CustomerDetailedTrialBalance."})

    return JSONResponse(content={"error": "No valid header row found."}, status_code=400)

# -------------------------- VERİ İŞLEME (PDF DF için ortak akış) --------------

def process_structured_df_and_insert(
    df: pd.DataFrame,
    ayrac: str,
    account_number: int,
    period_id: int
) -> dict:
    mapping = find_column_mapping(df, COLUMN_MAP)
    if "AccountCode" not in mapping:
        raise ValueError("AccountCode (hesap kodu) kolonu eşleştirilemedi. Lütfen başlıkları kontrol edin.")

    kod_kolon = mapping["AccountCode"]

    df[kod_kolon] = df[kod_kolon].astype(str).str.strip()
    all_codes = set(df[kod_kolon].dropna().unique())
    df["parent_kodu"] = df[kod_kolon].apply(lambda x: find_parent_code(x, all_codes, ayrac))

    data_list = df.to_dict(orient="records")
    tree = build_tree(data_list, kod_kolon_adi=kod_kolon)
    flat_data = flatten_tree(tree, mapping, account_number, period_id)

    insert_into_mssql(flat_data)

    return {
        "inserted": len(flat_data),
        "account_number": account_number,
        "period_id": period_id
    }

# ---------------------------- PDF'den tablo çıkarma ----------------------------

def extract_pdf_data(pdf_bytes: bytes, headers: List[str]) -> pd.DataFrame:
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
            header_y = 40  # fallback

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

        for group in grouped_lines:
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
                    spans_h = col_buckets[h]
                    if len(spans_h) == 1:
                        row_dict[h] = spans_h[0][0]
                    else:
                        sorted_spans = sorted(spans_h, key=lambda s: s[2])
                        min_y_text = sorted_spans[0][0]
                        max_y_text = sorted_spans[-1][0]
                        row_dict[h] = min_y_text if min_y_text == max_y_text else f"{min_y_text} {max_y_text}"

            # Kod/Açıklama hizalama düzeltmeleri
            if len(headers) >= 2:
                kod_header = headers[0]
                aciklama_header = headers[1]
                if not row_dict[kod_header] and row_dict[aciklama_header] and all_data_rows:
                    prev_row = all_data_rows[-1]
                    aciklama_index = headers.index(aciklama_header)
                    prev_row[aciklama_index] = (prev_row[aciklama_index] or "") + " " + row_dict[aciklama_header]
                    continue

                if row_dict[aciklama_header] is None and row_dict[kod_header] and " " in row_dict[kod_header]:
                    parts = row_dict[kod_header].split("", 1)
                    # Yukarıdaki split hatası olmasın diye kontrol
                    if len(parts) == 2:
                        row_dict[kod_header] = parts[0]
                        row_dict[aciklama_header] = parts[1]

            all_data_rows.append([row_dict[h] for h in headers])

    df = pd.DataFrame(all_data_rows, columns=headers)
    return df

# ----------------------------- ENDPOINTS ---------------------------------------

@app.post("/excel", summary="Excel dosyasından mizan verisi al ve MSSQL'e aktar")
async def read_excel(
    file: UploadFile = File(..., description="Excel, XLS veya CSV formatında mizan dosyası"),
    kod_kolon_adi: str = Form(..., description="Hesap kodlarını içeren kolonun adı", example="Hesap Kodu"),
    ayrac: str = Form(".", description="Hesap kodlarında parent-child ayracı", example="."),
    account_number: int = Form(..., description="Müşteri ID'si"),
    period_id: int = Form(..., description="Dönem bilgisi")
):
    start_time = datetime.now()
    logging.info(f"[INFO] İşlem başladı: {start_time}")

    contents = await file.read()
    filename = file.filename.lower()

    try:
        if filename.endswith(".xlsx"):
            xls = pd.ExcelFile(BytesIO(contents), engine="openpyxl")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                result = process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)
                end_time = datetime.now()
                elapsed_time = (end_time - start_time).total_seconds()
                logging.info(f"[INFO] İşlem bitti: {end_time} | Geçen süre: {elapsed_time} sn")
                return result

        elif filename.endswith(".xls"):
            xls = pd.ExcelFile(BytesIO(contents), engine="xlrd")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                result = process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)
                return result

        elif filename.endswith(".csv"):
            df = pd.read_csv(BytesIO(contents)).fillna("").astype(str)
            result = process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)
            return result

        return JSONResponse(content={"error": "Invalid file format"}, status_code=400)
    except Exception as e:
        logging.exception("Excel işleme hatası")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/account-tree", summary="AccountNumber ve PeriodId'a göre (isteğe bağlı hesap koduyla) hesap ağacı getir")
def get_account_tree(
    account_number: int = Query(..., description="Müşteri ID'si"),
    period_id: str = Query(..., description="Dönem bilgisi "),
    root_code: Optional[str] = Query(None, description="Kök hesap kodu (isteğe bağlı)")
):
    try:
        conn = get_mssql_connection()
        cursor = conn.cursor()

        if root_code:
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
            query = "SELECT * FROM CustomerDetailedTrialBalance WHERE AccountNumber = ? AND PeriodId = ?"
            cursor.execute(query, account_number, period_id)

        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()

        def convert_decimal(obj):
            return float(obj) if isinstance(obj, Decimal) else obj

        data = [{col: convert_decimal(val) for col, val in zip(columns, row)} for row in rows]
        tree = build_tree(data, kod_kolon_adi="AccountCode", parent_kolon_adi="ParentAccountCode")
        return JSONResponse(content=tree)
    except Exception as e:
        logging.exception("Ağaç getirme hatası")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/pdf", summary="PDF'den tablo çıkar, parent-child kur, MSSQL'e yaz")
async def read_pdf(
    file: UploadFile = File(..., description="PDF dosyası yükleyin"),
    headers: str = Form(..., description="Başlıkları virgülle ayırarak girin (örnek: HESAP KODU, AÇIKLAMA, BORÇ, ALACAK, BAK. BORÇ, BAK. ALACAK)"),
    ayrac: str = Form(".", description="Hesap kodlarında parent-child ayracı", example="."),
    account_number: int = Form(..., description="Müşteri ID'si"),
    period_id: int = Form(..., description="Dönem bilgisi")
):
    try:
        header_list = [h.strip() for h in headers.split(",")]
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Başlıklar ayrıştırılamadı: {e}")

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="PDF dosyası bekleniyor")

    contents = await file.read()
    try:
        df = extract_pdf_data(contents, header_list)
        summary = process_structured_df_and_insert(
            df=df,
            ayrac=ayrac,
            account_number=account_number,
            period_id=period_id
        )
        return JSONResponse(content={
            "message": "PDF verileri işlendi ve veritabanına yazıldı.",
            **summary
        })
    except Exception as e:
        logging.exception("PDF işleme hatası")
        return JSONResponse(content={"error": str(e)}, status_code=500)

# ----------------------------- RUNNER -----------------------------------------

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)