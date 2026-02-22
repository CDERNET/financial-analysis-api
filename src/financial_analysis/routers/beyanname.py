"""API endpoints for beyanname (tax declaration) processing."""

import logging

from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

from ..services import BeyannameParser

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Beyanname"])

# Initialize service
beyanname_parser = BeyannameParser()


@router.post(
    "/pdf",
    summary="Beyanname PDF parse et",
    description="GIB vergi beyannamesi PDF'ini (1010/1032/1001A) parse eder ve yapılandırılmış JSON döner"
)
async def parse_beyanname_pdf(
    file: UploadFile = File(..., description="GIB PDF dosyası (1010 / 1032 / 1001A)")
):
    """Parse uploaded GIB tax declaration PDF."""
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(400, "Sadece PDF dosyaları kabul edilir.")

    pdf_bytes = await file.read()
    try:
        raw = beyanname_parser.parse_pdf(pdf_bytes)
    except ValueError as e:
        raise HTTPException(422, str(e))
    except Exception as e:
        logger.error(f"Beyanname PDF parsing error: {e}")
        raise HTTPException(500, f"Beyanname parse işlemi başarısız: {e}")

    return JSONResponse(content=raw)


@router.post(
    "/excel",
    summary="Beyanname Excel parse et",
    description="GIB vergi beyannamesi Excel dosyasını parse eder (henüz implement edilmedi)"
)
async def parse_beyanname_excel(
    file: UploadFile = File(..., description="GIB Excel dosyası")
):
    """Parse uploaded GIB tax declaration Excel file (not yet implemented)."""
    raise HTTPException(501, "Beyanname Excel parse henüz implement edilmedi.")


@router.get(
    "/definitions",
    summary="Finansal kalem tanımları listesi",
    description="JSON dosyasından yüklenen tüm finansal kalem tanımlarını döner (336 adet)"
)
async def get_definitions():
    """Return all financial item definitions."""
    return JSONResponse(content=BeyannameParser.get_definitions())


@router.get(
    "/definitions/tree",
    summary="Finansal kalem tanımları hiyerarşik ağaç",
    description="Tüm tanımları ParentCode → Code ilişkisiyle nested tree olarak döner"
)
async def get_definitions_tree():
    """Return definitions as hierarchical tree."""
    return JSONResponse(content=BeyannameParser.get_definitions_tree())
