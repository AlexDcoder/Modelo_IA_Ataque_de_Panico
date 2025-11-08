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
            
            assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
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
            
            # Login to get token
            login_data = {
                "email": sample_user_data["email"],
                "password": sample_user_data["password"]
            }
            login_response = test_client.post("/auth/login", json=login_data)
            
            if login_response.status_code == 200:
                token_data = login_response.json()
                # Token should be present but not raw password
                assert "access_token" in token_data
                assert "password" not in token_data
    
    def test_cors_headers(self, test_client):
        """Test that CORS headers are properly set"""
        response = test_client.options("/")
        
        # Should have CORS headers
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "*"
        
        # Should allow necessary methods
        assert "access-control-allow-methods" in response.headers
        allowed_methods = response.headers["access-control-allow-methods"]
        for method in ["GET", "POST", "PUT", "DELETE"]:
            assert method in allowed_methods
    
    def test_rate_limiting_resilience(self, test_client, auth_headers, sample_vital_data):
        """Test that API handles multiple requests gracefully"""
        # Make multiple rapid requests
        for i in range(10):
            response = test_client.post(
                "/ai/predict", 
                json=sample_vital_data, 
                headers=auth_headers
            )
            # Should not crash and return proper status codes
            assert response.status_code in [200, 429, 401]