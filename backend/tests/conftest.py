import pytest
import asyncio
import sys
import os
from pathlib import Path
from unittest.mock import Mock, patch
from fastapi.testclient import TestClient

# Adicionar o diretório raiz ao Python path
root_dir = Path(__file__).parent.parent
sys.path.insert(0, str(root_dir))

from main import app
from core.dependencies import get_db_service, get_ai_service
from core.security.password import hash_password

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def mock_db_service():
    """Mock do DBService para testes"""
    mock = Mock()
    
    # Simular banco em memória
    users_db = {}
    vital_db = {}
    
    # Mock dos métodos do DBService
    def get_all_users():
        return users_db
    mock.get_all_users.side_effect = get_all_users
    
    def get_user(uid):
        return users_db.get(uid)
    mock.get_user.side_effect = get_user
    
    def create_user(uid, user_data):
        if uid is None:
            uid = "generated_uid_123"
        users_db[uid] = user_data
        return {"uid": uid, "message": "User created successfully"}
    mock.create_user.side_effect = create_user
    
    def update_user(uid, user_data):
        if uid in users_db:
            users_db[uid].update(user_data)
            return True
        return False
    mock.update_user.side_effect = update_user
    
    def delete_user(uid):
        if uid in users_db:
            del users_db[uid]
            return True
        return False
    mock.delete_user.side_effect = delete_user
    
    def get_user_vital_data(uid):
        return vital_db.get(uid)
    mock.get_user_vital_data.side_effect = get_user_vital_data
    
    def set_vital(uid, data):
        vital_db[uid] = data
        return {"message": "Vital data set successfully"}
    mock.set_vital.side_effect = set_vital
    
    def update_vital(uid, data):
        if uid in vital_db:
            vital_db[uid].update(data)
            return True
        return False
    mock.update_vital.side_effect = update_vital
    
    def delete_vital(uid):
        if uid in vital_db:
            del vital_db[uid]
            return True
        return False
    mock.delete_vital.side_effect = delete_vital
    
    def check_existing_user(email=None, username=None):
        email_exists = any(user.get('email') == email for user in users_db.values())
        username_exists = any(user.get('username') == username for user in users_db.values())
        return email_exists, username_exists
    mock.check_existing_user.side_effect = check_existing_user
    
    mock.close_connection.return_value = None
    
    return mock

@pytest.fixture
def mock_ai_service():
    """Mock do AIService para testes"""
    mock = Mock()
    mock.predict.return_value = False
    mock.set_feedback.return_value = None
    return mock

@pytest.fixture
def test_client(mock_db_service, mock_ai_service):
    """Client de teste com mocks injetados"""
    # Sobrescrever as dependências com mocks
    app.dependency_overrides[get_db_service] = lambda: mock_db_service
    app.dependency_overrides[get_ai_service] = lambda: mock_ai_service
    
    with TestClient(app) as client:
        yield client
    
    # Limpar sobrescritas após o teste
    app.dependency_overrides.clear()

@pytest.fixture
def sample_user_data():
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "Test1234",
        "detection_time": "12:00:00",
        "emergency_contact": [
            {
                "name": "Emergency Contact",
                "phone": "+1234567890"
            }
        ]
    }

@pytest.fixture
def sample_vital_data():
    return {
        "heart_rate": 75.0,
        "respiration_rate": 16.0,
        "accel_std": 0.1,
        "spo2": 98.0,
        "stress_level": 3.0
    }

@pytest.fixture
def authenticated_user(test_client, mock_db_service, sample_user_data):
    """Cria um usuário autenticado para testes"""
    # Criar usuário no mock
    user_data = sample_user_data.copy()
    user_data['password'] = hash_password(user_data['password'])
    user_id = "test_user_123"
    mock_db_service.create_user(user_id, user_data)
    
    # Mock da verificação de senha para retornar True
    with patch('core.routes.auth.verify_password', return_value=True):
        # Fazer login para obter token
        response = test_client.post("/auth/login", json={
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        })
    
    if response.status_code == 200:
        token = response.json()["access_token"]
        return {
            "uid": user_id,
            "headers": {"Authorization": f"Bearer {token}"},
            "user_data": user_data
        }
    return None