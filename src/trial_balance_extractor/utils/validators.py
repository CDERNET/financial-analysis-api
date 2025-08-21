"""Validation utilities for file processing."""

import os
from typing import List
from fastapi import HTTPException


def validate_file_extension(filename: str, allowed_extensions: List[str]) -> None:
    """
    Validate if file has an allowed extension.
    
    Args:
        filename: Name of the file to validate
        allowed_extensions: List of allowed file extensions
        
    Raises:
        HTTPException: If file extension is not allowed
    """
    if not filename:
        raise HTTPException(status_code=400, detail="Filename cannot be empty")
    
    file_ext = os.path.splitext(filename.lower())[1]
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"File extension {file_ext} not allowed. Allowed: {allowed_extensions}"
        )


def validate_file_size(file_size: int, max_size: int) -> None:
    """
    Validate if file size is within allowed limits.
    
    Args:
        file_size: Size of the file in bytes
        max_size: Maximum allowed file size in bytes
        
    Raises:
        HTTPException: If file size exceeds limit
    """
    if file_size > max_size:
        max_size_mb = max_size / (1024 * 1024)
        file_size_mb = file_size / (1024 * 1024)
        raise HTTPException(
            status_code=413,
            detail=f"File size {file_size_mb:.1f}MB exceeds limit of {max_size_mb:.1f}MB"
        )


def validate_account_parameters(account_number: int, period_id: int) -> None:
    """
    Validate account number and period ID parameters.
    
    Args:
        account_number: Account number to validate
        period_id: Period ID to validate
        
    Raises:
        HTTPException: If parameters are invalid
    """
    if account_number <= 0:
        raise HTTPException(
            status_code=400,
            detail="Account number must be positive"
        )
    
    if period_id <= 0:
        raise HTTPException(
            status_code=400, 
            detail="Period ID must be positive"
        )
