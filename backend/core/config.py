import os
import json
from pathlib import Path
from dotenv import load_dotenv
from core.logger import get_logger

BASE_DIR = Path(__file__).resolve().parent.parent

logger = get_logger(__name__)

# Determinar ambiente
ENV = os.getenv('ENV', 'production')
TESTING = os.getenv('TESTING', 'False').lower() == 'true'

# Em ambiente de teste, não carregamos .env, usamos variáveis de ambiente diretas
if ENV == 'test' or TESTING:
    print("🔧 Running in TEST environment - using environment variables directly")
    # Não carrega .env, usa apenas variáveis de ambiente
else:
    # Em produção, tenta carregar .env
    ENV_PATH = BASE_DIR / ".env"
    if ENV_PATH.exists():
        load_dotenv(ENV_PATH)
    else:
        logger.warning("ℹNo .env file found, using environment variables")

# Configurações do Firebase com fallbacks
DATABASE_URL = os.getenv("DATABASE_URL", "https://panic-attack-classifier-default-rtdb.firebaseio.com")
CREDENTIAL_FIREBASE = os.getenv("CREDENTIAL_FIREBASE", "")
CREDENTIAL_FIREBASE_PATH = os.getenv("CREDENTIAL_FIREBASE_PATH", "./firebase-credentials.json")
USER_PERSONAL_REF = os.getenv("USER_PERSONAL_REF", "user_registers")
USER_SENSOR_REF = os.getenv("USER_SENSOR_REF", "user_sensors_data")

# Configurações JWT com fallbacks
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "8a68e13e490405904dbe549068bcdabf0223ad51fc3f5cdb57943e69a5bb5a60")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

# Caminho dos dados
DATA_PATH = os.getenv("DATA_PATH", str(BASE_DIR / "panic_attack_data_improved.csv"))

# Função otimizada para carregar credenciais
def load_firebase_credentials():
    """Carrega credenciais do Firebase de forma flexível"""
    logger.info("🔄 Loading Firebase credentials...")
    
    # 1. Primeiro tenta carregar do arquivo (para GitHub Actions)
    if CREDENTIAL_FIREBASE_PATH and os.path.exists(CREDENTIAL_FIREBASE_PATH):
        try:
            with open(CREDENTIAL_FIREBASE_PATH, 'r') as f:
                content = f.read().strip()
                if content:
                    return CREDENTIAL_FIREBASE_PATH
        except Exception as e:
            logger.warning(f"⚠️ Error reading credentials file: {e}")
    
    # 2. Tenta carregar da variável de ambiente JSON
    if CREDENTIAL_FIREBASE and CREDENTIAL_FIREBASE.strip():
        logger.info("🔑 Loading from environment variable")
        try:
            json.loads(CREDENTIAL_FIREBASE)
            return CREDENTIAL_FIREBASE
        except json.JSONDecodeError:
            logger.warning("⚠️ CREDENTIAL_FIREBASE is not valid JSON")
    
    # 3. Fallback para Google default
    google_cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if google_cred_path and os.path.exists(google_cred_path):
        return google_cred_path
    
    logger.error("❌ No Firebase credentials found")
    return None

# Carregar credenciais
FIREBASE_CREDENTIALS = load_firebase_credentials()

if FIREBASE_CREDENTIALS:
    logger.info("Firebase credentials loaded successfully")
else:
    logger.warning("No Firebase credentials configured")