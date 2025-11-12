from fastapi import APIRouter, Depends, HTTPException, status
from core.services.ai_service import AIService
from core.schemas.user import UserVitalData
from core.logger import get_logger
from core.security.auth_middleware import get_current_user
from core.dependencies import get_ai_service

router = APIRouter()
logger = get_logger(__name__)

@router.post("/predict")
async def predict(
    vitals: UserVitalData, 
    current_user: str = Depends(get_current_user),
    ai_service: AIService = Depends(get_ai_service)
):
    try:
        """Faz predição baseada apenas nos dados vitais"""
        result = ai_service.predict(vitals.model_dump())
        return {"panic_attack_detected": bool(result)}
    except Exception as e:
        logger.error(f"Error during prediction: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error during prediction")