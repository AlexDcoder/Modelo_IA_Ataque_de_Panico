import re
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, field_validator
from .emergency_contact import EmergencyContact

class UserPersonalData(BaseModel):
    username: str = Field(..., min_length=3)
    email: EmailStr
    detection_time: str  
    emergency_contact: list[EmergencyContact]

    @field_validator("username")
    def validate_username(cls, value: str) -> str:
        pattern = r'^[a-zA-Z0-9]+$'
        if not re.match(pattern, value):
            raise ValueError("Username must be alphanumeric.")
        return value
    
    @field_validator("detection_time")
    def validate_detection_time(cls, value: str) -> str:
        try:
            datetime.fromisoformat(value.replace('Z', '+00:00'))
            return value
        except ValueError:
            raise ValueError("detection_time must be a valid ISO 8601 datetime string")

class UserVitalData(BaseModel):
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float

class UserVitalDataResponse(UserVitalData):
    uid: str