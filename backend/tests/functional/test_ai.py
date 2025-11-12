import pytest
from fastapi import status

class TestAIFeedback:
    """CT07 - Feedback do usuário para IA"""
    
    def test_user_feedback(self, client, auth_headers, test_user, test_vital_data):
        """CT07: Usuário fornece feedback para melhorar IA"""
        uid = test_user["uid"]
        
        feedback_data = {
            "uid": uid,
            "features": test_vital_data,
            "user_feedback": 1
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == 200
        assert response.json()["status"] == "success"

    # NOVOS TESTES DE ERRO
    def test_feedback_unauthorized_user(self, client, auth_headers, test_vital_data):
        """ERRO: Feedback com UID não autorizado"""
        feedback_data = {
            "uid": "other_user_123",  # UID diferente do usuário autenticado
            "features": test_vital_data,
            "user_feedback": 1
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_feedback_with_invalid_features(self, client, auth_headers, test_user):
        """ERRO: Feedback com features inválidas"""
        feedback_data = {
            "uid": test_user["uid"],
            "features": {
                "heart_rate": "invalid"  # Tipo inválido
            },
            "user_feedback": 1
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_feedback_without_authentication(self, client, test_user, test_vital_data):
        """ERRO: Feedback sem autenticação"""
        feedback_data = {
            "uid": test_user["uid"],
            "features": test_vital_data,
            "user_feedback": 1
        }
        
        response = client.post("/feedback/", json=feedback_data)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_feedback_invalid_label(self, client, auth_headers, test_user, test_vital_data):
        """ERRO: Feedback com label inválido"""
        feedback_data = {
            "uid": test_user["uid"],
            "features": test_vital_data,
            "user_feedback": 3  # Label inválido (deve ser 0 ou 1)
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code in [status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY]