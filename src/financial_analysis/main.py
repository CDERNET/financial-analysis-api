"""Main FastAPI application for Financial Analysis."""

import logging
import sys
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from .config import get_settings
from .routers import mizan_router, beyanname_router


# Configure logging
def setup_logging():
    """Set up application logging configuration."""
    settings = get_settings()
    
    logging.basicConfig(
        level= logging.INFO,#getattr(logging, settings.log_level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",#settings.log_format,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler("financial_analysis.log", mode="a", encoding="utf-8")
        ]
    )
    
    # Set specific loggers
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
     

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan context manager."""
    logger = logging.getLogger(__name__)
    logger.info("Starting Financial Analysis API...")

    from .db import init_db_pool, close_db_pool, get_db_pool, seed_item_definitions
    await init_db_pool()

    pool = get_db_pool()
    if pool:
        try:
            await seed_item_definitions(pool)
        except Exception as e:
            logger.error(f"Failed to seed item definitions: {e}")

    yield

    await close_db_pool()
    logger.info("Shutting down Financial Analysis API...")


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
    app.include_router(mizan_router, prefix="/api/v1/mizan")
    app.include_router(beyanname_router, prefix="/api/v1/beyanname")
    
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
        "message": "Welcome to Financial Analysis API",
        "title": settings.api_title,
        "version": settings.api_version,
        "description": settings.api_description,
        "docs_url": "/docs",
        "redoc_url": "/redoc"
    }


# Health check endpoint
@app.get("/health", summary="Health check endpoint", description="Application health status")
async def health_check():
    """Health check endpoint for monitoring."""
    from .db import get_db_pool

    db_status = "not_configured"
    pool = get_db_pool()
    if pool:
        try:
            async with pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            db_status = "connected"
        except Exception:
            db_status = "error"

    return {
        "status": "healthy",
        "message": "Financial Analysis API is running",
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }


def main():
    """Main entry point for running the application."""
    settings = get_settings()
    
    uvicorn.run(
        "financial_analysis.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=True,  # Set to False in production
        log_level=settings.log_level.lower()
    )


if __name__ == "__main__":
    main()
