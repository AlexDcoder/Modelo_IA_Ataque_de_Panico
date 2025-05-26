from pydantic import BaseModel
from typing import Dict

class FeedbackInput(BaseModel):
    uid: str  # Mantém uid pois será usado para identificar o usuário existente
    features: Dict[str, float]
    user_feedback: int
