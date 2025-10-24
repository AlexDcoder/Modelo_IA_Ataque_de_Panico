from pydantic import BaseModel
class EmergencyContact(BaseModel):
    name: str
    phone: str