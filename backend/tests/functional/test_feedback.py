import pytest

class TestAIFeedback:
    """CT07 - Feedback do usuário para IA"""
    
    def test_user_feedback(self, client, test_user, auth_headers, test_vital_data):
        """CT07: Usuário fornece feedback para melhorar IA - UM usuário"""
        uid = test_user["uid"]
        
        feedback_data = {
            "uid": uid,
            "features": test_vital_data,
            "user_feedback": 1  # 1 = confirmou ataque, 0 = negou
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        
        assert response.status_code == 200
        assert response.json()["status"] == "success"