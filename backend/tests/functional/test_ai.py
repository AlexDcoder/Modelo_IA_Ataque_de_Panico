import pytest

class TestAIDetection:
    """CT05 - Classificação de ataque de pânico"""
    
    def test_ct05_panic_detection(self, client, auth_headers, panic_vital_data):
        """CT05: Detecção de ataque de pânico pela IA"""
        response = client.post("/ai/predict", json=panic_vital_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "panic_attack_detected" in data
        assert isinstance(data["panic_attack_detected"], bool)