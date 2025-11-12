import pytest
import uuid

class TestUserRegistration:
    """CT03 - Cadastro de usuário"""
    
    def test_ct03_user_registration(self, client, unique_user_data, cleanup_user):
        """CT03: Cadastro de novo usuário"""
        response = client.post("/users/", json=unique_user_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == unique_user_data["username"]
        assert data["email"] == unique_user_data["email"]
        assert "uid" in data
        assert "password" not in data
        
        # Obter token para cleanup
        login_data = {
            "email": unique_user_data["email"],
            "password": unique_user_data["password"]
        }
        login_response = client.post("/auth/login", json=login_data)
        token = login_response.json()["access_token"]
        
        # Registrar para cleanup manual robusto
        cleanup_user(data["uid"], token)
    
    def test_multiple_users_cleanup(self, client, cleanup_user):
        """Teste que cria múltiplos usuários e verifica cleanup"""
        users_created = []
        
        # Criar 3 usuários de teste
        for i in range(3):
            unique_id = uuid.uuid4().hex[:8]
            user_data = {
                "username": f"multiuser_{i}_{unique_id}",
                "email": f"multi_{i}_{unique_id}@example.com",
                "password": "testpassword123",
                "detection_time": "12:00:00",
                "emergency_contact": []
            }
            
            response = client.post("/users/", json=user_data)
            assert response.status_code == 200
            
            user_info = response.json()
            uid = user_info["uid"]
            
            # Login para obter token
            login_response = client.post("/auth/login", json={
                "email": user_data["email"],
                "password": user_data["password"]
            })
            token = login_response.json()["access_token"]
            
            # Registrar cada usuário para cleanup
            cleanup_user(uid, token)
            users_created.append(uid)
        
        print(f"✅ Criados {len(users_created)} usuários para teste de cleanup múltiplo")
