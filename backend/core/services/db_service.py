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
    
    def close_connection(self):
        logger.info("Closing database connection")
        self._connector.close_connection()