import json
import firebase_admin
from firebase_admin import credentials, db

class RTDBConnector:
    def __init__(self, url_db: str = None, cert: str = None) -> None:
        url_db = url_db
        cert = cert

        if not url_db or not cert:
            raise EnvironmentError(
                "Environment variables FIREBASE_DB_URL and FIREBASE_CERT_PATH_OR_JSON must be set"
            )

        if cert.strip().startswith("{"):
            try:
                cert_dict = json.loads(cert)
            except json.JSONDecodeError as e:
                raise RuntimeError(f"Invalid credential JSON: {e}")
            try:
                self._cred = credentials.Certificate(cert_dict)
            except Exception as e:
                raise RuntimeError(f"Failed to load credentials from dict: {e}")
        else:
            try:
                self._cred = credentials.Certificate(cert)
            except Exception as e:
                raise RuntimeError(f"Failed to load credentials from file: {e}")

        self._url_db = url_db
        self._app    = None

    def connect_db(self) -> None:
        if not self._app:
            try:
                self._app = firebase_admin.initialize_app(self._cred, {
                    'databaseURL': self._url_db
                })
            except ValueError:
                self._app = firebase_admin.get_app()
            except Exception as e:
                raise RuntimeError(f"Error connecting to Firebase: {e}")

    def add_data(self, db_ref: str, user_data: dict) -> None:
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            uid = user_data.get("uid")
            if not uid:
                raise ValueError("user_data must contain 'uid' key")
            # Grava diretamente no nó do usuário (sobrescreve ou cria)
            ref = db.reference(f"{db_ref}/{uid}", app=self._app)
            ref.set(user_data)
            return {"message": "Data saved"}
        except Exception as e:
            raise RuntimeError(f"Failed to add data at '{db_ref}': {e}")

    def get_data(self, db_ref: str):
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            return ref.get()
        except Exception as e:
            raise RuntimeError(f"Failed to read data at '{db_ref}': {e}")
        
    def update_data(self, db_ref: str, updates: dict) -> bool:
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            ref.update(updates)
            return True
        except Exception as e:
            raise RuntimeError(f"Failed to update data at '{db_ref}': {e}")

    def close_connection(self) -> None:
        if self._app:
            try:
                firebase_admin.delete_app(self._app)
                self._app = None
                return {"message": "Connection closed"}
            except Exception as e:
                raise RuntimeError(f"Error closing Firebase connection: {e}")

