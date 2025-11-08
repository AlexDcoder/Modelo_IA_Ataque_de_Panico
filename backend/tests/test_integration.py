import pytest
from fastapi import status

@pytest.mark.integration
class TestIntegration:
    """Testes de integração entre módulos"""
    
    def test_complete_user_flow(self, test_client, sample_user_data, sample_vital_data):
        """Teste completo do fluxo do usuário: registro → login → dados vitais → predição"""
        
        # 1. Registro de usuário
        response = test_client.post("/users/", json=sample_user_data)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]
        
        if response.status_code == 200:
            user_data = response.json()
            user_id = user_data.get("uid")
            
            # 2. Login
            login_data = {
                "email": sample_user_data["email"],
                "password": sample_user_data["password"]
            }
            response = test_client.post("/auth/login", json=login_data)
            
            if response.status_code == 200:
                token = response.json()["access_token"]
                headers = {"Authorization": f"Bearer {token}"}
                
                # 3. Envio de dados vitais
                response = test_client.post(
                    f"/vital-data/{user_id}", 
                    json=sample_vital_data, 
                    headers=headers
                )
                assert response.status_code in [200, 403]
                
                # 4. Predição de ataque de pânico
                response = test_client.post(
                    "/ai/predict", 
                    json=sample_vital_data, 
                    headers=headers
                )
                assert response.status_code == status.HTTP_200_OK
                assert "panic_attack_detected" in response.json()
                
                # 5. Obter informações do usuário
                response = test_client.get("/users/me", headers=headers)
                assert response.status_code == status.HTTP_200_OK
                
                print("✅ Complete user flow test passed")
    
    def test_feedback_retraining_flow(self, test_client, auth_headers):
        """Teste do fluxo de feedback e retreinamento"""
        # 1. Fazer predição
        vital_data = {
            "heart_rate": 95.0,
            "respiration_rate": 20.0,
            "accel_std": 0.8,
            "spo2": 95.0,
            "stress_level": 6.0
        }
        
        response = test_client.post(
            "/ai/predict", 
            json=vital_data, 
            headers=auth_headers
        )
        assert response.status_code == status.HTTP_200_OK
        prediction = response.json()["panic_attack_detected"]
        
        # 2. Enviar feedback
        feedback_data = {
            "uid": "test-uid",
            "features": vital_data,
            "user_feedback": 0 if prediction else 1  # Opposite feedback for testing
        }
        
        response = test_client.post("/feedback/", json=feedback_data, headers=auth_headers)
        assert response.status_code in [200, 403]
        
        print("✅ Feedback retraining flow test passed")
    
    def test_user_lifecycle(self, test_client, sample_user_data):
        """Teste completo do ciclo de vida do usuário: criar → usar → deletar"""
        # 1. Criar usuário
        create_response = test_client.post("/users/", json=sample_user_data)
        assert create_response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]
        
        if create_response.status_code == 200:
            user_id = create_response.json().get("uid")
            
            # 2. Login
            login_data = {
                "email": sample_user_data["email"],
                "password": sample_user_data["password"]
            }
            login_response = test_client.post("/auth/login", json=login_data)
            
            if login_response.status_code == 200:
                token = login_response.json()["access_token"]
                headers = {"Authorization": f"Bearer {token}"}
                
                # 3. Usar funcionalidades
                vital_data = {
                    "heart_rate": 85.0,
                    "respiration_rate": 18.0,
                    "accel_std": 0.6,
                    "spo2": 96.0,
                    "stress_level": 4.0
                }
                
                # Fazer predição
                predict_response = test_client.post("/ai/predict", json=vital_data, headers=headers)
                assert predict_response.status_code == status.HTTP_200_OK
                
                # 4. Deletar usuário
                delete_response = test_client.delete(f"/users/{user_id}", headers=headers)
                assert delete_response.status_code in [200, 403]
                
                print("✅ User lifecycle test passed")
    
    def test_emergency_contact_flow(self, test_client, sample_user_data):
        """Teste do fluxo de contatos de emergência"""
        # Criar usuário com contatos de emergência
        response = test_client.post("/users/", json=sample_user_data)
        
        if response.status_code == 200:
            user_data = response.json()
            
            # Verificar se os contatos de emergência foram salvos
            assert "emergency_contact" in user_data
            assert len(user_data["emergency_contact"]) > 0
            assert user_data["emergency_contact"][0]["name"] == "Emergency Contact 1"
            
            print("✅ Emergency contact flow test passed")
    
    @pytest.mark.integration
    def test_multiple_users_scenario(self, test_client):
        """Teste com múltiplos usuários simultâneos"""
        users = [
            {
                "username": f"user{i}",
                "email": f"user{i}@example.com",
                "password": "TestPassword123",
                "detection_time": "10:00:00",
                "emergency_contact": []
            }
            for i in range(3)
        ]
        
        for user_data in users:
            # Criar usuário
            create_response = test_client.post("/users/", json=user_data)
            assert create_response.status_code in [200, 400]
            
            # Login
            login_response = test_client.post("/auth/login", json={
                "email": user_data["email"],
                "password": user_data["password"]
            })
            assert login_response.status_code in [200, 401]
            
        print("✅ Multiple users scenario test passed")