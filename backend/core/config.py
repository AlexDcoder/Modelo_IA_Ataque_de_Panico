import os
import json
from pathlib import Path
from dotenv import load_dotenv

# Diretório base do projeto
BASE_DIR = Path(__file__).resolve().parent.parent

# Configurações de ambiente
ENV = os.getenv("ENV", "production")
TESTING = os.getenv("TESTING", "False").lower() == "true"

# Determinar qual arquivo .env carregar
if ENV == "test" or TESTING:
    ENV_PATH = BASE_DIR / ".env.test"
else:
    ENV_PATH = BASE_DIR / ".env"

# Carregar variáveis de ambiente
load_dotenv(ENV_PATH)

# Configurações do Firebase
DATABASE_URL = os.getenv("DATABASE_URL")
CREDENTIAL_FIREBASE = os.getenv("CREDENTIAL_FIREBASE")
CREDENTIAL_FIREBASE_PATH = os.getenv("CREDENTIAL_FIREBASE_PATH")
USER_PERSONAL_REF = os.getenv("USER_PERSONAL_REF")
USER_SENSOR_REF = os.getenv("USER_SENSOR_REF")

# Configurações JWT
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

# Caminho dos dados
DATA_PATH = os.getenv("DATA_PATH", str(BASE_DIR / "panic_attack_data_improved.csv"))


def load_firebase_credentials():
    """Carrega credenciais do Firebase de forma flexível para diferentes ambientes."""
    
    # 1️⃣ Tenta carregar de um arquivo explícito
    if CREDENTIAL_FIREBASE_PATH and os.path.exists(CREDENTIAL_FIREBASE_PATH):
        return CREDENTIAL_FIREBASE_PATH
    
    # 2️⃣ Tenta carregar de variável de ambiente (JSON, caminho ou string direta)
    elif CREDENTIAL_FIREBASE:
        # Se for JSON válido
        try:
            json.loads(CREDENTIAL_FIREBASE)
            return CREDENTIAL_FIREBASE
        except json.JSONDecodeError:
            pass  # não é JSON, vamos testar as outras opções
        
        # Se for caminho de arquivo
        if os.path.exists(CREDENTIAL_FIREBASE):
            return CREDENTIAL_FIREBASE
        
        # Caso contrário, é uma string direta (hardcoded)
        return CREDENTIAL_FIREBASE

    # 3️⃣ Fallback: variável padrão do Google
    elif os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        google_cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        return google_cred_path

    # 4️⃣ Nenhuma credencial encontrada
    else:
        raise RuntimeError(
            "No Firebase credentials found. Please set one of: "
            "CREDENTIAL_FIREBASE, CREDENTIAL_FIREBASE_PATH, or GOOGLE_APPLICATION_CREDENTIALS."
        )


# Carregar credenciais
try:
    FIREBASE_CREDENTIALS = load_firebase_credentials()
except Exception as e:
    print(f"⚠️ Warning: {e}")
    FIREBASE_CREDENTIALS = None
