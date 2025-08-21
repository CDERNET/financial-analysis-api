"""Main FastAPI application for Trial Balance Extractor."""

import logging
import sys
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from .config import get_settings
from .routers import router
from .services import DatabaseService


# Configure logging
def setup_logging():
    """Set up application logging configuration."""
    settings = get_settings()
    
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format=settings.log_format,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler("trial_balance_extractor.log", mode="a", encoding="utf-8")
        ]
    )
    
    # Set specific loggers
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan context manager.
    
    Args:
        app: FastAPI application instance
    """
    # Startup
    logger = logging.getLogger(__name__)
    logger.info("Starting Trial Balance Extractor API...")
    
    # Test database connection
    db_service = DatabaseService()
    if db_service.check_connection():
        logger.info("Database connection successful")
    else:
        logger.warning("Database connection failed - some features may not work")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Trial Balance Extractor API...")


def create_app() -> FastAPI:
    """
    Create and configure FastAPI application.
    
    Returns:
        Configured FastAPI application
    """
    # Setup logging first
    setup_logging()
    logger = logging.getLogger(__name__)
    
    settings = get_settings()
    
    # Create FastAPI app
    app = FastAPI(
        title=settings.api_title,
        description=settings.api_description,
        version=settings.api_version,
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json"
    )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Configure appropriately for production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include routers
    app.include_router(router, prefix="/api/v1")
    
    logger.info(f"FastAPI application created: {settings.api_title} v{settings.api_version}")
    return app


# Create application instance
app = create_app()


# Root endpoint
@app.get("/", summary="Root endpoint", description="Welcome message and API information")
def root():
    """
    Root endpoint with API information.
    
    Returns:
        Welcome message and API details
    """
    settings = get_settings()
    return {
        "message": "Welcome to Trial Balance Extractor API",
        "title": settings.api_title,
        "version": settings.api_version,
        "description": settings.api_description,
        "docs_url": "/docs",
        "redoc_url": "/redoc"
    }


# Health check endpoint
@app.get("/health", summary="Health check endpoint", description="Application health status")
def health_check():
    """
    Health check endpoint for monitoring.
    
    Returns:
        Health status information
    """
    return {
        "status": "healthy",
        "message": "Trial Balance Extractor API is running",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }


def main():
    """Main entry point for running the application."""
    settings = get_settings()
    
    uvicorn.run(
        "trial_balance_extractor.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=True,  # Set to False in production
        log_level=settings.log_level.lower()
    )


if __name__ == "__main__":
    main()
