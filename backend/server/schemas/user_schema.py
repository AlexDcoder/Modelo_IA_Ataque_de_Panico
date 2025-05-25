from pydantic import BaseModel

class UserInformation(BaseModel):
    uid: str
    heart_rate: float
    respiration_rate: float
    accel_std: float
    spo2: float
    stress_level: float
