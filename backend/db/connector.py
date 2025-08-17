import json
import firebase_admin
from firebase_admin import credentials, db
from typing import Dict, Any, Optional

class RTDBConnector:
    def __init__(self, url_db: str = None, cert: str = None) -> None:
        if not url_db or not cert:
            raise EnvironmentError(
                "Environment variables DATABASE_URL and CREDENTIAL_FIREBASE must be set"
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
        self._app = None

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

    def add_data(self, db_ref: str, user_data: dict, uid: Optional[str] = None) -> Dict[str, str]:
        """
        Adiciona dados no Firebase RTDB.
        
        - Se `uid` for fornecido, salva os dados em db_ref/uid.
        - Caso contrário, gera um UID automaticamente com push().
        
        Args:
            db_ref: Caminho base no Firebase (ex: 'vital_data')
            user_data: Dicionário com os dados a serem salvos
            uid: UID opcional. Se fornecido, será usado como chave
        
        Returns:
            Dict com mensagem e uid utilizado ou gerado
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        
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
            raise RuntimeError(f"Failed to add data at '{db_ref}': {e}")


    def get_data(self, db_ref: str) -> Optional[Any]:
        """
        Obtém dados de uma referência específica
        Args:
            db_ref: Referência completa (ex: 'users/uid123' ou 'users')
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            return ref.get()
        except Exception as e:
            raise RuntimeError(f"Failed to read data at '{db_ref}': {e}")
        
    def update_data(self, db_ref: str, updates: dict) -> bool:
        """
        Atualiza dados em uma referência específica
        Args:
            db_ref: Referência completa (ex: 'users/uid123')
            updates: Dados a serem atualizados
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            clean_updates = {k: v for k, v in updates.items() if k != 'uid'}
            ref = db.reference(db_ref, app=self._app)
            ref.update(clean_updates)
            return True
        except Exception as e:
            raise RuntimeError(f"Failed to update data at '{db_ref}': {e}")

    def delete_data(self, db_ref: str) -> Dict[str, str]:
        """
        Remove dados de uma referência específica
        Args:
            db_ref: Referência completa (ex: 'users/uid123')
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            ref.delete()
            return {"message": "Data deleted successfully"}
        except Exception as e:
            raise RuntimeError(f"Failed to delete data at '{db_ref}': {e}")

    def close_connection(self) -> Dict[str, str]:
        if self._app:
            try:
                firebase_admin.delete_app(self._app)
                self._app = None
                return {"message": "Connection closed"}
            except Exception as e:
                raise RuntimeError(f"Error closing Firebase connection: {e}")
        return {"message": "No active connection to close"}