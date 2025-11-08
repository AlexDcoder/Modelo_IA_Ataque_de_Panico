import pytest
import asyncio
import os
import sys
from fastapi.testclient import TestClient

# Adicionar o diretório backend ao path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from backend.main import app
from core.dependencies import get_db_service, get_ai_service

# Configurar ambiente de teste
os.environ['ENV'] = 'test'

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
def test_client():
    """Create test client with overridden dependencies."""
    
    def override_get_db_service():
        class MockDBService:
            def __init__(self):
                self.users = {}
                self.vital_data = {}
                self.next_uid = 1
                
            def get_all_users(self): 
                return self.users
                
            def get_user(self, uid): 
                return self.users.get(uid)
                
            def create_user(self, uid, data): 
                if not uid:
                    uid = f"test-uid-{self.next_uid}"
                    self.next_uid += 1
                self.users[uid] = data
                return {"uid": uid, "message": "User created successfully"}
                
            def update_user(self, uid, data): 
                if uid in self.users:
                    self.users[uid].update(data)
                    return True
                return False
                
            def delete_user(self, uid): 
                if uid in self.users:
                    del self.users[uid]
                    if uid in self.vital_data:
                        del self.vital_data[uid]
                    return True
                return False
                
            def get_user_vital_data(self, uid): 
                return self.vital_data.get(uid)
                
            def set_vital(self, uid, data): 
                self.vital_data[uid] = data
                return True
                
            def update_vital(self, uid, data): 
                if uid in self.vital_data:
                    self.vital_data[uid].update(data)
                    return True
                return False
                
            def delete_vital(self, uid): 
                if uid in self.vital_data:
                    del self.vital_data[uid]
                    return True
                return False
                
            def close_connection(self): 
                pass
                
            def check_existing_user(self, email=None, username=None):
                email_exists = any(
                    user.get('email') == email 
                    for user in self.users.values() 
                    if email and user.get('email')
                )
                username_exists = any(
                    user.get('username') == username 
                    for user in self.users.values() 
                    if username and user.get('username')
                )
                return email_exists, username_exists
                
        return MockDBService()
    
    def override_get_ai_service():
        class MockAIService:
            def __init__(self):
                self.predictions = []
                self.feedbacks = []
                
            def predict(self, info): 
                # Lógica simples de predição baseada em múltiplos fatores
                heart_rate = info.get("heart_rate", 0)
                respiration_rate = info.get("respiration_rate", 0)
                stress_level = info.get("stress_level", 0)
                
                # Simula detecção de ataque de pânico
                result = (
                    heart_rate > 100 or 
                    respiration_rate > 22 or 
                    stress_level > 7
                )
                self.predictions.append((info, result))
                return result
                
            def set_feedback(self, features, label): 
                self.feedbacks.append((features, label))
                return True
                
        return MockAIService()
    
    app.dependency_overrides[get_db_service] = override_get_db_service
    app.dependency_overrides[get_ai_service] = override_get_ai_service
    
    with TestClient(app) as client:
        yield client
    
    # Clear overrides
    app.dependency_overrides.clear()

@pytest.fixture
def sample_user_data():
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "TestPassword123",
        "detection_time": "10:00:00",
        "emergency_contact": [
            {
                "name": "Emergency Contact 1",
                "phone": "+5511999999999"
            }
        ]
    }

@pytest.fixture
def sample_vital_data():
    return {
        "heart_rate": 80.0,
        "respiration_rate": 16.0,
        "accel_std": 0.5,
        "spo2": 98.0,
        "stress_level": 3.0
    }

@pytest.fixture
def auth_headers(test_client, sample_user_data):
    """Create a user and return auth headers"""
    try:
        # Create user
        response = test_client.post("/users/", json=sample_user_data)
        
        if response.status_code == 200:
            user_uid = response.json().get("uid")
        else:
            user_uid = "test-uid"
        
        # Login to get token
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        response = test_client.post("/auth/login", json=login_data)
        
        if response.status_code == 200:
            token = response.json()["access_token"]
            return {"Authorization": f"Bearer {token}"}
    except Exception:
        pass
    
    # Fallback para testes que não dependem de autenticação real
    return {"Authorization": "Bearer mock-test-token-12345"}