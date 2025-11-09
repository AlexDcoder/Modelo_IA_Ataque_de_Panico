import pytest
from fastapi import status

class TestSecurity:
    """CT10 - Testes de segurança"""
    
    def test_access_protected_route_without_token(self, test_client):
        """Acesso negado sem token JWT"""
        response = test_client.get("/users/me")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_access_with_invalid_token(self, test_client):
        """Acesso negado com token inválido"""
        headers = {"Authorization": "Bearer invalid_token"}
        response = test_client.get("/users/me", headers=headers)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_user_cannot_access_other_user_data(self, test_client, authenticated_user):
        """Usuário não pode acessar dados de outro usuário"""
        if authenticated_user:
            response = test_client.get("/vital-data/other_user_id", headers=authenticated_user["headers"])
            assert response.status_code == status.HTTP_403_FORBIDDEN