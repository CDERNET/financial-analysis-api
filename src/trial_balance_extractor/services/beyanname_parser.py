"""Beyanname (tax declaration) PDF parsing service."""

import io
import json
import logging
import re
from pathlib import Path
from typing import Optional, List, Dict, Any

import pdfplumber

logger = logging.getLogger(__name__)

# =============================================================================
# DEFINITIONS — JSON'dan yükle
# =============================================================================

_JSON_PATH = Path(__file__).resolve().parent.parent / "data" / "financial_item_definitions.json"

with open(_JSON_PATH, encoding="utf-8") as _f:
    FINANCIAL_ITEM_DEFINITIONS: list = json.load(_f)

_DEFN_BY_CODE: dict = {str(d["Code"]): d for d in FINANCIAL_ITEM_DEFINITIONS}


# =============================================================================
# LEVENSHTEIN
# =============================================================================

def _levenshtein(s1: str, s2: str) -> int:
    s1, s2 = s1.lower().strip(), s2.lower().strip()
    if s1 == s2:          return 0
    if not s1:            return len(s2)
    if not s2:            return len(s1)
    if len(s1) < len(s2): s1, s2 = s2, s1
    prev = list(range(len(s2) + 1))
    for c1 in s1:
        curr = [prev[0] + 1]
        for j, c2 in enumerate(s2):
            curr.append(min(prev[j+1]+1, curr[j]+1, prev[j]+(c1 != c2)))
        prev = curr
    return prev[-1]


# =============================================================================
# DEFINITION MATCHING
# =============================================================================

def _d3_leaf(d3: Optional[str]) -> str:
    if not d3: return ""
    last = d3.rstrip("/").split("/")[-1].strip()
    m = re.match(r"^\d+[-.\s]\s*(.+)$", last)
    return m.group(1).strip() if m else last


def _clean(s: Optional[str]) -> str:
    return re.sub(r"\s*\(-\)\s*$", "", (s or "")).strip().lower()


def _match_definition(aciklama: str) -> Optional[dict]:
    if not aciklama:
        return None
    cl   = _clean(aciklama)
    defs = FINANCIAL_ITEM_DEFINITIONS

    for d in defs:
        if _clean(d.get("Description")) == cl:
            return d
    for d in defs:
        v = _clean(d.get("Description2"))
        if v and v == cl:
            return d
    for d in defs:
        if _clean(_d3_leaf(d.get("Description3"))) == cl:
            return d

    raw = re.sub(r"\s*\(-\)\s*$", "", aciklama).strip()
    threshold = min(len(raw) // 3 + 2, 10)
    best, bd  = None, threshold + 1
    for d in defs:
        desc = re.sub(r"\s*\(-\)\s*$", "", (d.get("Description") or "")).strip()
        if not desc: continue
        dist = _levenshtein(raw, desc)
        if dist < bd:
            bd, best = dist, d
    return best if bd <= threshold else None


# =============================================================================
# OUTPUT ITEM
# =============================================================================

def _make_item(aciklama: str, identity: str, year: str, period: str,
               read_type: int, onceki: Optional[float], cari: Optional[float]) -> dict:
    defn = _match_definition(aciklama)
    return {
        "Code":                 defn.get("Code") if defn else None,
        "IdentityNumber":       identity,
        "Year":                 year,
        "Period":               period,
        "ReadType":             read_type,
        "Name":                 defn.get("Name") if defn else None,
        "PreviousPeriodValue":  onceki,
        "Value":                cari,
        "SearchingDescription": aciklama,
    }


# =============================================================================
# PDF READING
# =============================================================================

def _read_pdf(pdf_bytes: bytes) -> str:
    parts = []
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            t = page.extract_text()
            if t: parts.append(t)
    return "\n".join(parts)


# =============================================================================
# TYPE DETECTION + TRIM
# =============================================================================

def _detect_type(text: str) -> Optional[str]:
    h = text[:600]
    if re.search(r"\b1032\b", h) or "GEÇİCİ VERGİ BEYANNAMESİ"    in h: return "1032"
    if re.search(r"\b1010\b", h) or "KURUMLAR VERGİSİ BEYANNAMESİ" in h: return "1010"
    if re.search(r"1001\s*A\b", h, re.I) or "YILLIK GELİR VERGİSİ" in h: return "1001A"
    return None

_MARKERS = {
    "1010":  "KURUMLAR VERGİSİ BEYANNAMESİ",
    "1032":  "GEÇİCİ VERGİ BEYANNAMESİ",
    "1001A": "YILLIK GELİR VERGİSİ BEYANNAMESİ",
}

def _trim_to_type(text: str, btype: str) -> str:
    marker = _MARKERS.get(btype, "")
    idx    = text.find(marker)
    return text[idx:] if idx != -1 else text


# =============================================================================
# METADATA EXTRACTORS
# =============================================================================

def _extract_year(text: str) -> str:
    m = re.search(r"Y[ıi]l[ıi]?\s+(20\d{2})", text[:600])
    return m.group(1) if m else ""

def _extract_donem(text: str) -> str:
    m = re.search(r"D[öo]nem\s+([1-4])\.\s*D[öo]nem", text[:600])
    return m.group(1) if m else "4"

def _extract_vkn(text: str) -> str:
    for line in text.split("\n")[:20]:
        if "vergikimliknumaras" in re.sub(r"\s+", "", line.lower()):
            m = re.search(r"(\d{10,11})", line)
            if m: return m.group(1)
    return ""


# =============================================================================
# NUMBER HELPERS
# =============================================================================

_NUM_RE = re.compile(r"([\d\.]+,\d{2})")

def _parse_number(value: str) -> Optional[float]:
    try: return float(value.strip().replace(".", "").replace(",", "."))
    except: return None

def _extract_scalar(text: str, label: str) -> Optional[float]:
    matches = re.findall(re.escape(label) + r"[^\n]*?([\d\.]+,\d{2})", text, re.IGNORECASE)
    if not matches: return None
    parsed  = [_parse_number(v) for v in matches]
    nonzero = [v for v in parsed if v]
    return nonzero[0] if nonzero else parsed[0]


# =============================================================================
# BLOCK PARSER
# =============================================================================

_DOT_CODE = re.compile(r"^\.*\s*\d+\.\s+")
_ROMAN    = re.compile(r"^(I{1,3}V?|IV|VI{0,3}|IX|XI{1,2}|XII)\.\s+", re.U)
_SKIP     = re.compile(
    r"^(Açıklama|Önceki\s+Dönem|Cari\s+Dönem|\(\d{4}\)|TEK\s+DÜZEN|"
    r"AYRINTILI\s+BİLANÇO|AKTİF\s*$|PASİF\s*$|GELİR\s+TABLOSU\s*$|"
    r"AYRINTILI\s+GELİR\s+TABLOSU|Aktif\s*$|Pasif\s*$)$", re.I)

def _parse_raw_block(text: str, start_markers: list, end_marker: str) -> list:
    start_idx = -1
    for m in start_markers:
        idx = text.find(m)
        if idx != -1 and (start_idx == -1 or idx < start_idx):
            start_idx = idx
    if start_idx == -1: return []
    end_idx = text.find(end_marker, start_idx)
    section = text[start_idx:end_idx] if end_idx != -1 else text[start_idx:]
    rows = []
    for line in section.split("\n"):
        line = line.strip()
        if not line or _SKIP.match(line): continue
        if end_marker in line: break
        numbers = _NUM_RE.findall(line)
        if not numbers: continue
        desc = line
        for n in numbers: desc = desc.replace(n, "")
        desc = _DOT_CODE.sub("", desc)
        desc = _ROMAN.sub("", desc)
        desc = re.sub(r"\s{2,}", " ", desc).strip()
        desc = re.sub(r"\s*\(-\)\s*$", " (-)", desc).strip()
        if not desc or len(desc) < 2: continue
        onceki = _parse_number(numbers[-2]) if len(numbers) >= 2 else None
        cari   = _parse_number(numbers[-1])
        rows.append((desc, onceki, cari))
    return rows

def _build_items(raw_rows, identity, year, period, read_type):
    return [_make_item(d, identity, year, period, read_type, o, c) for d, o, c in raw_rows]


# =============================================================================
# FOOTNOTES
# =============================================================================

def _read_dipnots(text: str) -> list:
    idx = text.find("DİPNOT")
    if idx == -1: return []
    return [m.group(1).strip()
            for m in re.finditer(r"^\*\s+(.+)", text[idx:], re.M)
            if m.group(1).strip() != "*"]

def _read_dipnots_year(text: str) -> list:
    idx = text.lower().find("dipnot")
    if idx == -1: return []
    notes = []
    for line in text[idx:].split("\n")[1:]:
        s = line.strip()
        if re.match(r"^[1-4]\b", s): break
        if s: notes.append(s)
    return notes

def _dipnot_val(notes: list, keyword: str) -> Optional[float]:
    for note in notes:
        if keyword.lower() in note.lower():
            m = _NUM_RE.search(note)
            if m: return _parse_number(m.group(1))
    return None


# =============================================================================
# CODE INJECTION (691 / 590 / 591)
# =============================================================================

def _inject_code(items, identity, year, period, read_type,
                 code, value: Optional[float]) -> list:
    if value is None: return items
    defn = _DEFN_BY_CODE.get(str(code))
    for it in items:
        if str(it.get("Code")) == str(code):
            it["Value"] = value; return items
    items.append({
        "Code": code, "IdentityNumber": identity,
        "Year": year, "Period": period, "ReadType": read_type,
        "Name": defn.get("Name") if defn else None,
        "PreviousPeriodValue": None, "Value": value,
        "SearchingDescription": None,
    })
    return items

def _apply_income_rule(items, donem, identity, year, read_type):
    if donem != "4": return items
    val692 = next((it["Value"] for it in items if str(it.get("Code")) == "692"), None)
    if val692 is None: return items
    if val692 > 0: return _inject_code(items, identity, year, donem, read_type, 590,  val692)
    if val692 < 0: return _inject_code(items, identity, year, donem, read_type, 591, abs(val692))
    return items


# =============================================================================
# PARSERS
# =============================================================================

def _parse_1010(text: str) -> dict:
    year = _extract_year(text); identity = _extract_vkn(text)
    period = "4"; rt = 2
    ekler   = next((text.find(m) for m in ("E K L E R","EKLER") if text.find(m)!=-1), -1)
    aktif_s = text.find("AKTİF", ekler)          if ekler!=-1  else text.find("AKTİF")
    aktif_e = text.find("AKTİF TOPLAMI", aktif_s) if aktif_s!=-1 else -1
    pasif_s = text.find("PASİF", aktif_e)         if aktif_e!=-1 else text.find("PASİF")
    dipnot  = text.find("DİPNOT")
    gelir_s = text.find("GELİR TABLOSU", dipnot)  if dipnot!=-1  else text.find("GELİR TABLOSU")
    aktif = _build_items(_parse_raw_block(text[aktif_s:] if aktif_s!=-1 else "", ["AKTİF"], "AKTİF TOPLAMI"), identity, year, period, rt)
    pasif = _build_items(_parse_raw_block(text[pasif_s:] if pasif_s!=-1 else "", ["PASİF"], "PASİF TOPLAMI"), identity, year, period, rt)
    gelir = _build_items(_parse_raw_block(text[gelir_s:] if gelir_s!=-1 else "", ["GELİR TABLOSU"], "Dönem Net Karı veya Zararı"), identity, year, period, rt)
    pasif   = _inject_code(pasif, identity, year, period, rt, 691, _extract_scalar(text, "Hesaplanan Kurumlar Vergisi"))
    dipnots = _read_dipnots(text)
    return {
        "beyanname_turu": "1010", "identity_number": identity,
        "year": year, "period": period, "read_type": rt,
        "vergi_bildirimi": {
            "kurumlar_vergisi_matrahi":    _extract_scalar(text, "Kurumlar Vergisi Matrahı"),
            "hesaplanan_kurumlar_vergisi": _extract_scalar(text, "Hesaplanan Kurumlar Vergisi"),
            "odenen_gecici_vergi":         _extract_scalar(text, "Ödenen Geçici Vergi"),
            "odenmesi_gereken_kv":         _extract_scalar(text, "Ödenmesi Gereken Kurumlar Vergisi"),
            "kkeg_toplami":                _extract_scalar(text, "Kanunen Kabul Edilmeyen Giderler"),
            "damga_vergisi":               _extract_scalar(text, "Damga Vergisi"),
        },
        "dipnotlar": {
            "satirlar":            dipnots,
            "finansman_giderleri": _dipnot_val(dipnots, "FİNANSMAN GİDERLERİ"),
            "karsilik_giderleri":  _dipnot_val(dipnots, "KARŞILIK GİDERLERİ"),
        },
        "items": aktif + pasif + gelir,
    }


def _parse_1032(text: str) -> dict:
    year = _extract_year(text); donem = _extract_donem(text)
    identity = _extract_vkn(text); rt = 1
    gelir = _build_items(_parse_raw_block(text, ["TEK DÜZEN HESAP PLANINA UYGUN GELİR TABLOSU","GELİR TABLOSU"], "Dönem Net Karı veya Zararı"), identity, year, donem, rt)
    aktif = _build_items(_parse_raw_block(text, ["AKTİF"], "AKTİF TOPLAMI"), identity, year, donem, rt)
    pasif = _build_items(_parse_raw_block(text, ["PASİF"], "PASİF TOPLAMI"), identity, year, donem, rt)
    pasif = _inject_code(pasif, identity, year, donem, rt, 691, _extract_scalar(text, "Hesaplanan Geçici Vergi"))
    pasif = _apply_income_rule(pasif, donem, identity, year, rt)
    return {
        "beyanname_turu": "1032", "identity_number": identity,
        "year": year, "period": donem, "read_type": rt,
        "vergi_bildirimi": {
            "gecici_vergi_matrahi":         _extract_scalar(text, "Geçici Vergi Matrahı"),
            "hesaplanan_gecici_vergi":       _extract_scalar(text, "Hesaplanan Geçici Vergi"),
            "odenmesi_gereken_gecici_vergi": _extract_scalar(text, "Ödenmesi Gereken Geçici Vergi"),
            "kkeg":                          _extract_scalar(text, "Kanunen Kabul Edilmeyen Gider"),
            "damga_vergisi":                 _extract_scalar(text, "Damga Vergisi"),
        },
        "items": aktif + pasif + gelir,
    }


def _parse_1001a(text: str) -> dict:
    year = _extract_year(text); identity = _extract_vkn(text)
    period = "4"; rt = 2
    aktif = _build_items(_parse_raw_block(text, ["AKTİF","Aktif"], "AKTİF TOPLAMI"), identity, year, period, rt)
    pasif = _build_items(_parse_raw_block(text, ["PASİF","Pasif"], "PASİF TOPLAMI"), identity, year, period, rt)
    gelir = _build_items(_parse_raw_block(text, ["AYRINTILI GELİR TABLOSU"], "Dönem Net Karı veya Zararı"), identity, year, period, rt)
    return {
        "beyanname_turu": "1001A", "identity_number": identity,
        "year": year, "period": period, "read_type": rt,
        "vergi_bildirimi": {
            "vergiye_tabi_gelir_matrah":       _extract_scalar(text, "Vergiye Tabi Gelir (Matrah)"),
            "hesaplanan_gelir_vergisi":         _extract_scalar(text, "Hesaplanan Gelir Vergisi"),
            "mahsup_edilecek_vergiler_toplami": _extract_scalar(text, "Mahsup Edilecek Vergiler Toplamı"),
            "odenmesi_gereken_gelir_vergisi":   _extract_scalar(text, "Ödenmesi Gereken Gelir Vergisi"),
            "odenmesi_gereken_damga_vergisi":   _extract_scalar(text, "Ödenmesi Gereken Damga Vergisi"),
        },
        "dipnotlar": _read_dipnots_year(text),
        "items": aktif + pasif + gelir,
    }


# =============================================================================
# PUBLIC SERVICE CLASS
# =============================================================================

class BeyannameParser:
    """Parses GIB tax declaration PDFs (1010 / 1032 / 1001A)."""

    def __init__(self):
        pass

    def parse_pdf(self, pdf_bytes: bytes) -> dict:
        """Parse PDF bytes, detect type, return structured result."""
        raw = _read_pdf(pdf_bytes)
        btype = _detect_type(raw)
        if not btype:
            raise ValueError("Beyanname türü tespit edilemedi (1010/1032/1001A).")
        text = _trim_to_type(raw, btype)

        if   btype == "1010":  return _parse_1010(text)
        elif btype == "1032":  return _parse_1032(text)
        else:                  return _parse_1001a(text)

    @classmethod
    def get_definitions(cls) -> list:
        """Return all financial item definitions."""
        return FINANCIAL_ITEM_DEFINITIONS

    @classmethod
    def get_definitions_tree(cls) -> list:
        """Return definitions as hierarchical tree."""
        node_map: dict = {}
        for r in FINANCIAL_ITEM_DEFINITIONS:
            node = dict(r)
            node["children"] = []
            node_map[str(r["Code"])] = node

        roots = []
        for r in FINANCIAL_ITEM_DEFINITIONS:
            code        = str(r["Code"])
            parent_code = str(r["ParentCode"]) if r.get("ParentCode") is not None else None
            node        = node_map[code]
            if parent_code and parent_code in node_map:
                node_map[parent_code]["children"].append(node)
            else:
                roots.append(node)

        def sort_children(node):
            node["children"].sort(key=lambda x: (x.get("SequenceNumber") or 0))
            for child in node["children"]:
                sort_children(child)

        roots.sort(key=lambda x: (x.get("SequenceNumber") or 0))
        for root in roots:
            sort_children(root)

        return roots
