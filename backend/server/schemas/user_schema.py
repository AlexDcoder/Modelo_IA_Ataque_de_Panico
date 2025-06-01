from pydantic import BaseModel, EmailStr

class UserPersonalData(BaseModel):
    email: EmailStr
    password: str
    detection_time: int  # Obrigatório

class UserVitalData(BaseModel):
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float

# Schemas de resposta (com uid gerado)
class UserPersonalDataResponse(UserPersonalData):
    uid: str

class UserVitalDataResponse(UserVitalData):
    uid: str