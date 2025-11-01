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
    
    logger.info("Starting the application")

    try:
        logger.info("Initializing services")
        db_service = get_db_service()
        ai_service = get_ai_service()
        logger.info("All services initialized")
    except Exception as e:
        logger.error(f"Error initializing services: {e}")
        raise

    yield

    logger.info("Shutting down the application...")
    try:
        db_service.close_connection()
        logger.info("Firebase connection closed")
    except Exception as e:
        logger.error(f"Error during shutdown: {e}")

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
    logger.info("Health check")
    return {"status": "running"}