"""Text processing utilities for data cleaning and normalization."""

import re
import unicodedata
from typing import Dict, Optional, Set


def clean_text(text: str) -> str:
    """
    Clean and normalize text by removing extra whitespace and converting to uppercase.
    
    Args:
        text: Input text to clean
        
    Returns:
        Cleaned and normalized text
    """
    if not isinstance(text, str):
        text = str(text)
    
    text = unicodedata.normalize("NFKD", text)
    text = re.sub(r'\s+', '', text)
    return text.upper()


def normalize_text(text: str) -> str:
    """
    Normalize text for comparison by handling Turkish characters and formatting.
    
    Args:
        text: Input text to normalize
        
    Returns:
        Normalized text
    """
    if not isinstance(text, str):
        text = str(text)
    
    # Normalize Unicode characters
    text = unicodedata.normalize('NFKD', text)
    
    # Convert to lowercase and strip whitespace
    text = text.lower().strip()
    
    # Handle Turkish character mappings
    char_map = {
        'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ş': 's', 'ü': 'u', 'ö': 'o',
        'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ş': 's', 'Ü': 'u', 'Ö': 'o'
    }
    
    for turkish_char, english_char in char_map.items():
        text = text.replace(turkish_char, english_char)
    
    return text


def find_parent_code(code: str, all_codes: Set[str], separator: str) -> Optional[str]:
    """
    Find parent account code by removing the last part of hierarchical code.
    
    Args:
        code: Account code to find parent for
        all_codes: Set of all available account codes
        separator: Hierarchy separator (e.g., '.')
        
    Returns:
        Parent account code if found, None otherwise
    """
    if not isinstance(code, str) or not code:
        return None
    
    # Try separator-based hierarchy first
    if separator in code:
        parts = code.split(separator)
        while len(parts) > 1:
            parts = parts[:-1]
            candidate = separator.join(parts)
            if candidate in all_codes:
                return candidate
    
    # Fallback: try truncating character by character
    for i in range(len(code) - 1, 0, -1):
        candidate = code[:i]
        if candidate in all_codes:
            return candidate
    
    return None


def parse_numeric_value(value: str) -> float:
    """
    Parse numeric value from string, handling Turkish number format.
    
    Args:
        value: String representation of number
        
    Returns:
        Parsed float value, 0.0 if parsing fails
    """
    if not isinstance(value, str):
        try:
            return float(value)
        except (ValueError, TypeError):
            return 0.0
    
    try:
        # Handle Turkish format: . as thousands separator, , as decimal
        value = value.replace('.', '').replace(',', '.')
        return float(value)
    except (ValueError, TypeError):
        return 0.0
