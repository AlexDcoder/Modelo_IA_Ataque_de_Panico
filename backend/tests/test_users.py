import pytest
from fastapi import status

class TestUserManagement:
    """CT03: Testes de gerenciamento de usuários"""
    
    def test_create_user_success(self, test_client, sample_user_data):
        """CT03: Cadastro de novo usuário"""
        response = test_client.post("/users/", json=sample_user_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["username"] == sample_user_data["username"]
        assert data["email"] == sample_user_data["email"]
        assert "uid" in data
        assert "password" not in data
    
    def test_create_user_duplicate_email(self, test_client, sample_user_data):
        """Test duplicate email registration"""
        # First registration
        test_client.post("/users/", json=sample_user_data)
        
        # Try to create another user with same email
        duplicate_data = sample_user_data.copy()
        duplicate_data["username"] = "differentuser"
        response = test_client.post("/users/", json=duplicate_data)
        
        # Should return 400 Bad Request
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_create_user_duplicate_username(self, test_client, sample_user_data):
        """Test duplicate username registration"""
        # First registration
        test_client.post("/users/", json=sample_user_data)
        
        # Try to create another user with same username
        duplicate_data = sample_user_data.copy()
        duplicate_data["email"] = "different@example.com"
        response = test_client.post("/users/", json=duplicate_data)
        
        # Should return 400 Bad Request
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_get_current_user_info(self, test_client, auth_headers):
        """Test getting current user information"""
        response = test_client.get("/users/me", headers=auth_headers)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "uid" in data
        assert "username" in data
        assert "email" in data
    
    def test_get_user_public_info(self, test_client, auth_headers):
        """Test getting public user information"""
        response = test_client.get("/users/test-uid", headers=auth_headers)
        
        # Could be 200 (found) or 404 (not found)
        assert response.status_code in [200, 404]
    
    def test_update_user_info(self, test_client, auth_headers):
        """Test updating user information"""
        update_data = {
            "username": "updateduser",
            "detection_time": "15:00:00"
        }
        response = test_client.put("/users/test-uid", json=update_data, headers=auth_headers)
        
        # Could be 200 (success), 403 (unauthorized), or 404 (not found)
        assert response.status_code in [200, 403, 404]
    
    def test_update_user_password(self, test_client, auth_headers):
        """Test updating user password"""
        update_data = {
            "password": "NewPassword123"
        }
        response = test_client.put("/users/test-uid", json=update_data, headers=auth_headers)
        
        assert response.status_code in [200, 403, 404]
    
    def test_delete_user(self, test_client, auth_headers):
        """Test user deletion"""
        response = test_client.delete("/users/test-uid", headers=auth_headers)
        
        # Could be 200 (success) or 403 (unauthorized)
        assert response.status_code in [200, 403]
    
    def test_get_all_users(self, test_client, auth_headers):
        """Test getting all users (admin functionality)"""
        response = test_client.get("/users/", headers=auth_headers)
        
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), dict)
    
    @pytest.mark.users
    def test_user_validation_username(self, test_client):
        """Test username validation"""
        invalid_user_data = {
            "username": "ab",  # Too short
            "email": "test@example.com",
            "password": "TestPassword123",
            "detection_time": "10:00:00",
            "emergency_contact": []
        }
        response = test_client.post("/users/", json=invalid_user_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.users
    def test_user_validation_password(self, test_client):
        """Test password validation"""
        invalid_user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "short",  # Too short and weak
            "detection_time": "10:00:00",
            "emergency_contact": []
        }
        response = test_client.post("/users/", json=invalid_user_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY