import pytest
from fastapi import status

class TestFeedback:
    """CT07: Testes específicos de feedback"""
    
    def test_feedback_success(self, test_client, auth_headers):
        """Test successful feedback submission"""
        feedback_data = {
            "uid": "test-uid",
            "features": {
                "heart_rate": 95.0,
                "respiration_rate": 20.0,
                "accel_std": 0.8,
                "spo2": 95.0,
                "stress_level": 6.0
            },
            "user_feedback": 0  # User says no panic attack
        }
        
        response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code in [200, 403]
        
        if response.status_code == 200:
            assert response.json()["status"] == "success"
    
    def test_feedback_different_scenarios(self, test_client, auth_headers):
        """Test feedback with different scenarios"""
        scenarios = [
            {
                "features": {
                    "heart_rate": 110.0,
                    "respiration_rate": 22.0,
                    "accel_std": 1.0,
                    "spo2": 90.0,
                    "stress_level": 7.0
                },
                "user_feedback": 1  # User confirms panic attack
            },
            {
                "features": {
                    "heart_rate": 85.0,
                    "respiration_rate": 18.0,
                    "accel_std": 0.6,
                    "spo2": 96.0,
                    "stress_level": 4.0
                },
                "user_feedback": 0  # User denies panic attack
            }
        ]
        
        for scenario in scenarios:
            feedback_data = {
                "uid": "test-uid",
                "features": scenario["features"],
                "user_feedback": scenario["user_feedback"]
            }
            
            response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
            assert response.status_code in [200, 403]
    
    @pytest.mark.integration
    def test_feedback_after_prediction(self, test_client, auth_headers):
        """Test complete flow: prediction → feedback"""
        # First, make a prediction
        vital_data = {
            "heart_rate": 100.0,
            "respiration_rate": 21.0,
            "accel_std": 0.9,
            "spo2": 93.0,
            "stress_level": 6.5
        }
        
        prediction_response = test_client.post(
            "/ai/predict", 
            json=vital_data, 
            headers=auth_headers
        )
        assert prediction_response.status_code == status.HTTP_200_OK
        
        # Then, provide feedback
        feedback_data = {
            "uid": "test-uid",
            "features": vital_data,
            "user_feedback": 1
        }
        
        feedback_response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert feedback_response.status_code in [200, 403]
    
    def test_feedback_invalid_uid(self, test_client, auth_headers):
        """Test feedback with invalid UID format"""
        feedback_data = {
            "uid": "",  # Empty UID
            "features": {
                "heart_rate": 95.0,
                "respiration_rate": 20.0,
                "accel_std": 0.8,
                "spo2": 95.0,
                "stress_level": 6.0
            },
            "user_feedback": 1
        }
        
        response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_feedback_invalid_user_feedback(self, test_client, auth_headers):
        """Test feedback with invalid user_feedback value"""
        feedback_data = {
            "uid": "test-uid",
            "features": {
                "heart_rate": 95.0,
                "respiration_rate": 20.0,
                "accel_std": 0.8,
                "spo2": 95.0,
                "stress_level": 6.0
            },
            "user_feedback": 5  # Invalid value (should be 0 or 1)
        }
        
        response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY