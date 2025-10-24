import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR = BASE_DIR.parent
ENV_PATH = BASE_DIR / ".env"
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")
CREDENTIAL_FIREBASE = os.getenv("CREDENTIAL_FIREBASE")
USER_PERSONAL_REF = os.getenv("USER_PERSONAL_REF", "users")
USER_SENSOR_REF = os.getenv("USER_SENSOR_REF", "vital_data")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "supersecret")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

DATA_PATH = os.getenv("DATA_PATH", str(BASE_DIR / "panic_attack_data_improved.csv"))
MODEL_PATH = os.getenv("MODEL_PATH", str(BASE_DIR / "models" / "panic_model.joblib"))

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

REQUIRED_VARS = ["DATABASE_URL", "CREDENTIAL_FIREBASE", "JWT_SECRET_KEY"]

_missing = [v for v in REQUIRED_VARS if not globals().get(v)]
if _missing:
    raise RuntimeError(f"Variáveis obrigatórias ausentes no .env: {', '.join(_missing)}")