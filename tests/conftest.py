"""Test configuration and fixtures."""

import pytest
from unittest.mock import Mock
from fastapi.testclient import TestClient

from trial_balance_extractor.main import create_app
from trial_balance_extractor.services import DatabaseService


@pytest.fixture
def app():
    """Create FastAPI test application."""
    return create_app()


@pytest.fixture
def client(app):
    """Create test client."""
    return TestClient(app)


@pytest.fixture
def mock_db_service():
    """Create mock database service."""
    mock_service = Mock(spec=DatabaseService)
    mock_service.check_connection.return_value = True
    mock_service.insert_trial_balance_items.return_value = 5
    mock_service.get_account_tree_data.return_value = []
    return mock_service


@pytest.fixture
def sample_excel_data():
    """Sample Excel data for testing."""
    return {
        'headers': ['Hesap Kodu', 'Hesap Adı', 'Borç', 'Alacak', 'Borç Bakiye', 'Alacak Bakiye'],
        'data': [
            ['100', 'KASA', '1000.00', '500.00', '500.00', '0.00'],
            ['100.01', 'TL KASA', '600.00', '200.00', '400.00', '0.00'],
            ['120', 'BANKALAR', '5000.00', '1000.00', '4000.00', '0.00'],
            ['120.01', 'ABC BANKASI', '3000.00', '500.00', '2500.00', '0.00'],
        ]
    }


@pytest.fixture
def sample_pdf_headers():
    """Sample PDF headers for testing."""
    return ['HESAP KODU', 'AÇIKLAMA', 'BORÇ', 'ALACAK', 'BAK. BORÇ', 'BAK. ALACAK']
