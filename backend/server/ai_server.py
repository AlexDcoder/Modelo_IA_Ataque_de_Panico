import os
import logging
import pandas as pd
import numpy as np
import httpx

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from fastapi.responses import RedirectResponse
from .schemas.user_schema import UserInformation
from .schemas.feedback_schema import FeedbackInput
from db.connector import RTDBConnector
from ai.detection import PanicDetectionModel

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# DB connector and AI model
connector = RTDBConnector(
    url_db=os.getenv('DATABASE_URL'),
    cert=os.getenv('CREDENTIAL_FIREBASE')
)

DATA_PATH = 'panic_attack_data_improved.csv'
data = pd.read_csv(DATA_PATH)
model = PanicDetectionModel(data)

async def lifespan(app: FastAPI):
    # Startup: conecta DB e carrega modelo
    connector.connect_db()
    model.start_model()

    yield

# FastAPI app
app = FastAPI(lifespan=lifespan)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Ajustar em produção
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/server/users")
async def get_all_users():
    return connector.get_data(os.getenv('USER_DATASET_REF'))

@app.get("/server/users/{uid}")
async def get_user(uid: str):
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    user_data = connector.get_data(path)
    if user_data is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return {"uid": uid, **user_data}

@app.post("/server/users")
async def upsert_user(user_info: UserInformation, request: Request):
    uid = user_info.uid
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    existing_user = connector.get_data(path)
    
    model_input = {
        "accel_std": user_info.accel_std,
        "heart_rate": user_info.heart_rate,
        "respiration_rate": user_info.respiration_rate,
        "spo2": user_info.spo2,
        "stress_level": user_info.stress_level,
    }

    if existing_user:
        logger.info(f"Usuário {uid} já existe. Atualizando dados.")
        connector.update_data(path, model_input)
        # Redireciona para GET /server/users/{uid}
        return RedirectResponse(
            url=request.url_for('get_user', uid=uid),
            status_code=303
        )
    
    logger.info(f"Criando novo usuário {uid}.")
    connector.add_data(os.getenv('USER_DATASET_REF'), model_input)
    # Redireciona para GET /server/users/{uid}
    return RedirectResponse(
        url=request.url_for('get_user', uid=uid),
        status_code=201
    )

@app.put("/server/users/{uid}")
async def update_user(uid: str, user_info: UserInformation, request: Request):
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    if connector.get_data(path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    connector.update_data(path, user_info.dict())
    # Após atualização, redireciona para GET /server/users/{uid}
    return RedirectResponse(
        url=request.url_for('get_user', uid=uid),
        status_code=303
    )

@app.get("/server/users/{uid}/ai-response")
async def get_ai_response(uid: str):
    path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    user_data = connector.get_data(path)
    if not user_data:
        raise HTTPException(status_code=404, detail="Dados do usuário não encontrados")
    prediction = model.predict_information(user_data).tolist()[0]
    logger.info(f"Predição para {uid}: {prediction}")
    return {'ai_prediction': prediction}


@app.post("/server/users/{uid}/feedback")
async def submit_feedback(uid: str, feedback: FeedbackInput, request: Request):
    global data
    features = feedback.features
    label = feedback.user_feedback
    input_df = pd.DataFrame([features])
    tolerance = 1e-4

    match = data[data[list(features.keys())].apply(
        lambda row: np.all(np.isclose(row.values, input_df.values[0], atol=tolerance)),
        axis=1
    )]

    if not match.empty:
        data.loc[match.index, 'panic_attack'] = label
        message = "Feedback atualizado."
    else:
        new_row = {**features, 'panic_attack': label}
        data = pd.concat([data, pd.DataFrame([new_row])], ignore_index=True)
        message = "Feedback adicionado."

    data.to_csv(DATA_PATH, index=False)

    user_path = f"{os.getenv('USER_DATASET_REF')}/{uid}"
    if connector.get_data(user_path):
        connector.update_data(user_path, features)

    # Dispara re-treinamento e depois redireciona para AI response
    retrain_url = str(request.base_url) + "server/model/retrain"
    async with httpx.AsyncClient() as client:
        await client.post(retrain_url)

    # Redireciona para a predição atualizada
    return RedirectResponse(
        url=request.url_for('get_ai_response', uid=uid),
        status_code=303
    )

# Re-train model
@app.post("/server/model/retrain")
async def retrain_model():
    global data, model
    data = pd.read_csv(DATA_PATH)
    model.update_data(data)
    model.start_model()
    # Redireciona para documentação ou root
    return RedirectResponse(url='/', status_code=303)
