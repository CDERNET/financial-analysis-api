"""API endpoints for mizan (trial balance) processing."""

import logging
from datetime import datetime

from fastapi import APIRouter, File, Form, UploadFile, HTTPException

from ..config import get_settings
from ..models.schemas import ProcessingResult
from ..services import ExcelProcessor, PDFProcessor
from ..utils.validators import validate_file_extension, validate_file_size, validate_account_parameters


logger = logging.getLogger(__name__)
router = APIRouter(tags=["Mizan"])

# Initialize services
excel_processor = ExcelProcessor()
pdf_processor = PDFProcessor()
settings = get_settings()


@router.post(
    "/excel",
    response_model=ProcessingResult,
    summary="Excel dosyasından mizan verisi çıkar",
    description="Excel, XLS veya CSV dosyasından mizan verisi çıkarıp response olarak döner"
)
async def excel_file(
    file: UploadFile = File(..., description="Excel, XLS or CSV file containing trial balance data"),
    headers: str = Form(
        ...,
        description="Column headers separated by commas",
        example="HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK"
    ),
    separator: str = Form(".", description="Account hierarchy separator", example="."),
    account_number: str = Form("", description="Customer/Account number (optional)"),
    period_id: str = Form("", description="Period identifier (optional)")
) -> ProcessingResult:
    """
    Process Excel file and return extracted trial balance data.

    Args:
        file: Uploaded Excel/CSV file
        headers: Comma-separated column headers
        separator: Account hierarchy separator
        account_number: Customer account number (optional)
        period_id: Period identifier (optional)

    Returns:
        Processing result with extracted data

    Raises:
        HTTPException: If processing fails
    """
    start_time = datetime.now()
    logger.info(f"Excel processing started at {start_time}")

    try:
        # Validate file
        validate_file_extension(file.filename, settings.allowed_extensions)

        file_content = await file.read()
        validate_file_size(len(file_content), settings.max_file_size)

        # Parse optional parameters
        parsed_account_number = None
        parsed_period_id = None

        if account_number and account_number.strip():
            try:
                parsed_account_number = int(account_number.strip())
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid account_number format")

        if period_id and period_id.strip():
            try:
                parsed_period_id = int(period_id.strip())
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid period_id format")

        # Validate parameters only if provided
        if parsed_account_number is not None and parsed_period_id is not None:
            validate_account_parameters(parsed_account_number, parsed_period_id)

         # Parse headers
        try:
            header_list = [h.strip() for h in headers.split(",")]
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to parse headers: {e}")

        if not header_list:
            raise HTTPException(status_code=400, detail="Headers cannot be empty")

        logger.info(f"Parsed headers: {header_list}")
        # Process file
        result = excel_processor.process_excel_file(
            file_content=file_content,
            filename=file.filename,
            headers=header_list,
            separator=separator,
            account_number=parsed_account_number,
            period_id=parsed_period_id
        )

        end_time = datetime.now()
        elapsed_time = (end_time - start_time).total_seconds()
        logger.info(f"Excel processing completed in {elapsed_time:.2f} seconds")

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Excel processing error: {e}")
        raise HTTPException(status_code=500, detail=f"Excel processing failed: {e}")


@router.post(
    "/pdf",
    response_model=ProcessingResult,
    summary="PDF dosyasından mizan verisi çıkar",
    description="PDF dosyasından OCR ile mizan verisi çıkarıp response olarak döner"
)
async def pdf_file(
    file: UploadFile = File(..., description="PDF file containing trial balance data"),
    headers: str = Form(
        ...,
        description="Column headers separated by commas",
        example="HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK"
    ),
    separator: str = Form(".", description="Account hierarchy separator", example="."),
    account_number: str = Form("", description="Customer/Account number (optional)"),
    period_id: str = Form("", description="Period identifier (optional)")
) -> ProcessingResult:
    """
    Process PDF file and return extracted trial balance data.

    Args:
        file: Uploaded PDF file
        headers: Comma-separated column headers
        separator: Account hierarchy separator
        account_number: Customer account number (optional)
        period_id: Period identifier (optional)

    Returns:
        Processing result with extracted data

    Raises:
        HTTPException: If processing fails
    """
    start_time = datetime.now()
    logger.info(f"PDF processing started at {start_time}")

    try:
        # Validate file
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are supported")

        file_content = await file.read()
        validate_file_size(len(file_content), settings.max_file_size)

        # Parse headers
        try:
            header_list = [h.strip() for h in headers.split(",")]
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Failed to parse headers: {e}")

        if not header_list:
            raise HTTPException(status_code=400, detail="Headers cannot be empty")

        # Parse optional parameters
        parsed_account_number = None
        parsed_period_id = None

        if account_number and account_number.strip():
            try:
                parsed_account_number = int(account_number.strip())
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid account_number format")

        if period_id and period_id.strip():
            try:
                parsed_period_id = int(period_id.strip())
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid period_id format")

        # Validate parameters only if provided
        if parsed_account_number is not None and parsed_period_id is not None:
            validate_account_parameters(parsed_account_number, parsed_period_id)

        # Process file
        result = pdf_processor.process_pdf_file_no_save(
            file_content=file_content,
            headers=header_list,
            separator=separator,
            account_number=parsed_account_number,
            period_id=parsed_period_id
        )

        end_time = datetime.now()
        elapsed_time = (end_time - start_time).total_seconds()
        logger.info(f"PDF processing completed in {elapsed_time:.2f} seconds")

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"PDF processing error: {e}")
        raise HTTPException(status_code=500, detail=f"PDF processing failed: {e}")
