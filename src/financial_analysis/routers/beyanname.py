"""API endpoints for beyanname (tax declaration) processing."""

import logging
from typing import Optional

from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, Query
from fastapi.responses import JSONResponse

from ..services import BeyannameParser
from ..db.dependencies import get_repository
from ..db.repository import FinancialStatementRepository

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
    file: UploadFile = File(..., description="GIB PDF dosyası (1010 / 1032 / 1001A)"),
    repo: Optional[FinancialStatementRepository] = Depends(get_repository),
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

    # Insert into database
    if repo and raw.get("items"):
        try:
            count = await repo.insert_beyanname_items(
                identity_number=raw.get("identity_number", ""),
                year=raw.get("year", ""),
                period=raw.get("period", ""),
                read_type=raw.get("read_type", 2),
                items=raw["items"],
            )
            raw["db_inserted"] = count
        except Exception as e:
            logger.error(f"Database insertion failed for beyanname: {e}")
            raw["db_error"] = str(e)

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
    description="Veritabanından tüm finansal kalem tanımlarını döner"
)
async def get_definitions(
    repo: Optional[FinancialStatementRepository] = Depends(get_repository),
):
    """Return all financial item definitions from database."""
    if repo:
        try:
            data = await repo.get_definitions()
            return JSONResponse(content=data)
        except Exception as e:
            logger.error(f"Failed to fetch definitions from DB: {e}")
    return JSONResponse(content=BeyannameParser.get_definitions())


@router.get(
    "/definitions/tree",
    summary="Finansal kalem tanımları hiyerarşik ağaç",
    description="Tüm tanımları ParentCode → Code ilişkisiyle nested tree olarak döner"
)
async def get_definitions_tree(
    repo: Optional[FinancialStatementRepository] = Depends(get_repository),
):
    """Return definitions as hierarchical tree from database."""
    if repo:
        try:
            data = await repo.get_definitions_tree()
            return JSONResponse(content=data)
        except Exception as e:
            logger.error(f"Failed to fetch definitions tree from DB: {e}")
    return JSONResponse(content=BeyannameParser.get_definitions_tree())


@router.get(
    "/tree",
    summary="Beyanname verilerini hiyerarşik ağaç olarak getir",
    description="Belirtilen IdentityNumber ve Period için FinancialStatement verilerini "
                "FinancialStatementItemDefinition tablosundaki ParentCode üzerinden tree olarak döner"
)
async def get_beyanname_tree(
    identity_number: str = Query(..., description="Vergi kimlik numarası", example="2100009755"),
    period: int = Query(..., description="6 haneli dönem (YYYYQT)", example=202442),
    repo: Optional[FinancialStatementRepository] = Depends(get_repository),
):
    """Return beyanname data as a parent-child tree joined with item definitions."""
    if not repo:
        raise HTTPException(
            status_code=503,
            detail="Veritabanı bağlantısı yapılandırılmamış."
        )
    try:
        tree = await repo.get_beyanname_tree(
            identity_number=identity_number,
            period=period,
        )
    except Exception as e:
        logger.error(f"Beyanname tree fetch error: {e}")
        raise HTTPException(status_code=500, detail=f"Beyanname tree getirilemedi: {e}")

    if not tree:
        raise HTTPException(
            status_code=404,
            detail=f"IdentityNumber={identity_number}, Period={period} için kayıt bulunamadı."
        )

    return JSONResponse(content=tree)
