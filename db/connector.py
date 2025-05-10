import os
import json
import firebase_admin
from firebase_admin import credentials, db

class DBConnector:
    def __init__(self, url_db: str = None, cert: str = None) -> None:
        # Use provided URL or fall back to FIREBASE_DB_URL environment variable
        url_db = url_db or os.getenv("FIREBASE_DB_URL")
        # Use provided certificate string/path or fall back to FIREBASE_CERT_PATH_OR_JSON env var
        cert   = cert  or os.getenv("FIREBASE_CERT_PATH_OR_JSON")

        # Ensure both database URL and credential info are available
        if not url_db or not cert:
            raise EnvironmentError(
                "Environment variables FIREBASE_DB_URL and FIREBASE_CERT_PATH_OR_JSON must be set"
            )

        # If the certificate parameter is a JSON string, parse it
        if cert.strip().startswith("{"):
            try:
                cert_dict = json.loads(cert)
            except json.JSONDecodeError as e:
                raise RuntimeError(f"Invalid credential JSON: {e}")
            try:
                # Load credentials directly from the parsed dictionary
                self._cred = credentials.Certificate(cert_dict)
            except Exception as e:
                raise RuntimeError(f"Failed to load credentials from dict: {e}")
        else:
            # Otherwise treat the certificate parameter as a file path
            try:
                self._cred = credentials.Certificate(cert)
            except Exception as e:
                raise RuntimeError(f"Failed to load credentials from file: {e}")

        # Store the database URL and initialize the app handle to None
        self._url_db = url_db
        self._app    = None

    def connect_db(self) -> None:
        """
        Initialize the Firebase app if not already initialized.
        Subsequent calls will reuse the existing app instance.
        """
        if not self._app:
            try:
                # Attempt to initialize a new Firebase app with the given credentials and URL
                self._app = firebase_admin.initialize_app(self._cred, {
                    'databaseURL': self._url_db
                })
            except ValueError:
                # App is already initialized in this process; retrieve the existing instance
                self._app = firebase_admin.get_app()
            except Exception as e:
                raise RuntimeError(f"Error connecting to Firebase: {e}")

    def add_data(self, db_ref: str, user_data: dict) -> None:
        """
        Write the provided user_data dictionary to the specified database reference path.
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            # Obtain a reference to the target node and set its value
            ref = db.reference(db_ref, app=self._app)
            ref.push(user_data)
            return {"message": "Data saved"}
        except Exception as e:
            raise RuntimeError(f"Failed to add data at '{db_ref}': {e}")

    def get_data(self, db_ref: str):
        """
        Read and return data from the specified database reference path.
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            # Obtain a reference to the target node and retrieve its value
            ref = db.reference(db_ref, app=self._app)
            return ref.get()
        except Exception as e:
            raise RuntimeError(f"Failed to read data at '{db_ref}': {e}")
        
    def update_data(self, db_ref: str, updates: dict) -> bool:
        """
        Atualiza dados no nó especificado.
        """
        if not self._app:
            raise RuntimeError("Database not connected. Call connect_db() first.")
        try:
            ref = db.reference(db_ref, app=self._app)
            ref.update(updates)
            return True
        except Exception as e:
            raise RuntimeError(f"Failed to update data at '{db_ref}': {e}")

    def close_connection(self) -> None:
        """
        Delete the Firebase app instance to free resources
        and allow for a fresh connection later.
        """
        if self._app:
            try:
                # Remove the app from the firebase_admin internal registry
                firebase_admin.delete_app(self._app)
                self._app = None
                return {"message": "Connection closed"}
            except Exception as e:
                raise RuntimeError(f"Error closing Firebase connection: {e}")
