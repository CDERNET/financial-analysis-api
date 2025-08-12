# -*- coding: utf-8 -*-
from fastapi import FastAPI, UploadFile, File, Form,Query
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
    "AccountCode": ["Hesap Kodu", "Kod", "T.D. Hesap No", "MainAccount", "KODLAR","Hesap"],
    "AccountName": ["Hesap Adı", "Adı", "HESAP İSMİ", "hesabı","Acıklama"],
    "Debit": ["Borç", "Toplam Borç", "Borç Toplamı", "TL BORÇ","Borc"],
    "Credit": ["Alacak", "Toplam Alac.", "Alacak Toplamı", "TL ALACAK"],
    "DebitBalance": ["Borç Bakiye", "Bakiye Borç", "TL BORÇ BAKİYE","Borcbakıye"],
    "CreditBalance": ["Alacak Bakiye", "Bakiye Alac.", "TL ALACAK BAKİYE","Alacakbakıye"]
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
    for i in range(len(code) - 1, 0, -1):
        candidate = code[:i]
        if candidate in all_codes:
            return candidate
    return None

def find_column_mapping(df: pd.DataFrame, column_map: dict) -> dict:
    mapping = {}
    df_columns = [str(col).strip().lower() for col in df.columns]
    for standard, synonyms in column_map.items():
        for syn in synonyms:
            if syn.strip().lower() in df_columns:
                original = df.columns[df_columns.index(syn.strip().lower())]
                mapping[standard] = original
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

# -------------------------- VERİ İŞLEME ----------------------------------------

def process_dataframe(df: pd.DataFrame, kod_kolon_adi: str, ayrac: str, account_number: int, period_id: int):
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
            logging.debug(f"Tree structure: {flat_data}")
            insert_into_mssql(flat_data)
            return JSONResponse(content={"message": f"{len(flat_data)} rows inserted into AccountDetailPlan."})

    return JSONResponse(content={"error": "No valid header row found."}, status_code=400)

# ----------------------------- ENDPOINT ----------------------------------------

@app.post("/excel", summary="Excel dosyasından mizan verisi al ve MSSQL'e aktar")
async def read_excel(
    file: UploadFile = File(..., description="Excel, XLS veya CSV formatında mizan dosyası"),
    kod_kolon_adi: str = Form(..., description="Hesap kodlarını içeren kolonun adı", example="Hesap Kodu"),
    ayrac: str = Form(".", description="Hesap kodlarında parent-child ayracı", example="."),
    account_number: int = Form(..., description="Müşteri ID'si"),
    period_id: int = Form(..., description="Dönem bilgisi")
):
    # Başlangıç zamanı
    start_time = datetime.now()
    print(f"[INFO] İşlem başladı: {start_time}")

    contents = await file.read()
    filename = file.filename.lower()

    try:
        if filename.endswith(".xlsx"):
            xls = pd.ExcelFile(BytesIO(contents), engine="openpyxl")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                result= process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)
                 # Bitiş zamanı
                end_time = datetime.now()
                elapsed_time = (end_time - start_time).total_seconds()

                print(f"[INFO] İşlem bitti: {end_time} | Geçen süre: {elapsed_time} sn")
                return result
        elif filename.endswith(".xls"):
            xls = pd.ExcelFile(BytesIO(contents), engine="xlrd")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                result= process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)
        elif filename.endswith(".csv"):
            df = pd.read_csv(BytesIO(contents)).fillna("").astype(str)
            result= process_dataframe(df, kod_kolon_adi, ayrac, account_number, period_id)

        

        return JSONResponse(content={"error": "Invalid file format"}, status_code=400)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)



from decimal import Decimal

@app.get("/account-tree", summary="AccountNumber ve periodId'a göre (isteğe bağlı hesap koduyla) hesap ağacı getir")
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
                    SELECT child.* FROM AccountDetailPlan child
                    INNER JOIN RecursiveTree parent ON child.ParentAccountCode = parent.AccountCode
                    WHERE child.AccountNumber = ? AND child.PeriodId= ?
                )
                SELECT * FROM RecursiveTree
            """
            cursor.execute(query, account_number, period_id, root_code, account_number, period_id)
        else:
            query = """
                SELECT * FROM CustomerDetailedTrialBalance WHERE AccountNumber = ? AND PeriodId = ?
            """
            cursor.execute(query, account_number, period_id)

        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()

        def convert_decimal(obj):
            return float(obj) if isinstance(obj, Decimal) else obj

        data = [
            {col: convert_decimal(val) for col, val in zip(columns, row)}
            for row in rows
        ]

        tree = build_tree(data, kod_kolon_adi="AccountCode", parent_kolon_adi="ParentAccountCode")
        return JSONResponse(content=tree)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

# ----------------------------- RUNNER -----------------------------------------

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
