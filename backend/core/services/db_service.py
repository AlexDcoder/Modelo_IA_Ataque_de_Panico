from core.db.connector import RTDBConnector
from core.config import USER_SENSOR_REF, USER_PERSONAL_REF

class DBService:
    def __init__(self, connector: RTDBConnector) -> None:
        self._connector = connector

    def get_all_users(self):
        return self._connector.get_data(USER_PERSONAL_REF)

    def get_user(self, uid):
        return self._connector.get_data(f"{USER_PERSONAL_REF}/{uid}")

    def create_user(self, uid, user_data):
        return self._connector.add_data(USER_PERSONAL_REF, user_data, uid)
    
    def update_user(self, uid, user_data):
        return self._connector.update_data(f"{USER_PERSONAL_REF}/{uid}", user_data)
    
    def delete_user(self, uid):
        return self._connector.delete_data(f"{USER_PERSONAL_REF}/{uid}")
    
    def get_user_vital_data(self, uid):
        return self._connector.get_data(f"{USER_SENSOR_REF}/{uid}")
    
    def set_vital(self, uid: str, data: dict):
        return self._connector.add_data(USER_SENSOR_REF, data, uid=uid)

    def update_vital(self, uid: str, data: dict):
        return self._connector.update_data(f"{USER_SENSOR_REF}/{uid}", data)