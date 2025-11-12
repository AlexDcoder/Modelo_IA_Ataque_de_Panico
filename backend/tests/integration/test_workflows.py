import pytest
import uuid

class TestCompleteWorkflows:
    """Testes de integração - fluxos completos"""
    
    def test_complete_user_journey(self, client, cleanup_user):
        """Fluxo completo: Cadastro → Login → Monitoramento → Detecção → Feedback"""
        # Gerar dados únicos
        unique_id = uuid.uuid4().hex[:8]
        test_user_data = {
            "username": f"workflow_{unique_id}",
            "email": f"workflow_{unique_id}@example.com",
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": [
                {
                    "name": "Workflow Contact",
                    "phone": "+5511888888888"
                }
            ]
        }
        
        test_vital_data = {
            "heart_rate": 85.0,
            "respiration_rate": 18.0,
            "accel_std": 1.2,
            "spo2": 95.0,
            "stress_level": 5.0
        }
        
        # CT03: Cadastro
        register_response = client.post("/users/", json=test_user_data)
        assert register_response.status_code == 200
        user_data = register_response.json()
        uid = user_data["uid"]
        
        # CT01: Login
        login_response = client.post("/auth/login", json={
            "email": test_user_data["email"],
            "password": test_user_data["password"]
        })
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Registrar para cleanup manual robusto
        cleanup_user(uid, token)
        
        # CT04: Coleta de dados vitais
        vital_response = client.post(f"/vital-data/{uid}", json=test_vital_data, headers=headers)
        assert vital_response.status_code == 200
        
        # CT05: Predição
        prediction_response = client.post("/ai/predict", json=test_vital_data, headers=headers)
        assert prediction_response.status_code == 200
        prediction = prediction_response.json()
        
        # CT07: Feedback
        feedback_data = {
            "uid": uid,
            "features": test_vital_data,
            "user_feedback": 1 if prediction.get("panic_attack_detected", False) else 0
        }
        feedback_response = client.post("/feedback/", json=feedback_data, headers=headers)
        assert feedback_response.status_code == 200
        
        # Verificar estado final
        user_response = client.get(f"/users/{uid}", headers=headers)
        assert user_response.status_code == 200
        
        vital_check = client.get(f"/vital-data/{uid}", headers=headers)
        assert vital_check.status_code == 200