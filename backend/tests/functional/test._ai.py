import pytest
from fastapi import status

class TestAIPredictions:
    """CT05, CT11 - Testes de IA e reaprendizado"""
    
    def test_panic_attack_prediction(self, test_client, authenticated_user, sample_vital_data):
        """CT05: Classificação de ataque de pânico"""
        if authenticated_user:
            response = test_client.post(
                "/ai/predict",
                json=sample_vital_data,
                headers=authenticated_user["headers"]
            )
            
            assert response.status_code == status.HTTP_200_OK
            assert "panic_attack_detected" in response.json()
    
    def test_prediction_with_invalid_data(self, test_client, authenticated_user):
        """Testar predição com dados inválidos"""
        if authenticated_user:
            invalid_data = {"invalid": "data"}
            
            response = test_client.post(
                "/ai/predict",
                json=invalid_data,
                headers=authenticated_user["headers"]
            )
            
            assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY