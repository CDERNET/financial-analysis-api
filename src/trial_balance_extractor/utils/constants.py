"""Constants for column mapping and keywords."""

from typing import Dict, List

# Column mapping for different Excel/PDF formats to standardized names
COLUMN_MAP: Dict[str, List[str]] = {
    "AccountCode": [
        "Hesap Kodu", "Kod", "T.D. Hesap No", "MainAccount", 
        "KODLAR", "Hesap", "Account Code", "Code"
    ],
    "AccountName": [
        "Hesap Adı", "Adı", "HESAP İSMİ", "hesabı", "Acıklama", 
        "Açıklama", "Account Name", "Description", "Name","Açiklama","AÇIKLAMA"
    ],
    "Debit": [
        "Borç", "Toplam Borç", "Borç Toplamı", "TL BORÇ", "Borc", 
        "Debit", "BORC", "BORÇ"
    ],
    "Credit": [
        "Alacak", "Toplam Alac.", "Alacak Toplamı", "TL ALACAK",
        "Credit", "ALACAK", "ALAC"
    ],
    "DebitBalance": [
        "Borç Bakiye", "Bakiye Borç", "TL BORÇ BAKİYE", "Borcbakıye", 
        "Bak. Borç", "BAK. BORÇ", "Debit Balance", "BORÇ BAKİYE"
    ],
    "CreditBalance": [
        "Alacak Bakiye", "Bakiye Alac.", "TL ALACAK BAKİYE", "Alacakbakıye", 
        "Bak. Alacak", "BAK. ALACAK", "Credit Balance", "ALACAK BAKİYE","Bakiye Alacak"
    ]
}

# Extract all keywords for header detection
KEYWORDS: List[str] = [keyword for column_list in COLUMN_MAP.values() for keyword in column_list]

# Supported file formats
SUPPORTED_FORMATS = {
    'excel': ['.xlsx', '.xls'],
    'csv': ['.csv'],
    'pdf': ['.pdf']
}

# Default processing parameters
DEFAULT_SEPARATOR = "."
DEFAULT_TOLERANCE = 5  # Pixel tolerance for PDF processing
DEFAULT_DPI = 300
