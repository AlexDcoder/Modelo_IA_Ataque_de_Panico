import os
import logging
import pandas as pd
import numpy as np
import httpx
from datetime import datetime

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from fastapi.responses import RedirectResponse

from .schemas.user_schema import UserPersonalData, UserVitalData, UserInformation, \
    UserPersonalDataResponse, UserVitalDataResponse
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

# ===== ROTAS PARA DADOS PESSOAIS =====
@app.get("/server/users")
async def get_all_users():
    """Retorna todos os usuários (dados pessoais)"""
    return connector.get_data(os.getenv('USER_PERSONAL_REF'))

@app.get("/server/users/{uid}")
async def get_user(uid: str):
    """Retorna dados pessoais de um usuário específico"""
    path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    user_data = connector.get_data(path)
    if user_data is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return {"uid": uid, **user_data}

@app.post("/server/users", response_model=UserPersonalDataResponse)
async def create_user(user_data: UserPersonalData):
    """Cria usuário com UID gerado automaticamente pelo Firebase"""
    
    # Converte datetime para string ISO se necessário
    user_dict = user_data.dict()
    if isinstance(user_dict.get('detection_time'), datetime):
        user_dict['detection_time'] = user_dict['detection_time'].isoformat()
    
    # Adiciona dados e recebe UID gerado
    result = connector.add_data(os.getenv('USER_PERSONAL_REF'), user_dict)
    generated_uid = result["uid"]
    
    logger.info(f"Usuário criado com UID: {generated_uid}")
    
    return UserPersonalDataResponse(
        uid=generated_uid,
        **user_dict
    )

@app.put("/server/users/{uid}", response_model=UserPersonalDataResponse)
async def update_user(uid: str, user_data: UserPersonalData):
    """Atualiza dados pessoais de um usuário existente"""
    path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    user_dict = user_data.dict()
    if isinstance(user_dict.get('detection_time'), datetime):
        user_dict['detection_time'] = user_dict['detection_time'].isoformat()
    
    connector.update_data(path, user_dict)
    
    return UserPersonalDataResponse(
        uid=uid,
        **user_dict
    )

# ===== ROTAS PARA DADOS VITAIS =====
@app.get("/server/vital-data")
async def get_all_vital_data():
    """Retorna todos os dados vitais"""
    return connector.get_data(os.getenv('USER_SENSOR_REF'))

@app.get("/server/vital-data/{uid}")
async def get_user_vital_data(uid: str):
    """Retorna dados vitais de um usuário específico"""
    user_path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(user_path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    path = f"{os.getenv('USER_SENSOR_REF')}/{uid}"
    vital_data = connector.get_data(path)
    if vital_data is None:
        raise HTTPException(status_code=404, detail="Dados vitais não encontrados")
    return {"uid": uid, **vital_data}

@app.post("/server/vital-data/{uid}")
async def create_vital_data(uid: str, vital_data: UserVitalData, request: Request):
    """Cria ou atualiza dados vitais do usuário"""
    user_path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(user_path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    path = f"{os.getenv('USER_SENSOR_REF')}/{uid}"
    existing_data = connector.get_data(path)

    vital_dict = vital_data.dict()

    if existing_data:
        logger.info(f"Dados vitais do usuário {uid} já existem. Atualizando.")
        connector.update_data(path, vital_dict)
        status_code = 303
    else:
        logger.info(f"Criando novos dados vitais para usuário {uid}.")
        connector.add_data(os.getenv('USER_SENSOR_REF'), vital_dict, uid=uid)
        status_code = 201

    return RedirectResponse(
        url=request.url_for('get_user_vital_data', uid=uid),
        status_code=status_code
    )

@app.put("/server/vital-data/{uid}")
async def update_vital_data(uid: str, vital_data: UserVitalData, request: Request):
    """Atualiza dados vitais de um usuário"""
    user_path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(user_path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    path = f"{os.getenv('USER_SENSOR_REF')}/{uid}"
    if connector.get_data(path) is None:
        raise HTTPException(status_code=404, detail="Dados vitais não encontrados")
    
    vital_dict = vital_data.dict()
    connector.update_data(path, vital_dict)
    
    return RedirectResponse(
        url=request.url_for('get_user_vital_data', uid=uid),
        status_code=303
    )

@app.get("/server/users/{uid}/ai-response")
async def get_ai_response(uid: str):
    """Retorna predição da IA baseada nos dados vitais do usuário"""
    user_path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(user_path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    vital_path = f"{os.getenv('USER_SENSOR_REF')}/{uid}"
    vital_data = connector.get_data(vital_path)
    
    if not vital_data:
        raise HTTPException(status_code=404, detail="Dados vitais do usuário não encontrados")
    
    # Remove uid para predição se existir
    model_input = {k: v for k, v in vital_data.items() if k != 'uid'}
    
    prediction = model.predict_information(model_input).tolist()[0]
    logger.info(f"Predição para {uid}: {prediction}")
    return {'ai_prediction': prediction}

@app.post("/server/users/{uid}/feedback")
async def submit_feedback(uid: str, feedback: FeedbackInput, request: Request):
    """Submete feedback do usuário e retreina o modelo"""
    user_path = f"{os.getenv('USER_PERSONAL_REF')}/{uid}"
    if connector.get_data(user_path) is None:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    global data
    features = feedback.features
    label = feedback.user_feedback
    input_df = pd.DataFrame([features])
    tolerance = 1e-4

    # Busca match no dataset existente
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

    # Salva dataset atualizado
    data.to_csv(DATA_PATH, index=False)

    # Atualiza dados vitais do usuário no Firebase
    vital_path = f"{os.getenv('USER_SENSOR_REF')}/{uid}"
    if connector.get_data(vital_path):
        connector.update_data(vital_path, features)

    # Dispara re-treinamento
    retrain_url = str(request.base_url) + "server/model/retrain"
    async with httpx.AsyncClient() as client:
        await client.post(retrain_url)

    return RedirectResponse(
        url=request.url_for('get_ai_response', uid=uid),
        status_code=303
    )

@app.post("/server/model/retrain")
async def retrain_model():
    """Retreina o modelo de IA"""
    global data, model
    data = pd.read_csv(DATA_PATH)
    model.update_data(data)
    model.start_model()
    return RedirectResponse(url='/', status_code=303)

# ===== ROTAS DE COMPATIBILIDADE (DEPRECATED) =====
@app.post("/server/users/legacy", response_model=UserVitalDataResponse)
async def upsert_user_legacy(user_info: UserInformation):
    """
    DEPRECATED: Use /server/vital-data instead
    Mantido para compatibilidade com código antigo
    """
    logger.warning(" Using deprecated endpoint. Please use /server/vital-data instead.")
    
    # Converte para novo formato
    vital_data = UserVitalData(**user_info.dict())
    return await create_vital_data(vital_data)
