import pytest
from fastapi import status

class TestCompleteWorkflows:
    """Testes de integração - fluxos completos"""
    
    def test_complete_user_journey(self, client, test_user, auth_headers, test_vital_data):
        """Fluxo completo: Cadastro → Login → Monitoramento → Detecção → Feedback"""
        uid = test_user["uid"]
        
        vital_response = client.post(f"/vital-data/{uid}", json=test_vital_data, headers=auth_headers)
        assert vital_response.status_code == 200
        
        prediction_response = client.post("/ai/predict", json=test_vital_data, headers=auth_headers)
        assert prediction_response.status_code == 200
        prediction = prediction_response.json()
        
        feedback_data = {
            "uid": uid,
            "features": test_vital_data,
            "user_feedback": 1 if prediction.get("panic_attack_detected", False) else 0
        }
        feedback_response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert feedback_response.status_code == 200
        
        user_response = client.get(f"/users/{uid}", headers=auth_headers)
        assert user_response.status_code == 200
        
        vital_check = client.get(f"/vital-data/{uid}", headers=auth_headers)
        assert vital_check.status_code == 200

    # NOVOS TESTES DE ERRO - FLUXOS COM FALHA
    def test_workflow_with_invalid_credentials(self, client):
        """ERRO: Fluxo completo com credenciais inválidas"""
        # Tentar acessar endpoints sem autenticação
        response = client.get("/users/me")
        assert response.status_code == status.HTTP_403_FORBIDDEN
        
        response = client.post("/ai/predict", json={})
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_workflow_with_nonexistent_user(self, client, auth_headers, test_vital_data):
        """ERRO: Fluxo com usuário inexistente"""
        # Tentar operações com usuário que não existe
        response = client.get("/users/nonexistent_123", headers=auth_headers)
        assert response.status_code in [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND]
        
        response = client.post("/vital-data/nonexistent_123", json=test_vital_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_feedback_workflow_with_unauthorized_user(self, client, auth_headers, test_vital_data):
        """ERRO: Fluxo de feedback com usuário não autorizado"""
        feedback_data = {
            "uid": "unauthorized_user_123",
            "features": test_vital_data,
            "user_feedback": 1
        }
        
        response = client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN