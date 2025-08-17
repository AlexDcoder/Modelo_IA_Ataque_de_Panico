from pydantic import BaseModel, EmailStr

class UserPersonalData(BaseModel):
    email: EmailStr
    password: str
    detection_time: int

class UserVitalData(BaseModel):
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float

class UserPersonalDataResponse(UserPersonalData):
    uid: str

class UserVitalDataResponse(UserVitalData):
    uid: str