# Financial Analysis

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A professional FastAPI application for extracting trial balance data from PDF and Excel files, with OCR capabilities and hierarchical account detection.

## 🎯 Features

- **Multi-format Support**: Process Excel (.xlsx, .xls), CSV, and PDF files
- **OCR Processing**: Extract data from PDF documents using PyMuPDF and Tesseract
- **Hierarchical Detection**: Build parent-child account relationships automatically
- **Stateless API**: Returns extracted data directly as API response
- **RESTful API**: FastAPI with automatic Swagger documentation
- **Turkish Language Support**: Handle Turkish characters and number formats
- **Docker Support**: Containerized deployment with Docker Compose
- **Type Safety**: Full type hints with Pydantic models
- **Comprehensive Testing**: Test suite with pytest

## 🏗️ Project Structure

```
financial_analysis/
├── src/
│   └── financial_analysis/
│       ├── __init__.py              # Package initialization
│       ├── main.py                  # FastAPI application
│       ├── config/
│       │   ├── __init__.py
│       │   └── settings.py          # Configuration management
│       ├── models/
│       │   ├── __init__.py
│       │   └── schemas.py           # Pydantic models
│       ├── services/
│       │   ├── __init__.py
│       │   ├── excel_processor.py   # Excel file processing
│       │   └── pdf_processor.py     # PDF processing with OCR
│       ├── routers/
│       │   ├── __init__.py
│       │   └── api.py               # API endpoints
│       └── utils/
│           ├── __init__.py
│           ├── constants.py         # Column mappings and constants
│           ├── text_processing.py   # Text cleaning utilities
│           └── validators.py        # Input validation
├── tests/                           # Test suite
│   ├── __init__.py
│   ├── conftest.py                  # Test configuration
│   └── test_text_processing.py
├── requirements.txt                 # Production dependencies
├── pyproject.toml                   # Project configuration
├── README.md                        # This file
├── Dockerfile                       # Docker container
└── docker-compose.yml              # Multi-service deployment
```

## 🚀 Quick Start

### Prerequisites

- Python 3.10 or higher
- Docker (for containerized deployment - optional)
- Tesseract OCR (for PDF processing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/cdemir5/scsoft-TrialBalanceExtractor.git
   cd scsoft-TrialBalanceExtractor
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\\Scripts\\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment:**
   Create a `.env` file:
   ```env
   API_HOST=0.0.0.0
   API_PORT=8000
   LOG_LEVEL=INFO
   ```

5. **Run the application:**
   ```bash
   python -m financial_analysis.main
   ```

   Or use the console script:
   ```bash
   financial-analysis
   ```

### Docker Deployment

1. **Build and run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Access the API:**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## 📚 API Usage

### Process Excel File

```bash
curl -X POST "http://localhost:8000/api/v1/excel" \
  -F "file=@trial_balance.xlsx" \
  -F "headers=HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK" \
  -F "separator=." \
  -F "account_number=12345" \
  -F "period_id=202403"
```

### Process PDF File

```bash
curl -X POST "http://localhost:8000/api/v1/pdf" \
  -F "file=@trial_balance.pdf" \
  -F "headers=HESAP KODU,AÇIKLAMA,BORÇ,ALACAK,BAK. BORÇ,BAK. ALACAK" \
  -F "separator=." \
  -F "account_number=12345" \
  -F "period_id=202403"
```

## 🔧 Configuration

The application supports configuration through environment variables or `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_HOST` | `0.0.0.0` | API host address |
| `API_PORT` | `8000` | API port number |
| `LOG_LEVEL` | `INFO` | Logging level |
| `MAX_FILE_SIZE` | `52428800` | Max file size (50MB) |
| `TESSERACT_LANG` | `tur` | Tesseract OCR language |
| `PDF_DPI` | `300` | PDF rendering DPI |

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=financial_analysis

# Run specific test file
pytest tests/test_text_processing.py
```

## 📊 Column Mapping

The application automatically maps various column names to standard formats:

| Standard | Synonyms |
|----------|----------|
| AccountCode | "Hesap Kodu", "Kod", "T.D. Hesap No", "MainAccount", "KODLAR", "Hesap" |
| AccountName | "Hesap Adı", "Adı", "HESAP İSMİ", "hesabı", "Açıklama", "Description" |
| Debit | "Borç", "Toplam Borç", "Borç Toplamı", "TL BORÇ", "Borc" |
| Credit | "Alacak", "Toplam Alac.", "Alacak Toplamı", "TL ALACAK" |
| DebitBalance | "Borç Bakiye", "Bakiye Borç", "TL BORÇ BAKİYE", "Bak. Borç" |
| CreditBalance | "Alacak Bakiye", "Bakiye Alac.", "TL ALACAK BAKİYE", "Bak. Alacak" |

## 🐛 Error Handling

The application provides comprehensive error handling:

- **File Validation**: Size limits, format validation
- **Data Processing**: Invalid data handling, missing columns
- **OCR Errors**: PDF reading issues, text extraction problems

All errors are logged and return appropriate HTTP status codes with detailed messages.

## 🔍 Logging

Logging is configured with multiple levels:

- **DEBUG**: Detailed processing information
- **INFO**: General application flow
- **WARNING**: Potential issues
- **ERROR**: Error conditions
- **CRITICAL**: Critical failures

Logs are written to both console and file (`financial_analysis.log`).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Install development dependencies
pip install -r requirements.txt[dev]

# Install pre-commit hooks
pre-commit install

# Run code formatting
black src/ tests/

# Run linting
flake8 src/ tests/

# Run type checking
mypy src/
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

1. Check the [documentation](https://github.com/cdemir5/scsoft-TrialBalanceExtractor/wiki)
2. Search [existing issues](https://github.com/cdemir5/scsoft-TrialBalanceExtractor/issues)
3. Create a [new issue](https://github.com/cdemir5/scsoft-TrialBalanceExtractor/issues/new)

## 📈 Roadmap

- [ ] Additional file format support (ODS, CSV variants)
- [ ] Machine learning for better column detection
- [ ] REST API versioning
- [ ] Batch processing capabilities
- [ ] Web UI for file uploads
- [ ] Export functionality (JSON, XML)
- [ ] Performance optimizations for large files
- [ ] Multi-language support

## 🙏 Acknowledgments

- [FastAPI](https://fastapi.tiangolo.com/) - Modern web framework
- [PyMuPDF](https://github.com/pymupdf/PyMuPDF) - PDF processing
- [Pandas](https://pandas.pydata.org/) - Data manipulation
- [Pydantic](https://pydantic-docs.helpmanual.io/) - Data validation
- [Tesseract](https://github.com/tesseract-ocr/tesseract) - OCR engine

---

**Made with ❤️ by the Financial Analysis Team**
