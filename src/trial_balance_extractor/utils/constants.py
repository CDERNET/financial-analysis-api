"""Constants for column mapping and keywords."""

# Supported file formats
SUPPORTED_FORMATS = {
    'excel': ['.xlsx', '.xls', '.xlsm'],
    'csv': ['.csv'],
    'pdf': ['.pdf']
}

# Default processing parameters
DEFAULT_SEPARATOR = "."
DEFAULT_TOLERANCE = 5  # Pixel tolerance for PDF processing
DEFAULT_DPI = 300
