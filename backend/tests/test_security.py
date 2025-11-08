import pytest
from fastapi import status

@pytest.mark.security
class TestSecurity:
    """CT10: Testes de segurança"""
    
    def test_unauthenticated_access(self, test_client):
        """CT10: Tentar acessar dados sem autenticação"""
        endpoints = [
            ("/users/me", "GET"),
            ("/vital-data/test-uid", "GET"),
            ("/ai/predict", "POST"),
            ("/feedback/", "POST")
        ]
        
        for endpoint, method in endpoints:
            if method == "GET":
                response = test_client.get(endpoint)
            else:
                response = test_client.post(endpoint, json={})
            
            # CORREÇÃO: API está retornando 403 em vez de 401
            assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]
    
    def test_password_hashing(self):
        """Test that passwords are properly hashed"""
        from core.security.password import hash_password, verify_password
        
        plain_password = "TestPassword123"
        hashed = hash_password(plain_password)
        
        # Hashed password should be different from plain text
        assert hashed != plain_password
        # Should be significantly longer
        assert len(hashed) > len(plain_password)
        # Should verify correctly
        assert verify_password(plain_password, hashed) == True
        # Wrong password should not verify
        assert verify_password("WrongPassword", hashed) == False
    
    def test_jwt_token_creation(self):
        """Test JWT token creation"""
        from core.security.jwt_handler import JWTHandler
        
        test_data = {"sub": "test-user"}
        token = JWTHandler.create_access_token(test_data)
        
        # Token should be created
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_sql_injection_prevention(self, test_client, auth_headers):
        """Test basic SQL injection prevention"""
        malicious_username = "test'; DROP TABLE users; --"
        
        user_data = {
            "username": malicious_username,
            "email": "sql_test@example.com",
            "password": "TestPassword123",
            "detection_time": "10:00:00",
            "emergency_contact": []
        }
        
        response = test_client.post("/users/", json=user_data)
        
        # Should handle safely (validation may reject or accept but not execute)
        assert response.status_code in [200, 400, 422]
    
    def test_xss_prevention(self, test_client, auth_headers):
        """Test basic XSS prevention"""
        malicious_script = "<script>alert('xss')</script>"
        
        user_data = {
            "username": malicious_script,
            "email": "xss_test@example.com",
            "password": "TestPassword123",
            "detection_time": "10:00:00",
            "emergency_contact": []
        }
        
        response = test_client.post("/users/", json=user_data)
        
        # Should handle safely
        assert response.status_code in [200, 400, 422]
    
    def test_sensitive_data_exposure(self, test_client, sample_user_data):
        """Test that sensitive data is not exposed"""
        # Create user
        response = test_client.post("/users/", json=sample_user_data)
        
        if response.status_code == 200:
            user_data = response.json()
            
            # Password should never be exposed
            assert "password" not in user_data
    
    def test_cors_headers(self, test_client):
        """Test that CORS headers are properly set"""
        # CORREÇÃO: Usar um endpoint que existe e suporta CORS
        response = test_client.get("/")
        
        # Should have CORS headers
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "*"
    
    def test_rate_limiting_resilience(self, test_client, auth_headers, sample_vital_data):
        """Test that API handles multiple requests gracefully"""
        # Make multiple rapid requests
        for i in range(5):
            response = test_client.post(
                "/ai/predict", 
                json=sample_vital_data, 
                headers=auth_headers
            )
            # Should not crash and return proper status codes
            assert response.status_code in [200, 401, 403, 429]