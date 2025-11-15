from core.db.connector import RTDBConnector
from core.config import USER_SENSOR_REF, USER_PERSONAL_REF
from core.logger import get_logger


logger = get_logger(__name__)

class DBService:
    def __init__(self, connector: RTDBConnector) -> None:
        self._connector = connector
        
    def get_all_users(self):
        logger.info("🔄 [DB_SERVICE] Getting all users")
        result = self._connector.get_data(USER_PERSONAL_REF)
        logger.info(f"✅ [DB_SERVICE] Retrieved {len(result) if result else 0} users")
        return result

    def get_user(self, uid):
        logger.info(f"🔄 [DB_SERVICE] Getting user {uid}")
        result = self._connector.get_data(f"{USER_PERSONAL_REF}/{uid}")
        if result:
            logger.info(f"✅ [DB_SERVICE] User {uid} found")
        else:
            logger.warning(f"⚠️ [DB_SERVICE] User {uid} not found")
        return result

    def create_user(self, uid, user_data):
        logger.info(f"🔄 [DB_SERVICE] Creating user with UID: {uid}")
        logger.debug(f"📦 [DB_SERVICE] User data: {user_data}")
        result = self._connector.add_data(USER_PERSONAL_REF, user_data, uid)
        logger.info(f"✅ [DB_SERVICE] User created successfully")
        logger.debug(f"📄 [DB_SERVICE] Create result: {result}")
        return result
    
    def update_user(self, uid, user_data):
        logger.info(f"🔄 [DB_SERVICE] Updating user {uid}")
        logger.debug(f"📦 [DB_SERVICE] Update data: {user_data}")
        result = self._connector.update_data(f"{USER_PERSONAL_REF}/{uid}", user_data)
        logger.info(f"✅ [DB_SERVICE] User updated successfully")
        logger.debug(f"📄 [DB_SERVICE] Update result: {result}")
        return result
    
    def delete_user(self, uid):
        logger.info(f"🔄 [DB_SERVICE] Deleting user {uid}")
        result = self._connector.delete_data(f"{USER_PERSONAL_REF}/{uid}")
        logger.info(f"✅ [DB_SERVICE] User deleted successfully")
        return result
    
    def get_user_vital_data(self, uid):
        logger.info(f"🔄 [DB_SERVICE] Getting vital data for user {uid}")
        result = self._connector.get_data(f"{USER_SENSOR_REF}/{uid}")
        if result:
            logger.info(f"✅ [DB_SERVICE] Vital data found for user {uid}")
        else:
            logger.warning(f"⚠️ [DB_SERVICE] Vital data not found for user {uid}")
        return result
    
    def set_vital(self, uid: str, data: dict):
        logger.info(f"🔄 [DB_SERVICE] Setting vital data for user {uid}")
        logger.debug(f"📦 [DB_SERVICE] Vital data: {data}")
        result = self._connector.add_data(USER_SENSOR_REF, data, uid=uid)
        logger.info(f"✅ [DB_SERVICE] Vital data set successfully")
        return result

    def update_vital(self, uid: str, data: dict):
        logger.info(f"🔄 [DB_SERVICE] Updating vital data for user {uid}")
        logger.debug(f"📦 [DB_SERVICE] Update data: {data}")
        result = self._connector.update_data(f"{USER_SENSOR_REF}/{uid}", data)
        logger.info(f"✅ [DB_SERVICE] Vital data updated successfully")
        return result
    
    def delete_vital(self, uid: str):
        logger.info(f"🔄 [DB_SERVICE] Deleting vital data for user {uid}")
        result = self._connector.delete_data(f"{USER_SENSOR_REF}/{uid}")
        logger.info(f"✅ [DB_SERVICE] Vital data deleted successfully")
        return result
    
    def check_existing_user(self, email: str = None, username: str = None) -> tuple[bool, bool]:
        """Verifica se email ou username já existem no banco.
        Retorna (email_exists, username_exists)"""
        logger.info(f"🔄 [DB_SERVICE] Checking existing user - Email: {email}, Username: {username}")
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
        
        logger.info(f"✅ [DB_SERVICE] Check result - Email exists: {email_exists}, Username exists: {username_exists}")
        return email_exists, username_exists
    
    def close_connection(self):
        logger.info("🔄 [DB_SERVICE] Closing database connection")
        self._connector.close_connection()
        logger.info("✅ [DB_SERVICE] Database connection closed")