import re
from datetime import datetime, time
from pydantic import BaseModel, EmailStr, Field, field_validator
from .emergency_contact import EmergencyContact

class UserPersonalData(BaseModel):
    username: str = Field(..., min_length=3)
    email: EmailStr
    detection_time: str  # Formato: "HH:MM:SS"
    emergency_contact: list[EmergencyContact]

    @field_validator("username")
    def validate_username(cls, value: str) -> str:
        pattern = r'^.{3,}'
        if not re.match(pattern, value):
            raise ValueError("Username must be alphanumeric.")
        return value
    
    @field_validator("detection_time")
    def validate_detection_time(cls, value: str) -> str:
        # Validar formato HH:MM:SS
        pattern = r'^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
        if not re.match(pattern, value):
            raise ValueError("detection_time must be in HH:MM:SS format")
        
        # Validar se é um horário válido
        try:
            hours, minutes, seconds = map(int, value.split(':'))
            time(hours, minutes, seconds)
        except ValueError:
            raise ValueError("Invalid time values")
            
        return value

class UserVitalData(BaseModel):
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float

class UserVitalDataResponse(UserVitalData):
    uid: str