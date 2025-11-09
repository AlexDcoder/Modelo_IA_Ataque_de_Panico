import pytest
from fastapi import status
from unittest.mock import patch
from core.security.jwt_handler import JWTHandler
import time

class TestAuthentication:
    """CT01, CT02 - Testes de autenticação"""
    
    @patch('core.routes.auth.verify_password')
    def test_login_valid_user(self, mock_verify, test_client, mock_db_service, sample_user_data):
        """CT01: Login de usuário válido"""
        # Configurar o mock para retornar True quando a senha for a correta
        mock_verify.return_value = True
        
        # Setup - criar usuário no mock
        user_data = sample_user_data.copy()
        user_data['password'] = 'Test1234'
        hashed_user_data = user_data.copy()
        hashed_user_data['password'] = '$2b$12$hashedpassword123'
        
        mock_db_service.create_user("test_uid", hashed_user_data)
        
        # Test - fazer login
        response = test_client.post("/auth/login", json={
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        })

        assert response.status_code == status.HTTP_200_OK
        assert "access_token" in response.json()
        assert "refresh_token" in response.json()
    
    def test_login_invalid_credentials(self, test_client):
        """CT02: Login com credenciais inválidas"""
        response = test_client.post("/auth/login", json={
            "email": "invalid@example.com",
            "password": "wrongpassword"
        })

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @patch('core.routes.auth.verify_password')
    def test_refresh_token_valid(self, mock_verify, test_client, mock_db_service, sample_user_data):
        """Testar renovação de token com refresh token válido"""
        # Configurar mocks
        mock_verify.return_value = True
        user_data = sample_user_data.copy()
        hashed_user_data = user_data.copy()
        hashed_user_data['password'] = '$2b$12$hashedpassword123'
        user_id = "test_user_123"
        mock_db_service.create_user(user_id, hashed_user_data)

        # Fazer login para obter tokens
        login_response = test_client.post("/auth/login", json={
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        })
        
        refresh_token = login_response.json()["refresh_token"]

        # Fazer refresh do token
        refresh_response = test_client.post("/auth/refresh", json={
            "refresh_token": refresh_token
        })

        assert refresh_response.status_code == status.HTTP_200_OK
        assert "access_token" in refresh_response.json()
        assert "refresh_token" in refresh_response.json()
    
    def test_refresh_token_invalid(self, test_client):
        """Testar renovação com refresh token inválido"""
        response = test_client.post("/auth/refresh", json={
            "refresh_token": "invalid_token_here"
        })

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    @patch('core.routes.auth.verify_password')
    def test_refresh_token_user_not_found(self, mock_verify, test_client, mock_db_service, sample_user_data):
        """Testar refresh token quando usuário não existe mais"""
        # Configurar mocks
        mock_verify.return_value = True
        user_data = sample_user_data.copy()
        hashed_user_data = user_data.copy()
        hashed_user_data['password'] = '$2b$12$hashedpassword123'
        user_id = "test_user_123"
        mock_db_service.create_user(user_id, hashed_user_data)

        # Fazer login para obter tokens
        login_response = test_client.post("/auth/login", json={
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        })
        
        refresh_token = login_response.json()["refresh_token"]

        # Remover usuário do mock
        mock_db_service.delete_user(user_id)

        # Tentar refresh
        refresh_response = test_client.post("/auth/refresh", json={
            "refresh_token": refresh_token
        })

        assert refresh_response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_refresh_token_wrong_type(self, test_client, authenticated_user):
        """Testar usar access token como refresh token"""
        if authenticated_user:
            access_token = authenticated_user["headers"]["Authorization"].split(" ")[1]
            
            response = test_client.post("/auth/refresh", json={
                "refresh_token": access_token
            })

            assert response.status_code == status.HTTP_401_UNAUTHORIZED