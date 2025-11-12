import pytest
import uuid
from fastapi import status

class TestUserRegistration:
    """CT03 - Cadastro de usuário"""
    
    def test_user_registration(self, client, cleanup_user):
        """CT03: Cadastro de novo usuário"""
        unique_id = uuid.uuid4().hex[:8]
        test_user_data = {
            "username": f"testuser_{unique_id}",
            "email": f"test_{unique_id}@example.com",
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": [
                {
                    "name": "Emergency Contact",
                    "phone": "+5511999999999"
                }
            ]
        }
        
        response = client.post("/users/", json=test_user_data)
        assert response.status_code == 200
        data = response.json()
        
        # Registrar para cleanup
        login_response = client.post("/auth/login", json={
            "email": test_user_data["email"],
            "password": test_user_data["password"]
        })
        token = login_response.json()["access_token"]
        cleanup_user(data["uid"], token)

    # NOVOS TESTES DE ERRO
    def test_create_user_duplicate_email(self, client, test_user, cleanup_user):
        """ERRO: Criar usuário com email duplicado"""
        duplicate_user_data = {
            "username": "different_username",
            "email": test_user["email"],  # Email duplicado
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        response = client.post("/users/", json=duplicate_user_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "email already exists" in response.json()["detail"].lower()

    def test_create_user_duplicate_username(self, client, test_user, cleanup_user):
        """ERRO: Criar usuário com username duplicado"""
        duplicate_user_data = {
            "username": test_user["username"],  # Username duplicado
            "email": "different@example.com",
            "password": "testpassword123",
            "detection_time": "12:00:00",
            "emergency_contact": []
        }
        
        response = client.post("/users/", json=duplicate_user_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "username already exists" in response.json()["detail"].lower()

    def test_create_user_invalid_data(self, client):
        """ERRO: Criar usuário com dados inválidos"""
        invalid_user_data = {
            "username": "ab",  # Muito curto
            "email": "invalid-email",  # Email inválido
            "password": "123",  # Senha curta
            "detection_time": "25:00:00",  # Hora inválida
            "emergency_contact": []
        }
        
        response = client.post("/users/", json=invalid_user_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

class TestUserManagement:
    """Testes de gerenciamento de usuários"""
    
    def test_get_nonexistent_user(self, client, auth_headers):
        """ERRO: Buscar usuário inexistente"""
        response = client.get("/users/nonexistent_user_123", headers=auth_headers)
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_nonexistent_user(self, client, auth_headers):
        """ERRO: Atualizar usuário inexistente"""
        update_data = {"username": "newname"}
        response = client.put("/users/nonexistent_user_123", json=update_data, headers=auth_headers)
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_user_unauthorized(self, client, auth_headers):
        """ERRO: Atualizar outro usuário"""
        response = client.put("/users/other_user_123", json={"username": "hacker"}, headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_delete_nonexistent_user(self, client, auth_headers):
        """ERRO: Deletar usuário inexistente"""
        response = client.delete("/users/nonexistent_user_123", headers=auth_headers)
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_user_unauthorized(self, client, auth_headers):
        """ERRO: Deletar outro usuário"""
        response = client.delete("/users/other_user_123", headers=auth_headers)
        assert response.status_code == status.HTTP_403_FORBIDDEN