import pytest
from fastapi import status

class TestAuthentication:
    """CT01 e CT02 - Testes de autenticação"""
    
    def test_valid_login(self, client, test_user):
        """CT01: Login de usuário válido"""
        login_data = {
            "email": test_user["email"],
            "password": test_user["password"]
        }
        login_response = client.post("/auth/login", json=login_data)
        
        assert login_response.status_code == 200
        data = login_response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_invalid_login(self, client):
        """CT02: Login de usuário inválido"""
        login_data = {
            "email": "invalid@example.com",
            "password": "wrongpassword"
        }
        response = client.post("/auth/login", json=login_data)
        
        assert response.status_code == 401
        assert "Invalid credentials" in response.json()["detail"]

    # NOVOS TESTES DE ERRO
    def test_login_user_not_found(self, client):
        """ERRO: Login com usuário inexistente"""
        login_data = {
            "email": "nonexistent@example.com",
            "password": "anypassword"
        }
        response = client.post("/auth/login", json=login_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_login_wrong_password(self, client, test_user):
        """ERRO: Login com senha incorreta"""
        login_data = {
            "email": test_user["email"],
            "password": "wrongpassword123"
        }
        response = client.post("/auth/login", json=login_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_access_protected_route_without_token(self, client):
        """ERRO: Acesso sem autenticação"""
        response = client.get("/users/me")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_access_protected_route_with_invalid_token(self, client):
        """ERRO: Acesso com token inválido"""
        headers = {"Authorization": "Bearer invalid_token_123"}
        response = client.get("/users/me", headers=headers)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_refresh_token_invalid(self, client):
        """ERRO: Refresh token inválido"""
        refresh_data = {"refresh_token": "invalid_refresh_token"}
        response = client.post("/auth/refresh", json=refresh_data)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED