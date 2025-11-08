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
        
        assert response.status_code == status.HTTP_200_OK
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
        # Should either return 401 (invalid token) or 200 (valid token)
        assert response.status_code in [401, 200]
    
    def test_login_missing_credentials(self, test_client):
        """Test login with missing credentials"""
        response = test_client.post("/auth/login", json={})
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.auth
    def test_protected_endpoint_without_token(self, test_client):
        """Test accessing protected endpoint without token"""
        response = test_client.get("/users/me")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED