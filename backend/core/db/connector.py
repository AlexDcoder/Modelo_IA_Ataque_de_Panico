import os
import json
import firebase_admin
from firebase_admin import credentials, db
from typing import Dict, Any, Optional
from core.config import DATABASE_URL, FIREBASE_CREDENTIALS
from core.logger import get_logger

logger = get_logger(__name__)

class RTDBConnector:
    def __init__(self) -> None:
        try:
            self._url_db = DATABASE_URL
            self._cred = self._load_credentials(FIREBASE_CREDENTIALS)
            self._app = None
            self.connect_db()
        except Exception as e:
            logger.error(f"❌ Failed to initialize RTDBConnector: {e}")
            raise RuntimeError(f"Failed to initialize RTDBConnector: {e}")
    
    def _load_credentials(self, cred_source: str):
        """Carrega credenciais do Firebase de forma flexível"""
        try:
            if not cred_source:
                raise ValueError("No credentials source provided")
            
            # Se for um caminho de arquivo
            if os.path.exists(cred_source):
                return credentials.Certificate(cred_source)
            
            # Se for um JSON string
            if cred_source.strip().startswith("{"):
                cred_dict = json.loads(cred_source)
                return credentials.Certificate(cred_dict)
            
            # Se for um caminho que não existe, tenta como JSON
            try:
                cred_dict = json.loads(cred_source)
                return credentials.Certificate(cred_dict)
            except json.JSONDecodeError:
                raise ValueError(f"Invalid credential source: {cred_source}")
                
        except Exception as e:
            logger.error(f"❌ Failed to load Firebase credentials: {e}")
            raise RuntimeError(f"Failed to load Firebase credentials: {e}")

    # ... resto do código do connector permanece igual ...
    def connect_db(self) -> None:
        if not self._app:
            try:
                self._app = firebase_admin.initialize_app(self._cred, {
                    'databaseURL': self._url_db
                })
            except ValueError:
                self._app = firebase_admin.get_app()
            except Exception as e:
                logger.error(f"❌ Error connecting to Firebase: {e}")
                raise RuntimeError(f"Error connecting to Firebase: {e}")

    def add_data(self, db_ref: str, user_data: dict, uid: Optional[str] = None) -> Dict[str, str]:
        if not self._app:
            self.connect_db()
        
        try:
            if uid:
                ref = db.reference(f"{db_ref}/{uid}", app=self._app)
                ref.set(user_data)
                return {"message": "Data saved successfully", "uid": uid}
            else:
                ref = db.reference(db_ref, app=self._app)
                new_ref = ref.push(user_data)
                generated_uid = new_ref.key
                return {"message": "Data saved successfully", "uid": generated_uid}
        except Exception as e:
            logger.error(f"❌ Failed to add data at '{db_ref}': {e}")
            raise RuntimeError(f"Failed to add data at '{db_ref}': {e}")

    def get_data(self, db_ref: str) -> Optional[Any]:
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            data = ref.get()
            return data if data is not None else None
        except Exception as e:
            logger.error(f"❌ Failed to read data at '{db_ref}': {e}")
            raise RuntimeError(f"Failed to read data at '{db_ref}': {e}")
        
    def update_data(self, db_ref: str, updates: dict) -> bool:
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            clean_updates = {k: v for k, v in updates.items() if k != 'uid'}
            ref = db.reference(db_ref, app=self._app)
            ref.update(clean_updates)
            return True
        except Exception as e:
            logger.error(f"❌ Failed to update data at '{db_ref}': {e}")
            raise RuntimeError(f"Failed to update data at '{db_ref}': {e}")

    def delete_data(self, db_ref: str) -> Dict[str, str]:
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            ref.delete()
            return {"message": "Data deleted successfully"}
        except Exception as e:
            logger.error(f"❌ Failed to delete data at '{db_ref}': {e}")
            raise RuntimeError(f"Failed to delete data at '{db_ref}': {e}")

    def close_connection(self) -> Dict[str, str]:
        if self._app:
            try:
                firebase_admin.delete_app(self._app)
                self._app = None
                return {"message": "Connection closed"}
            except Exception as e:
                logger.error(f"❌ Error closing Firebase connection: {e}")
                raise RuntimeError(f"Error closing Firebase connection: {e}")
        return {"message": "No active connection to close"}