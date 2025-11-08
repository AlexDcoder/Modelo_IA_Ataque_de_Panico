import pytest
from fastapi import status

class TestAIModel:
    """CT05, CT07, CT11: Testes de IA"""
    
    def test_panic_attack_prediction(self, test_client, auth_headers, sample_vital_data):
        """CT05: Classificação de ataque de pânico"""
        response = test_client.post(
            "/ai/predict", 
            json=sample_vital_data, 
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        assert "panic_attack_detected" in response.json()
        assert isinstance(response.json()["panic_attack_detected"], bool)
    
    def test_panic_attack_prediction_unauthorized(self, test_client, sample_vital_data):
        """Test prediction without authentication"""
        response = test_client.post("/ai/predict", json=sample_vital_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_feedback_mechanism(self, test_client, auth_headers):
        """CT07, CT11: Feedback do usuário e reaprendizado da IA"""
        feedback_data = {
            "uid": "test-uid",
            "features": {
                "heart_rate": 85.0,
                "respiration_rate": 18.0,
                "accel_std": 0.7,
                "spo2": 96.0,
                "stress_level": 5.0
            },
            "user_feedback": 1
        }
        
        response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        
        assert response.status_code in [200, 403]
    
    def test_feedback_validation(self, test_client, auth_headers):
        """Test feedback data validation"""
        invalid_feedback = {
            "uid": "test-uid",
            "features": {
                "heart_rate": "invalid",  # Should be number
                "respiration_rate": 18.0,
                "accel_std": 0.7,
                "spo2": 96.0,
                "stress_level": 5.0
            },
            "user_feedback": 1
        }
        
        response = test_client.post("/feedback/", json=invalid_feedback, headers=auth_headers)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_feedback_unauthorized(self, test_client):
        """Test feedback without authentication"""
        feedback_data = {
            "uid": "test-uid",
            "features": {
                "heart_rate": 85.0,
                "respiration_rate": 18.0,
                "accel_std": 0.7,
                "spo2": 96.0,
                "stress_level": 5.0
            },
            "user_feedback": 1
        }
        
        response = test_client.post("/feedback/", json=feedback_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @pytest.mark.ai
    def test_prediction_with_different_data(self, test_client, auth_headers):
        """Test prediction with various vital data patterns"""
        test_cases = [
            {
                "heart_rate": 120.0,  # High heart rate - possible panic
                "respiration_rate": 25.0,
                "accel_std": 1.2,
                "spo2": 92.0,
                "stress_level": 8.0
            },
            {
                "heart_rate": 75.0,  # Normal vitals - no panic
                "respiration_rate": 15.0,
                "accel_std": 0.3,
                "spo2": 99.0,
                "stress_level": 2.0
            }
        ]
        
        for vital_data in test_cases:
            response = test_client.post(
                "/ai/predict", 
                json=vital_data, 
                headers=auth_headers
            )
            assert response.status_code == status.HTTP_200_OK
            assert "panic_attack_detected" in response.json()