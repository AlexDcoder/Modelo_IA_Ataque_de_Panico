import pytest
from fastapi import status

class TestVitalData:
    """CT04 - Testes de dados vitais"""
    
    def test_create_vital_data(self, test_client, authenticated_user, sample_vital_data):
        """CT04: Coleta de sinais fisiológicos"""
        if authenticated_user:
            response = test_client.post(
                f"/vital-data/{authenticated_user['uid']}", 
                json=sample_vital_data,
                headers=authenticated_user["headers"]
            )
            
            assert response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
    
    def test_get_vital_data(self, test_client, authenticated_user):
        """Buscar dados vitais do usuário"""
        if authenticated_user:
            response = test_client.get(
                f"/vital-data/{authenticated_user['uid']}",
                headers=authenticated_user["headers"]
            )
            
            # Pode retornar 200 (se existir) ou 404 (se não existir)
            assert response.status_code in [status.HTTP_200_OK, status.HTTP_404_NOT_FOUND]