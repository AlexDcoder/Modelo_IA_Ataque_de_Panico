import os
import json
import pandas as pd
from fastapi import FastAPI, HTTPException
from .models.user import UserInformation
from db.connector import DBConnector
from ai.detection import PanicDetectionModel
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

data = pd.read_csv('panic_attack_data_improved.csv')
model = PanicDetectionModel(data)

connector = DBConnector(
    url_db=os.getenv('DATABASE_URL'),
    cert=os.getenv('CREDENTIAL_FIREBASE')
)

@app.on_event("startup")
def startup_event():
    """
    Initialize Firebase connection once when the app starts,
    rather than on every request.
    """
    connector.connect_db()

@app.get("/")
async def read_users():
    """
    Return all users stored under 'usuarios' node.
    """
    # No need to reconnect each time if you initialized in startup
    return connector.get_data(os.getenv('USER_DATASET_REF'))

@app.get("/user_data/{uid}/")
def ler_usuario(uid: str):
    """Lê usuário pelo uid, lança 404 se não existir."""
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    data = connector.get_data(path)
    if data is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return {"uid": uid, **data}

@app.post("/user_data/")
async def add_user_data(user_info: UserInformation):
    """
    Add or overwrite data under 'usuarios' node.
    Returns the submitted payload.
    """
    connector.add_data(os.getenv('USER_DATASET_REF'), user_info.dict())
    return user_info

@app.put("/user_data/{uid}/")
def atualizar_usuario(uid: str, usuario: UserInformation):
    """Atualiza dados de um usuário existente."""
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    if connector.get_data(path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    connector.update_data(path, usuario.dict())
    return {"uid": uid, **usuario.dict()}