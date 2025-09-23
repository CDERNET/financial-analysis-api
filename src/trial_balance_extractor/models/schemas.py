"""Pydantic models and schemas for data validation."""

from decimal import Decimal
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field, validator


class TrialBalanceItem(BaseModel):
    """Model for trial balance item data."""
    
    account_code: str = Field(..., description="Account code")
    account_name: str = Field(..., description="Account name/description") 
    debit: float = Field(default=0.0, description="Debit amount")
    credit: float = Field(default=0.0, description="Credit amount")
    debit_balance: float = Field(default=0.0, description="Debit balance")
    credit_balance: float = Field(default=0.0, description="Credit balance")
    parent_account_code: Optional[str] = Field(None, description="Parent account code")
    account_number: int = Field(..., description="Customer/Account number")
    period_id: int = Field(..., description="Period identifier")
    
    @validator('debit', 'credit', 'debit_balance', 'credit_balance', pre=True)
    def parse_decimal_fields(cls, v):
        """Parse decimal/float fields from various formats."""
        if isinstance(v, (int, float, Decimal)):
            return float(v)
        if isinstance(v, str):
            try:
                # Handle Turkish decimal format (. as thousands, , as decimal)
                v = v.replace('.', '').replace(',', '.')
                return float(v)
            except ValueError:
                return 0.0
        return 0.0


class TreeNode(BaseModel):
    """Model for hierarchical tree node structure."""
    
    account_code: str
    account_name: str
    debit: float = 0.0
    credit: float = 0.0
    debit_balance: float = 0.0 
    credit_balance: float = 0.0
    parent_account_code: Optional[str] = None
    children: List['TreeNode'] = Field(default_factory=list)
    
    class Config:
        # Enable self-referencing models
        arbitrary_types_allowed = True


# Update forward references
TreeNode.model_rebuild()


class ProcessingResult(BaseModel):
    """Model for file processing results."""
    
    success: bool = Field(..., description="Processing success status")
    message: str = Field(..., description="Result message")
    inserted_count: int = Field(default=0, description="Number of records inserted")
    account_number: Optional[int] = Field(None, description="Account number processed")
    period_id: Optional[int] = Field(None, description="Period ID processed")
    errors: List[str] = Field(default_factory=list, description="Processing errors")
    data: Optional[List[Dict[str, Any]]] = Field(None, description="Processed data (when not saved to database)")


class FileUploadRequest(BaseModel):
    """Model for file upload request parameters."""
    
    account_code_column: str = Field(..., description="Account code column name")
    separator: str = Field(default=".", description="Account hierarchy separator")
    account_number: int = Field(..., description="Customer/Account number")
    period_id: int = Field(..., description="Period identifier")


class AccountTreeResponse(BaseModel):
    """Model for account tree API response."""
    
    data: List[TreeNode] = Field(..., description="Account tree data")
    total_count: int = Field(..., description="Total number of nodes")
    account_number: int = Field(..., description="Account number")
    period_id: int = Field(..., description="Period ID")


class PDFHeaders(BaseModel):
    """Model for PDF header configuration."""
    
    headers: List[str] = Field(..., description="PDF column headers")
    
    @validator('headers')
    def validate_headers(cls, v):
        """Validate headers list is not empty."""
        if not v or len(v) == 0:
            raise ValueError("Headers list cannot be empty")
        return v
