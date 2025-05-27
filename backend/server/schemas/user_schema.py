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
class UserPersonalDataResponse(BaseModel):
    uid: str
    email: str
    password: str
    detection_time: int

class UserVitalDataResponse(BaseModel):
    uid: str
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float

# Para compatibilidade com código existente (deprecated)
class UserInformation(BaseModel):
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float