from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.logger import get_logger
from core.routes import users, feedback, ai, vital, auth

logger = get_logger(__name__)

app = FastAPI(
    title='Panic Attack Detection API',
    version='1.0.0'
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
async def root():
    """Health check endpoint for the API.

    Returns a JSON object with a single key-value pair, where the key is "status" and the value is "running".
    """
    logger.info("Health check")
    return {"status": "running"}