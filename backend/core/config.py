import os
from pathlib import Path
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent

ENV_PATH = BASE_DIR / ".env"
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")
CREDENTIAL_FIREBASE = os.getenv("CREDENTIAL_FIREBASE")
USER_PERSONAL_REF = os.getenv("USER_PERSONAL_REF")
USER_SENSOR_REF = os.getenv("USER_SENSOR_REF")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS"))

DATA_PATH = str(BASE_DIR / "panic_attack_data_improved.csv")