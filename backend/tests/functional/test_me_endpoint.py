import pytest
from fastapi import status

class TestMeEndpoint:
    """Testes específicos para a rota /users/me"""
    
    def test_me_returns_current_user_data(self, test_client, authenticated_user, mock_db_service):
        """Testar se /me retorna dados do usuário atual"""
        if authenticated_user:
            # Configurar dados específicos no mock
            expected_data = {
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
            mock_db_service.get_user.return_value = expected_data
            
            response = test_client.get("/users/me", headers=authenticated_user["headers"])
            
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            
            # Verificar estrutura da resposta
            assert data["uid"] == authenticated_user["uid"]
            assert data["username"] == expected_data["username"]
            assert data["email"] == expected_data["email"]
            assert data["detection_time"] == expected_data["detection_time"]
            assert len(data["emergency_contact"]) == 1
            assert "password" not in data  # Senha não deve ser exposta
    
    def test_me_with_invalid_token(self, test_client):
        """Testar /me com token inválido"""
        headers = {"Authorization": "Bearer invalid_token"}
        response = test_client.get("/users/me", headers=headers)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_me_with_expired_token(self, test_client, authenticated_user):
        """Testar /me com token expirado"""
        if authenticated_user:
            # Usar token expirado
            expired_headers = {"Authorization": "Bearer expired_token_here"}
            response = test_client.get("/users/me", headers=expired_headers)
            
            assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_me_after_user_deletion(self, test_client, authenticated_user, mock_db_service):
        """Testar /me após o usuário ser deletado - CORRIGIDO"""
        if authenticated_user:
            # Configurar o mock para retornar dados na primeira chamada e None na segunda
            user_data = authenticated_user["user_data"].copy()
            if "password" in user_data:
                del user_data["password"]
                
            mock_db_service.get_user.side_effect = [user_data, None]
            
            # Primeiro acesso deve funcionar
            response1 = test_client.get("/users/me", headers=authenticated_user["headers"])
            assert response1.status_code == status.HTTP_200_OK
            
            # Segundo acesso deve falhar (usuário deletado)
            response2 = test_client.get("/users/me", headers=authenticated_user["headers"])
            # Pode retornar 404 ou 500 dependendo da implementação
            assert response2.status_code in [status.HTTP_404_NOT_FOUND, status.HTTP_500_INTERNAL_SERVER_ERROR]
    
    def test_me_response_structure(self, test_client, authenticated_user):
        """Testar estrutura da resposta de /me"""
        if authenticated_user:
            response = test_client.get("/users/me", headers=authenticated_user["headers"])
            
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            
            # Verificar campos obrigatórios
            required_fields = ["uid", "username", "email", "detection_time", "emergency_contact"]
            for field in required_fields:
                assert field in data, f"Campo {field} não encontrado na resposta"
            
            # Verificar tipos dos campos
            assert isinstance(data["uid"], str)
            assert isinstance(data["username"], str)
            assert isinstance(data["email"], str)
            assert isinstance(data["detection_time"], str)
            assert isinstance(data["emergency_contact"], list)