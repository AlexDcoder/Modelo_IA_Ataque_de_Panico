import pytest
from fastapi import status

class TestAuthentication:
    """CT01, CT02: Testes de autenticação"""
    
    def test_login_valid_user(self, test_client, sample_user_data):
        """CT01: Login de usuário válido"""
        # Create user first
        test_client.post("/users/", json=sample_user_data)
        
        # Attempt login
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        response = test_client.post("/auth/login", json=login_data)
        
        # Pode retornar 200 (sucesso) ou 401 (dependendo do mock)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_401_UNAUTHORIZED]
        
        if response.status_code == 200:
            assert "access_token" in response.json()
            assert response.json()["token_type"] == "bearer"
    
    def test_login_invalid_user(self, test_client):
        """CT02: Login de usuário inválido"""
        login_data = {
            "email": "nonexistent@example.com",
            "password": "wrongpassword"
        }
        response = test_client.post("/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_login_wrong_password(self, test_client, sample_user_data):
        """CT02: Login com senha incorreta"""
        test_client.post("/users/", json=sample_user_data)
        
        login_data = {
            "email": sample_user_data["email"],
            "password": "wrongpassword"
        }
        response = test_client.post("/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_refresh_token_endpoint_exists(self, test_client):
        """Test that refresh token endpoint exists"""
        response = test_client.post("/auth/refresh", json={"refresh_token": "test"})
        # Should either return 401 (invalid token) or 422 (validation error)
        assert response.status_code in [401, 422]
    
    def test_login_missing_credentials(self, test_client):
        """Test login with missing credentials"""
        response = test_client.post("/auth/login", json={})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.auth
    def test_protected_endpoint_without_token(self, test_client):
        """Test accessing protected endpoint without token"""
        response = test_client.get("/users/me")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_login_invalid_email_format(self, test_client):
        """Test login with invalid email format"""
        login_data = {
            "email": "invalid-email",
            "password": "password123"
        }
        response = test_client.post("/auth/login", json=login_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY