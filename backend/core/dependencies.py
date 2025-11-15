from fastapi import Depends
from core.db.connector import RTDBConnector
from core.services.db_service import DBService
from core.services.ai_service import AIService
from core.logger import get_logger
from core.security.auth_middleware import get_current_user

logger = get_logger(__name__)

# Conexão única com o Firebase
_firebase_connector = None
# Serviço de banco de dados com conexão compartilhada
_db_service = None
# Serviço de IA
_ai_service = None

def get_firebase_connector() -> RTDBConnector:
    global _firebase_connector
    if _firebase_connector is None:
        logger.info("🔄 [DEPENDENCIES] Initializing Firebase connector")
        _firebase_connector = RTDBConnector()
        logger.info("✅ [DEPENDENCIES] Firebase connector initialized successfully")
    else:
        logger.debug("📝 [DEPENDENCIES] Returning existing Firebase connector instance")
    return _firebase_connector


def get_db_service() -> DBService:
    global _db_service
    if _db_service is None:
        logger.info("🔄 [DEPENDENCIES] Initializing DB Service")
        connector = get_firebase_connector()
        _db_service = DBService(connector)
        logger.info("✅ [DEPENDENCIES] DB Service initialized successfully")
    else:
        logger.debug("📝 [DEPENDENCIES] Returning existing DB Service instance")
    return _db_service


def get_ai_service() -> AIService:
    global _ai_service
    if _ai_service is None:
        logger.info("🔄 [DEPENDENCIES] Initializing AI Service")
        _ai_service = AIService()
        logger.info("✅ [DEPENDENCIES] AI Service initialized successfully")
    else:
        logger.debug("📝 [DEPENDENCIES] Returning existing AI Service instance")
    return _ai_service

# Dependência para autenticação (mantida separada)
async def get_current_user_dependency():
    logger.debug("🔄 [DEPENDENCIES] Getting current user from dependency")
    return await get_current_user()