import re
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from core.schemas.user import UserPersonalData, UserVitalData
from core.schemas.emergency_contact import EmergencyContact

class UserCreateDTO(UserPersonalData):
    password: str = Field(..., min_length=8)

    @field_validator("password")
    def validate_password(cls, value: str) -> str:
        pattern = r"^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$"
        if not re.match(pattern, value):
            raise ValueError(
                "Password must be at least 8 characters long, contain at least one letter, one number, and one special character."
            )
        return value
    
    @field_validator("detection_time")
    def validate_detection_time(cls, value: str) -> str:
        try:
            datetime.fromisoformat(value.replace('Z', '+00:00'))
            return value
        except ValueError:
            raise ValueError("detection_time must be a valid ISO 8601 datetime string")
    
class UserLoginDTO(BaseModel):
    email: EmailStr
    password: str

class UserUpdateDTO(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=30)
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8)
    detection_time: Optional[datetime] = None
    emergency_contact: Optional[list[EmergencyContact]] = None

    @field_validator("password")
    def validate_password(cls, value: Optional[str]) -> Optional[str]:
        if value:
            pattern = r"^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$"
            if not re.match(pattern, value):
                raise ValueError("Invalid password format.")
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