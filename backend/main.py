import os
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.logger import get_logger
from core.routes import users, feedback, ai, vital, auth
from contextlib import asynccontextmanager
from core.dependencies import get_db_service, get_ai_service

logger = get_logger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_service, ai_service
    
    logger.info("🚀 [APP] Starting the application")

    try:
        logger.info("🔄 [APP] Initializing services")
        db_service = get_db_service()
        ai_service = get_ai_service()
        logger.info("✅ [APP] All services initialized successfully")
    except Exception as e:
        logger.error(f"❌ [APP] Error initializing services: {e}")
        raise

    yield

    logger.info("🔄 [APP] Shutting down the application...")
    try:
        db_service.close_connection()
        logger.info("✅ [APP] Firebase connection closed successfully")
    except Exception as e:
        logger.error(f"❌ [APP] Error during shutdown: {e}")

app = FastAPI(
    title='Panic Attack Detection API',
    version='1.0.0',
    description='API para detecção de ataques de panico',
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# Incluir routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(feedback.router, prefix="/feedback", tags=["Feedback"])
app.include_router(ai.router, prefix="/ai", tags=["AI"])
app.include_router(vital.router, prefix="/vital-data", tags=["Vital Data"])

@app.get("/", tags=["Health"])
async def root() -> dict:
    """Health check endpoint for the API.

    Returns a JSON object with a single key-value pair, where the key is "status" and the value is "running".
    """
    logger.info("🔍 [HEALTH] Health check endpoint called")
    return {"status": "running"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))  # CORREÇÃO: Porta 8080
    logger.info(f"🚀 [APP] Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)