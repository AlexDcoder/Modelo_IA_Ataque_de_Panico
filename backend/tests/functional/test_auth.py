import pytest

class TestAuthentication:
    """CT01 e CT02 - Testes de autenticação"""
    
    def test_ct01_valid_login(self, client, test_user):
        """CT01: Login de usuário válido"""
        # O usuário já foi criado pela fixture test_user
        # Apenas validar que podemos fazer login
        login_data = {
            "email": test_user["email"],
            "password": test_user["password"]
        }
        login_response = client.post("/auth/login", json=login_data)
        
        assert login_response.status_code == 200
        data = login_response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    def test_ct02_invalid_login(self, client):
        """CT02: Login de usuário inválido"""
        login_data = {
            "email": "invalid@example.com",
            "password": "wrongpassword"
        }
        response = client.post("/auth/login", json=login_data)
        
        assert response.status_code == 401
        assert "Invalid credentials" in response.json()["detail"]