import re
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import time
from core.schemas.user import UserPersonalData, UserVitalData
from core.schemas.emergency_contact import EmergencyContact

class UserCreateDTO(UserPersonalData):
    password: str = Field(..., min_length=8)

    @field_validator("password")
    def validate_password(cls, value: str) -> str:
        pattern = r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$"
        if not re.match(pattern, value):
            raise ValueError(
                "The password must contain at least 8 characters, including at least one letter and one number."
            )
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
    
class UserLoginDTO(BaseModel):
    email: EmailStr
    password: str

class UserUpdateDTO(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=30)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8)
    detection_time: Optional[str] = None  # Formato: "HH:MM:SS"
    emergency_contact: Optional[list[EmergencyContact]] = None

    @field_validator("password")
    def validate_password(cls, value: str) -> str:
        pattern = r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$"
        if not re.match(pattern, value):
            raise ValueError(
                "The password must contain at least 8 characters, including at least one letter and one number."
        )
        return value
    
    @field_validator("detection_time")
    def validate_detection_time(cls, value: Optional[str]) -> Optional[str]:
        if value:
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
    
class UserResponseDTO(UserPersonalData):
    uid: str

class VitalDataCreateDTO(UserVitalData):
    pass

class VitalResponseDTO(UserVitalData):
    uid: str

class UserPublicDTO(BaseModel):
    uid: str
    username: str
    email: EmailStr
    detection_time: str