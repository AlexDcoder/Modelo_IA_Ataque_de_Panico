from pydantic import BaseModel
from typing import Dict

class FeedbackInput(BaseModel):
    uid: str
    features: Dict[str, float]
    user_feedback: int