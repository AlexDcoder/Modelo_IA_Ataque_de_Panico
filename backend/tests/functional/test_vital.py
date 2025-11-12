import pytest

class TestVitalData:
    """CT04 - Coleta de sinais fisiológicos"""
    
    def test_ct04_vital_data_collection(self, client, auth_headers, test_user, test_vital_data):
        """CT04: Coleta e armazenamento de dados vitais"""
        # Usar UID do usuário de teste
        uid = test_user["uid"]
        
        # Enviar dados vitais
        response = client.post(f"/vital-data/{uid}", json=test_vital_data, headers=auth_headers)
        
        assert response.status_code == 200
        assert "successfully" in response.json()["message"]
        
        # Verificar se dados foram salvos
        vital_response = client.get(f"/vital-data/{uid}", headers=auth_headers)
        assert vital_response.status_code == 200
        saved_data = vital_response.json()
        assert saved_data["heart_rate"] == test_vital_data["heart_rate"]
        # O cleanup é automático via fixture test_user