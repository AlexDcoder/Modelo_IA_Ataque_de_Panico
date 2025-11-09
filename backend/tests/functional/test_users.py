import pytest
from fastapi import status
from unittest.mock import patch

class TestUsers:
    """CT03 - Testes de gestão de usuários"""
    
    def test_create_user_success(self, test_client, mock_db_service, sample_user_data):
        """CT03: Cadastro de novo usuário bem-sucedido"""
        # Configurar mock para retornar que não existe usuário com mesmo email/username
        mock_db_service.check_existing_user.return_value = (False, False)
        
        response = test_client.post("/users/", json=sample_user_data)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.json()["email"] == sample_user_data["email"]
        assert "password" not in response.json()
    
    def test_create_user_duplicate_email(self, test_client, mock_db_service, sample_user_data):
        """Testar criação de usuário com email duplicado"""
        # Primeiro criar um usuário com o mesmo email
        mock_db_service.check_existing_user.return_value = (False, False)
        first_response = test_client.post("/users/", json=sample_user_data)
        assert first_response.status_code == status.HTTP_200_OK
        
        # Agora tentar criar outro usuário com o mesmo email
        # O mock deve retornar que o email já existe
        mock_db_service.check_existing_user.return_value = (True, False)
        
        second_user_data = sample_user_data.copy()
        second_user_data["username"] = "differentuser"
        
        response = test_client.post("/users/", json=second_user_data)
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "email already exists" in response.json()["detail"].lower()
    
    def test_get_user_profile_authenticated(self, test_client, authenticated_user):
        """Buscar perfil do usuário autenticado via /me"""
        if authenticated_user:
            response = test_client.get("/users/me", headers=authenticated_user["headers"])
            assert response.status_code == status.HTTP_200_OK
            assert "email" in response.json()
            assert "username" in response.json()
            assert "uid" in response.json()
            assert "password" not in response.json()  # Senha não deve ser exposta
    
    def test_get_me_unauthenticated(self, test_client):
        """Tentar acessar /me sem autenticação"""
        response = test_client.get("/users/me")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_me_returns_correct_user_data(self, test_client, authenticated_user, mock_db_service):
        """Verificar se /me retorna os dados corretos do usuário"""
        if authenticated_user:
            # Configurar mock para retornar dados específicos
            user_data = {
                "username": "testuser",
                "email": "test@example.com", 
                "detection_time": "12:00:00",
                "emergency_contact": [
                    {
                        "name": "Emergency Contact",
                        "phone": "+1234567890"
                    }
                ]
            }
            mock_db_service.get_user.return_value = user_data
            
            response = test_client.get("/users/me", headers=authenticated_user["headers"])
            
            assert response.status_code == status.HTTP_200_OK
            assert response.json()["uid"] == authenticated_user["uid"]
            assert response.json()["username"] == user_data["username"]
            assert response.json()["email"] == user_data["email"]
    
    def test_update_user_via_me_not_allowed(self, test_client, authenticated_user):
        """Verificar que não é possível atualizar usuário via /me - CORRIGIDO"""
        if authenticated_user:
            update_data = {"username": "newname"}
            response = test_client.put("/users/me", json=update_data, headers=authenticated_user["headers"])
            # A rota /me não aceita PUT - pode retornar 403, 404 ou 405
            assert response.status_code in [
                status.HTTP_403_FORBIDDEN, 
                status.HTTP_404_NOT_FOUND, 
                status.HTTP_405_METHOD_NOT_ALLOWED
            ]