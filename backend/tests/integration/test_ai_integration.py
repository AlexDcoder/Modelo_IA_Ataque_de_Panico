import pytest
from fastapi import status

class TestAIIntegration:
    """Testes de integração da IA"""
    
    def test_complete_prediction_flow(self, test_client, authenticated_user):
        """Fluxo completo: dados vitais → predição → feedback"""
        if authenticated_user:
            # Dados vitais
            vital_data = {
                "heart_rate": 85.0,
                "respiration_rate": 20.0,
                "accel_std": 0.3,
                "spo2": 95.0,
                "stress_level": 7.0
            }
            
            # Predição
            prediction_response = test_client.post(
                "/ai/predict",
                json=vital_data,
                headers=authenticated_user["headers"]
            )
            assert prediction_response.status_code == status.HTTP_200_OK
            
            # Feedback
            feedback_data = {
                "uid": authenticated_user['uid'],
                "features": vital_data,
                "user_feedback": 1
            }
            
            feedback_response = test_client.post(
                "/feedback/",
                json=feedback_data,
                headers=authenticated_user["headers"]
            )
            assert feedback_response.status_code == status.HTTP_200_OK