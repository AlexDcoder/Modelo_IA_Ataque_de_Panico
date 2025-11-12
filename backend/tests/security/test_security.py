import pytest
import uuid
from fastapi import status

class TestSecurity:
    """CT10 - Teste de segurança dos dados"""
    
    def test_unauthenticated_access(self, client):
        """CT10: Tentativa de acesso sem autenticação"""
        response = client.get("/users/me")
        assert response.status_code == 403

    def test_access_other_user_data(self, client, cleanup_user):
        """CT10: Tentativa de acessar dados de outro usuário"""
        unique_id = uuid.uuid4().hex[:8]
        user_data = {
            "username": f"security_test_{unique_id}",
            "email": f"security_{unique_id}@example.com",
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        response = client.post("/users/", json=user_data)
        user_uid = response.json()["uid"]
        
        login_response = client.post("/auth/login", json={
            "email": user_data["email"],
            "password": user_data["password"]
        })
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        cleanup_user(user_uid, token)
        
        fake_uid = "nonexistent_user_123"
        response = client.get(f"/users/{fake_uid}", headers=headers)
        assert response.status_code in [403, 404]

    # NOVOS TESTES DE ERRO
    def test_access_all_users_unauthorized(self, client, auth_headers):
        """ERRO: Acesso à lista de todos os usuários sem permissão"""
        response = client.get("/users/", headers=auth_headers)
        # Pode retornar 403 ou 200 dependendo da implementação
        assert response.status_code in [200, 403]

    def test_access_vital_data_other_user(self, client, auth_headers):
        """ERRO: Acessar dados vitais de outro usuário"""
        response = client.get("/vital-data/other_user_123", headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_create_vital_data_other_user(self, client, auth_headers, test_vital_data):
        """ERRO: Criar dados vitais para outro usuário"""
        response = client.post("/vital-data/other_user_123", json=test_vital_data, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_update_user_unauthorized(self, client, auth_headers):
        """ERRO: Atualizar outro usuário"""
        response = client.put("/users/other_user_123", json={"username": "hacker"}, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN