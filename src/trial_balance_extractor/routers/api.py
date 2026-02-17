"""API endpoints for trial balance processing."""

import logging
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, File, Form, Query, UploadFile, HTTPException
from fastapi.responses import JSONResponse

from ..config import get_settings
from ..models.schemas import ProcessingResult, AccountTreeResponse
from ..services import ExcelProcessor, PDFProcessor, TreeBuilder, DatabaseService
from ..utils.validators import validate_file_extension, validate_file_size, validate_account_parameters


logger = logging.getLogger(__name__)
router = APIRouter()

# Initialize services
excel_processor = ExcelProcessor()
pdf_processor = PDFProcessor()
tree_builder = TreeBuilder()
db_service = DatabaseService()
settings = get_settings()


@router.post(
    "/excel",
    response_model=ProcessingResult,
    summary="Preview Excel file data without saving to database.",
    description="Upload Excel, XLS, or CSV file to extract and preview trial balance data without storing in database"
)
async def excel_file(
    file: UploadFile = File(..., description="Excel, XLS or CSV file containing trial balance data"),
    headers: str = Form(
        ..., 
        description="Column headers separated by commas",
        example="HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK"
    ),
    separator: str = Form(".", description="Account hierarchy separator", example="."),
    account_number: str = Form("", description="Customer/Account number (optional for preview)"),
    period_id: str = Form("", description="Period identifier (optional for preview)")
) -> ProcessingResult:
    """
    Preview Excel file data without saving to database.
    
    Args:
        file: Uploaded Excel/CSV file
        headers: Comma-separated column headers
        separator: Account hierarchy separator
        account_number: Customer account number (optional for preview)
        period_id: Period identifier (optional for preview)
        
    Returns:
        Processing result with extracted data (no database save)
        
    Raises:
        HTTPException: If processing fails
    """
    start_time = datetime.now()
    logger.info(f"Excel preview processing started at {start_time}")
    
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
        # Process file without saving
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
        logger.info(f"Excel preview processing completed in {elapsed_time:.2f} seconds")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Excel preview processing error: {e}")
        raise HTTPException(status_code=500, detail=f"Excel preview processing failed: {e}")


@router.post(
    "/pdf",
    response_model=ProcessingResult, 
    summary="Preview PDF file data without saving to database",
    description="Upload PDF file to extract and preview trial balance data using OCR without storing in database"
)
async def pdf_file(
    file: UploadFile = File(..., description="PDF file containing trial balance data"),
    headers: str = Form(
        ..., 
        description="Column headers separated by commas",
        example="HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK"
    ),
    separator: str = Form(".", description="Account hierarchy separator", example="."),
    account_number: str = Form("", description="Customer/Account number (optional for preview)"),
    period_id: str = Form("", description="Period identifier (optional for preview)")
) -> ProcessingResult:
    """
    Preview PDF file data without saving to database.
    
    Args:
        file: Uploaded PDF file
        headers: Comma-separated column headers
        separator: Account hierarchy separator
        account_number: Customer account number (optional for preview)
        period_id: Period identifier (optional for preview)
        
    Returns:
        Processing result with extracted data (no database save)
        
    Raises:
        HTTPException: If processing fails
    """
    start_time = datetime.now()
    logger.info(f"PDF preview processing started at {start_time}")
    
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
        
        # Process file without saving
        result = pdf_processor.process_pdf_file_no_save(
            file_content=file_content,
            headers=header_list,
            separator=separator,
            account_number=parsed_account_number,
            period_id=parsed_period_id
        )
        
        end_time = datetime.now()
        elapsed_time = (end_time - start_time).total_seconds()
        logger.info(f"PDF preview processing completed in {elapsed_time:.2f} seconds")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"PDF preview processing error: {e}")
        raise HTTPException(status_code=500, detail=f"PDF preview processing failed: {e}")


@router.get(
    "/account-tree",
    response_model=AccountTreeResponse,
    summary="Get account tree structure",
    description="Retrieve hierarchical account tree for specified account number and period"
)
def get_account_tree(
    account_number: int = Query(..., description="Customer/Account number"),
    period_id: int = Query(..., description="Period identifier"),
    root_code: Optional[str] = Query(None, description="Root account code (optional filter)")
) -> AccountTreeResponse:
    """
    Get hierarchical account tree structure.
    
    Args:
        account_number: Customer account number
        period_id: Period identifier
        root_code: Optional root account code for filtering
        
    Returns:
        Account tree response with hierarchical data
        
    Raises:
        HTTPException: If retrieval fails
    """
    try:
        # Validate parameters
        validate_account_parameters(account_number, period_id)
        
        # Get data from database
        data = db_service.get_account_tree_data(account_number, period_id, root_code)
        
        if not data:
            return AccountTreeResponse(
                data=[],
                total_count=0,
                account_number=account_number,
                period_id=period_id
            )
        
        # Build tree structure
        tree_data = tree_builder.build_tree_from_dict(data)
        
        return AccountTreeResponse(
            data=tree_data,
            total_count=len(data),
            account_number=account_number,
            period_id=period_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Account tree retrieval error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve account tree: {e}")


@router.get(
    "/health",
    summary="Health check endpoint",
    description="Check API and database health status"
)
def health_check() -> JSONResponse:
    """
    Health check endpoint.
    
    Returns:
        Health status information
    """
    try:
        # Test database connection
        db_healthy = db_service.check_connection()
        
        return JSONResponse(content={
            "status": "healthy" if db_healthy else "unhealthy",
            "api": "online",
            "database": "connected" if db_healthy else "disconnected",
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "api": "online",
                "database": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )
