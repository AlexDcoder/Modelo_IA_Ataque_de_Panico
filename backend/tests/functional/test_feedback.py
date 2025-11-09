import pytest
from fastapi import status

class TestFeedback:
    """CT07 - Testes de feedback"""
    
    def test_submit_feedback(self, test_client, authenticated_user):
        """CT07: Feedback do usuário para IA"""
        if authenticated_user:
            feedback_data = {
                "uid": authenticated_user['uid'],
                "features": {
                    "heart_rate": 75.0,
                    "respiration_rate": 16.0,
                    "accel_std": 0.1,
                    "spo2": 98.0,
                    "stress_level": 3.0
                },
                "user_feedback": 1
            }
            
            response = test_client.post(
                "/feedback/",
                json=feedback_data,
                headers=authenticated_user["headers"]
            )
            
            assert response.status_code == status.HTTP_200_OK