from fastapi import APIRouter, Depends, status, HTTPException
from core.schemas.feedback import FeedbackInput
from core.services.ai_service import AIService
from core.logger import get_logger
from core.security.auth_middleware import get_current_user
from core.dependencies import get_ai_service
router = APIRouter()
logger = get_logger(__name__)

@router.post("/")
async def send_feedback(
    feedback: FeedbackInput, 
    current_user: str = Depends(get_current_user),
    ai_service: AIService = Depends(get_ai_service)
):
    if feedback.uid != current_user:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to send feedback for this user"
        )
        
    logger.info(f"Feedback received for UID={feedback.uid}")
    
    ai_service.set_feedback(feedback.features, feedback.user_feedback)
    
    return {"status": "success"}
