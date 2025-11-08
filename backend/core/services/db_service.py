from core.db.connector import RTDBConnector
from core.config import USER_SENSOR_REF, USER_PERSONAL_REF
from core.logger import get_logger


logger = get_logger(__name__)

class DBService:
    def __init__(self, connector: RTDBConnector) -> None:
        self._connector = connector
        
    def get_all_users(self):
        logger.info("Getting all users")
        return self._connector.get_data(USER_PERSONAL_REF)

    def get_user(self, uid):
        logger.info(f"Getting user {uid}")
        return self._connector.get_data(f"{USER_PERSONAL_REF}/{uid}")

    def create_user(self, uid, user_data):
        logger.info(f"Creating user")
        return self._connector.add_data(USER_PERSONAL_REF, user_data, uid)
    
    def update_user(self, uid, user_data):
        logger.info(f"Updating user {uid}")
        return self._connector.update_data(f"{USER_PERSONAL_REF}/{uid}", user_data)
    
    def delete_user(self, uid):
        logger.info(f"Deleting user {uid}")
        return self._connector.delete_data(f"{USER_PERSONAL_REF}/{uid}")
    
    def get_user_vital_data(self, uid):
        logger.info(f"Getting vital data for user {uid}")
        return self._connector.get_data(f"{USER_SENSOR_REF}/{uid}")
    
    def set_vital(self, uid: str, data: dict):
        logger.info(f"Setting vital data for user {uid}")
        return self._connector.add_data(USER_SENSOR_REF, data, uid=uid)

    def update_vital(self, uid: str, data: dict):
        logger.info(f"Updating vital data for user {uid}")
        return self._connector.update_data(f"{USER_SENSOR_REF}/{uid}", data)
    
    def delete_vital(self, uid: str):
        logger.info(f"Deleting vital data for user {uid}")
        return self._connector.delete_data(f"{USER_SENSOR_REF}/{uid}")
    
    # Adicione esta função no arquivo db_service.py
    def check_existing_user(self, email: str = None, username: str = None) -> tuple[bool, bool]:
        """Verifica se email ou username já existem no banco.
        Retorna (email_exists, username_exists)"""
        users = self.get_all_users() or {}
        
        email_exists = False
        username_exists = False
        
        for user_data in users.values():
            if email and user_data.get('email') == email:
                email_exists = True
            if username and user_data.get('username') == username:
                username_exists = True
            if email_exists and username_exists:
                break
        
        return email_exists, username_exists
    
    def close_connection(self):
        logger.info("Closing database connection")
        self._connector.close_connection()