"""Tests for text processing utilities."""

import pytest
from trial_balance_extractor.utils.text_processing import (
    clean_text,
    normalize_text,
    find_parent_code,
    parse_numeric_value
)


class TestTextProcessing:
    """Test cases for text processing functions."""
    
    def test_clean_text(self):
        """Test text cleaning functionality."""
        # Normal text
        assert clean_text("Hesap Kodu") == "HESAPKODU"
        
        # Text with extra spaces
        assert clean_text("  Hesap   Kodu  ") == "HESAPKODU"
        
        # Text with special characters
        assert clean_text("Hesap-Kodu_123") == "HESAP-KODU_123"
        
        # Non-string input
        assert clean_text(123) == "123"
        assert clean_text(None) == "NONE"
    
    def test_normalize_text(self):
        """Test text normalization functionality."""
        # Turkish characters
        assert normalize_text("çğıöşüÇĞIÖŞÜ") == "cgiousCGIOUS"
        
        # Mixed case
        assert normalize_text("Hesap KODU") == "hesap kodu"
        
        # With spaces
        assert normalize_text("  Hesap Kodu  ") == "hesap kodu"
        
        # Non-string input
        assert normalize_text(123) == "123"
    
    def test_find_parent_code(self):
        """Test parent code finding functionality."""
        all_codes = {"100", "100.01", "100.01.001", "120", "120.01"}
        
        # Normal hierarchy
        assert find_parent_code("100.01.001", all_codes, ".") == "100.01"
        assert find_parent_code("100.01", all_codes, ".") == "100"
        assert find_parent_code("120.01", all_codes, ".") == "120"
        
        # Root code
        assert find_parent_code("100", all_codes, ".") is None
        
        # Non-existent code
        assert find_parent_code("999", all_codes, ".") is None
        
        # Different separator
        all_codes_dash = {"100", "100-01", "100-01-001"}
        assert find_parent_code("100-01-001", all_codes_dash, "-") == "100-01"
        
        # Fallback to character truncation
        all_codes_no_sep = {"1000", "10001", "100011"}
        assert find_parent_code("100011", all_codes_no_sep, ".") == "10001"
    
    def test_parse_numeric_value(self):
        """Test numeric value parsing."""
        # Normal numbers
        assert parse_numeric_value("123.45") == 123.45
        assert parse_numeric_value("1000") == 1000.0
        
        # Turkish format (. as thousand separator, , as decimal)
        assert parse_numeric_value("1.000,50") == 1000.50
        assert parse_numeric_value("10.500,75") == 10500.75
        
        # Already numeric
        assert parse_numeric_value(123.45) == 123.45
        assert parse_numeric_value(100) == 100.0
        
        # Invalid values
        assert parse_numeric_value("invalid") == 0.0
        assert parse_numeric_value("") == 0.0
        assert parse_numeric_value(None) == 0.0
        
        # Edge cases
        assert parse_numeric_value("0") == 0.0
        assert parse_numeric_value("0,00") == 0.0
        assert parse_numeric_value("1.000.000,00") == 1000000.0


if __name__ == "__main__":
    pytest.main([__file__])
