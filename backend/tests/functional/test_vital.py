import pytest
from fastapi import status

class TestVitalData:
    """CT04 - Coleta de sinais fisiológicos"""
    
    def test_vital_data_collection(self, client, test_user, auth_headers, test_vital_data):
        """CT04: Coleta e armazenamento de dados vitais"""
        uid = test_user["uid"]
        
        response = client.post(f"/vital-data/{uid}", json=test_vital_data, headers=auth_headers)
        assert response.status_code == 200
        assert "successfully" in response.json()["message"]
        
        vital_response = client.get(f"/vital-data/{uid}", headers=auth_headers)
        assert vital_response.status_code == 200
        saved_data = vital_response.json()
        assert saved_data["heart_rate"] == test_vital_data["heart_rate"]

    # NOVOS TESTES DE ERRO
    def test_get_vital_data_nonexistent(self, client, auth_headers, test_user):
        """ERRO: Buscar dados vitais inexistentes"""
        response = client.get(f"/vital-data/{test_user['uid']}", headers=auth_headers)
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_get_vital_data_unauthorized(self, client, auth_headers):
        """ERRO: Buscar dados vitais de outro usuário"""
        response = client.get("/vital-data/other_user_123", headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_create_vital_data_unauthorized(self, client, auth_headers, test_vital_data):
        """ERRO: Criar dados vitais para outro usuário"""
        response = client.post("/vital-data/other_user_123", json=test_vital_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_create_vital_data_invalid_values(self, client, auth_headers, test_user):
        """ERRO: Criar dados vitais com valores inválidos"""
        invalid_vital_data = {
            "heart_rate": -10,  # Valor negativo
            "respiration_rate": 0,
            "accel_std": -1.0,
            "spo2": 150.0,  # Acima de 100%
            "stress_level": -5.0
        }
        
        response = client.post(f"/vital-data/{test_user['uid']}", json=invalid_vital_data, headers=auth_headers)
        assert response.status_code in [status.HTTP_400_BAD_REQUEST, status.HTTP_422_UNPROCESSABLE_ENTITY]

    def test_update_vital_data_nonexistent(self, client, auth_headers, test_user, test_vital_data):
        """ERRO: Atualizar dados vitais inexistentes"""
        response = client.put(f"/vital-data/{test_user['uid']}", json=test_vital_data, headers=auth_headers)
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_vital_data_unauthorized(self, client, auth_headers, test_vital_data):
        """ERRO: Atualizar dados vitais de outro usuário"""
        response = client.put("/vital-data/other_user_123", json=test_vital_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN