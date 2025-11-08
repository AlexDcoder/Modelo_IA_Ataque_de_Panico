import pytest
import asyncio
import os
import sys
from fastapi.testclient import TestClient

# Add the parent directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.dependencies import get_db_service, get_ai_service

# Set test environment
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
    
    # Override dependencies for testing
    def override_get_db_service():
        from core.db.connector import RTDBConnector
        from core.services.db_service import DBService
        try:
            connector = RTDBConnector()
            return DBService(connector)
        except Exception:
            # Return mock service if Firebase not available
            class MockDBService:
                def get_all_users(self): return {}
                def get_user(self, uid): return None
                def create_user(self, uid, data): return {"uid": "test-uid"}
                def update_user(self, uid, data): return True
                def delete_user(self, uid): return True
                def get_user_vital_data(self, uid): return None
                def set_vital(self, uid, data): return True
                def update_vital(self, uid, data): return True
                def delete_vital(self, uid): return True
                def close_connection(self): pass
                def check_existing_user(self, email=None, username=None): return False, False
            return MockDBService()
    
    def override_get_ai_service():
        from core.services.ai_service import AIService
        try:
            return AIService()
        except Exception:
            # Return mock service if data file not available
            class MockAIService:
                def predict(self, info): return False
                def set_feedback(self, features, label): return True
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
        
        # Login to get token
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        response = test_client.post("/auth/login", json=login_data)
        
        if response.status_code == 200:
            token = response.json()["access_token"]
            return {"Authorization": f"Bearer {token}"}
        else:
            # Return mock headers if login fails
            return {"Authorization": "Bearer mock-token-for-testing"}
    except Exception:
        # Return mock headers if any error occurs
        return {"Authorization": "Bearer mock-token-for-testing"}