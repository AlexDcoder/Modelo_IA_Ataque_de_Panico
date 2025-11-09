import pytest
from pydantic import ValidationError
from core.schemas.dto.user_dto import UserCreateDTO, UserUpdateDTO, UserLoginDTO
from core.schemas.user import UserVitalData
from core.schemas.feedback import FeedbackInput

class TestUserModels:
    """Testes unitários para modelos de usuário"""
    
    def test_user_create_dto_valid(self):
        """Testar criação de UserCreateDTO válido"""
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "ValidPass123",
            "detection_time": "12:00:00",
            "emergency_contact": [
                {
                    "name": "Emergency Contact",
                    "phone": "+1234567890"
                }
            ]
        }
        
        user = UserCreateDTO(**user_data)
        
        assert user.username == "testuser"
        assert user.email == "test@example.com"
        assert user.password == "ValidPass123"
        assert user.detection_time == "12:00:00"
        assert len(user.emergency_contact) == 1
    
    def test_user_create_dto_invalid_password(self):
        """Testar UserCreateDTO com senha inválida"""
        user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "short",  # Senha muito curta
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        with pytest.raises(ValidationError):
            UserCreateDTO(**user_data)
    
    def test_user_create_dto_invalid_email(self):
        """Testar UserCreateDTO com email inválido"""
        user_data = {
            "username": "testuser",
            "email": "invalid-email",
            "password": "ValidPass123",
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        with pytest.raises(ValidationError):
            UserCreateDTO(**user_data)
    
    def test_user_update_dto_partial(self):
        """Testar UserUpdateDTO com atualização parcial"""
        update_data = {
            "username": "newusername"
        }
        
        user = UserUpdateDTO(**update_data)
        
        assert user.username == "newusername"
        assert user.email is None
        assert user.password is None
    
    def test_user_vital_data_valid(self):
        """Testar UserVitalData válido"""
        vital_data = {
            "heart_rate": 75.0,
            "respiration_rate": 16.0,
            "accel_std": 0.1,
            "spo2": 98.0,
            "stress_level": 3.0
        }
        
        vital = UserVitalData(**vital_data)
        
        assert vital.heart_rate == 75.0
        assert vital.respiration_rate == 16.0
        assert vital.accel_std == 0.1
        assert vital.spo2 == 98.0
        assert vital.stress_level == 3.0
    
    def test_feedback_input_valid(self):
        """Testar FeedbackInput válido"""
        feedback_data = {
            "uid": "test_user",
            "features": {
                "heart_rate": 75.0,
                "respiration_rate": 16.0
            },
            "user_feedback": 1
        }
        
        feedback = FeedbackInput(**feedback_data)
        
        assert feedback.uid == "test_user"
        assert feedback.features["heart_rate"] == 75.0
        assert feedback.user_feedback == 1