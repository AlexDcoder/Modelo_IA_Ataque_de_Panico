import pytest
from datetime import timedelta
from core.security.jwt_handler import JWTHandler
from fastapi import HTTPException, status
import time

class TestJWTHandler:
    """Testes unitários para o JWTHandler"""
    
    def test_create_access_token(self):
        """Testar criação de access token"""
        data = {"sub": "test_user", "role": "user"}
        token = JWTHandler.create_access_token(data)
        
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_create_refresh_token(self):
        """Testar criação de refresh token"""
        data = {"sub": "test_user"}
        token = JWTHandler.create_refresh_token(data)
        
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_decode_valid_token(self):
        """Testar decodificação de token válido"""
        data = {"sub": "test_user", "test_data": "value"}
        token = JWTHandler.create_access_token(data)
        
        decoded = JWTHandler.decode_token(token)
        
        assert decoded["sub"] == "test_user"
        assert decoded["test_data"] == "value"
    
    def test_decode_invalid_token(self):
        """Testar decodificação de token inválido"""
        with pytest.raises(HTTPException) as exc_info:
            JWTHandler.decode_token("invalid_token")
        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_token_expiration(self):
        """Testar expiração do token"""
        # Salvar configuração original
        original_expire = JWTHandler.ACCESS_TOKEN_EXPIRE_MINUTES
        
        try:
            # Configurar expiração para 1 segundo
            JWTHandler.ACCESS_TOKEN_EXPIRE_MINUTES = 1/60  # 1 segundo
            
            data = {"sub": "test_user"}
            token = JWTHandler.create_access_token(data)
            
            # Aguardar 2 segundos para o token expirar
            time.sleep(2)
            
            with pytest.raises(HTTPException) as exc_info:
                JWTHandler.decode_token(token)
            assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
            assert "expired" in exc_info.value.detail.lower()
        finally:
            # Restaurar valor original
            JWTHandler.ACCESS_TOKEN_EXPIRE_MINUTES = original_expire
    
    def test_refresh_token_has_correct_type(self):
        """Testar se refresh token tem o tipo correto"""
        data = {"sub": "test_user"}
        token = JWTHandler.create_refresh_token(data)
        
        decoded = JWTHandler.decode_token(token)
        
        assert decoded["type"] == "refresh"
        assert decoded["sub"] == "test_user"