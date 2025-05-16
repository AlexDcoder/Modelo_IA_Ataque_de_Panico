import os
import json
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException, Request
from .models.user import UserInformation
from .models.feedback import FeedbackInput
from db.connector import DBConnector
from ai.detection import PanicDetectionModel
from dotenv import load_dotenv
import httpx

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
    model.start_model()

@app.get("/")
async def view_all_users():
    """
    Return all users stored under 'usuarios' node.
    """
    # No need to reconnect each time if you initialized in startup
    return connector.get_data(os.getenv('USER_DATASET_REF'))

@app.get("/user_data/{uid}/")
async def view_user_data(uid: str):
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
async def update_user_data(uid: str, user_info: UserInformation):
    """Atualiza dados de um usuário existente."""
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    if connector.get_data(path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    connector.update_data(path, user_info.dict())
    return {"uid": uid, **user_info.dict()}

@app.get("/ai_response/{uid}")
async def get_response_ai(uid: str):
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    user_data = connector.get_data(path)
    value = model.predict_information(user_data).tolist()[0]
    return {'ai_prediction': value}


@app.post("/ia_feedback")
async def set_ia_feedback(user_res: FeedbackInput, request: Request):
    features = user_res.features
    label = user_res.user_feedback

    input_df = pd.DataFrame([features])
    tolerance = 1e-4

    global data

    # Encontra as linhas que batem com os features fornecidos
    match = data[data[list(features.keys())].apply(
        lambda row: np.all(np.isclose(row.values, input_df.values[0], atol=tolerance)),
        axis=1
    )]

    if not match.empty:
        data.loc[match.index, 'panic_attack'] = label
        msg = "Linha existente atualizada com o novo feedback."
    else:
        new_row = {**features, 'panic_attack': label}
        data = pd.concat([data, pd.DataFrame([new_row])], ignore_index=True)
        msg = "Nova linha adicionada com o feedback."

    # Salva no CSV
    data.to_csv('panic_attack_data_improved.csv', index=False)

    url = str(request.base_url) + "retrain_model"
    async with httpx.AsyncClient() as client:
        await client.post(url)

    return {"message": msg}

@app.post("/retrain_model")
async def retrain_model():
    global data, model

    data = pd.read_csv('panic_attack_data_improved.csv')
    model.update_data(data)
    model.start_model()

    return {"message": "Modelo reentreinado com sucesso."}
