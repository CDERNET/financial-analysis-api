# -*- coding: utf-8 -*-
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from enum import Enum
from io import BytesIO
import fitz  # PyMuPDF
import pandas as pd
import uvicorn
import logging
import re
import unicodedata

logging.basicConfig(level=logging.DEBUG)

def clean_text(text):
    if not isinstance(text, str):
        text = str(text)
    text = unicodedata.normalize("NFKD", text)  # Unicode normalize
    text = re.sub(r'\s+', '', text)            # Tüm boşluk, tab, newline karakterlerini sil
    return text.upper()  

class OutputFormat(str, Enum):
    excel = "excel"
    json = "json"

app = FastAPI(
    title="MIZAN OCR API",
    description="MIZAN PDF/Excel'den başlık bazlı veri çıkarımı ve Excel / JSON'a dönüştürme",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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

@app.post("/pdf")
async def read_pdf(
    file: UploadFile = File(..., description="PDF dosyası yükleyin"),
    headers: str = Form(..., description="Başlıkları virgülle ayırarak girin (örnek: HESAP KODU, AÇIKLAMA, BORÇ, ALACAK, BAK. BORÇ, BAK. ALACAK)"),
    output_format: OutputFormat = Form(OutputFormat.excel, description="Çıktı formatı")
):
    try:
        header_list = [h.strip() for h in headers.split(",")]
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Başlıklar ayrıştırılamadı: {e}")
    logging.debug(file.filename)
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="PDF dosyası bekleniyor")

    contents = await file.read()
    df = extract_pdf_data(contents, header_list)

    if output_format == OutputFormat.json:
        return df.to_dict(orient="records")
    else:
        output = io.BytesIO()
        df.to_excel(output, index=False)
        output.seek(0)
        return StreamingResponse(
            output,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": "attachment; filename=result.xlsx"}
        )

KEYWORDS = ["TL BORÇ","TL ALACAK"	,"TL BORÇ BAKİYE",	"TL ALACAK BAKİYE","MainAccount","hesabı","HESAP İSMİ", "Ad","Adı", "Kapanış Bakiye","Borç", "Alacak", "Bakiye", "Hesap Kodu", "Hesap Adı", "Borç","Alacak", "Borç Bakiye", "Alacak Bakiye",
"(Tam) Hesap",	"Hesap Adı"	,"T.D. Hesap No",	"Toplam Borç",	"Toplam Alac."	,"Bakiye Borç",	"Bakiye Alac.",	"F.P.Br.","Borç Toplamı"	,"Alacak Toplamı",	
"KODLAR","HESAPLAR"	, "B/A BAKİYE"	, "USD BORÇ BAKİYE" 	,"USD ALACAK BAKİYE" ,	 "USD BAKİYE" ,	 "EUR BORÇ BAKİYE"	, "EUR ALACAK BAKİYE"	, "EUR BAKİYE" ]
		

@app.post("/excel")
async def read_excel(file: UploadFile = File(...)):
    contents = await file.read()
    filename = file.filename.lower()

    try:
        # Excel ve CSV formatlarını uygun engine ile oku
        if filename.endswith(".xlsx"):
            xls = pd.ExcelFile(BytesIO(contents), engine="openpyxl")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                response = process_dataframe(df, KEYWORDS)
                if response:
                    return response

        elif filename.endswith(".xls"):
            xls = pd.ExcelFile(BytesIO(contents), engine="xlrd")
            for sheet_name in xls.sheet_names:
                df = xls.parse(sheet_name, header=None).fillna("").astype(str)
                logging.debug(df)
                response = process_dataframe(df, KEYWORDS)
                if response:
                    return response

        elif filename.endswith(".csv"):
            df = pd.read_csv(BytesIO(contents)).fillna("").astype(str)
            return process_dataframe(df, KEYWORDS)

        else:
            return JSONResponse(
                content={"error": "Unsupported file format. Please upload .xlsx, .xls, or .csv"},
                status_code=400,
            )

        return JSONResponse(content={"error": "No matching header row found."}, status_code=400)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


def process_dataframe(df: pd.DataFrame, keywords: list):
    for i, row in df.iterrows():
        normalized = [cell.strip().lower() for cell in row]
        match_count = sum(1 for cell in normalized if cell in [k.lower() for k in keywords])
        if match_count >= 3:
            header_row = i
            df.columns = df.iloc[header_row]
            df = df.iloc[header_row + 1:].reset_index(drop=True)
            df = df[[col for col in df.columns if col.strip().lower() in [k.lower() for k in keywords]]]
            return JSONResponse(content=df.to_dict(orient="records"))
    return None






if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
