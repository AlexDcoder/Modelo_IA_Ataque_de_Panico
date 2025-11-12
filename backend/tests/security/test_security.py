import pytest

class TestSecurity:
    """CT10 - Teste de segurança dos dados"""
    
    def test_ct10_unauthenticated_access(self, client):
        """CT10: Tentativa de acesso sem autenticação"""
        response = client.get("/users/me")
        assert response.status_code == 403  # Forbidden
        
    def test_ct10_access_other_user_data(self, client, unique_user_data, cleanup_user):
        """CT10: Tentativa de acessar dados de outro usuário"""
        # Criar primeiro usuário
        user1_response = client.post("/users/", json=unique_user_data)
        user1_data = user1_response.json()
        user1_uid = user1_data["uid"]
        
        # Obter token do primeiro usuário
        login1_response = client.post("/auth/login", json={
            "email": unique_user_data["email"],
            "password": unique_user_data["password"]
        })
        user1_token = login1_response.json()["access_token"]
        user1_headers = {"Authorization": f"Bearer {user1_token}"}
        
        # Registrar primeiro usuário para cleanup
        cleanup_user(user1_uid, user1_token)
        
        # Criar segundo usuário com dados diferentes
        user2_data = {
            "username": "user2_different",
            "email": "user2_different@example.com",
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        user2_response = client.post("/users/", json=user2_data)
        user2_uid = user2_response.json()["uid"]
        
        # Obter token do segundo usuário
        login2_response = client.post("/auth/login", json={
            "email": user2_data["email"],
            "password": user2_data["password"]
        })
        user2_token = login2_response.json()["access_token"]
        
        # Registrar segundo usuário para cleanup
        cleanup_user(user2_uid, user2_token)
        
        # Tentar acessar dados do user2 com token do user1 (DEVE FALHAR)
        response = client.get(f"/users/{user2_uid}", headers=user1_headers)
        assert response.status_code == 403  # Forbidden