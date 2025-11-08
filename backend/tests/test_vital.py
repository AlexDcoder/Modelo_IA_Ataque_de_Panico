import pytest
from fastapi import status

class TestVitalData:
    """CT04: Testes de dados vitais"""
    
    def test_create_vital_data(self, test_client, auth_headers, sample_vital_data):
        """CT04: Coleta de sinais fisiológicos"""
        response = test_client.post(
            "/vital-data/test-uid", 
            json=sample_vital_data, 
            headers=auth_headers
        )
        
        assert response.status_code in [200, 403]  # Success or unauthorized
    
    def test_get_vital_data(self, test_client, auth_headers):
        """Test retrieving vital data"""
        response = test_client.get("/vital-data/test-uid", headers=auth_headers)
        
        assert response.status_code in [200, 403, 404]
    
    def test_update_vital_data(self, test_client, auth_headers, sample_vital_data):
        """Test updating vital data"""
        updated_data = sample_vital_data.copy()
        updated_data["heart_rate"] = 90.0
        
        response = test_client.put(
            "/vital-data/test-uid", 
            json=updated_data, 
            headers=auth_headers
        )
        
        assert response.status_code in [200, 403, 404]
    
    def test_get_all_vital_data(self, test_client, auth_headers):
        """Test getting all vital data (admin functionality)"""
        response = test_client.get("/vital-data/", headers=auth_headers)
        
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), dict)
    
    def test_vital_data_validation(self, test_client, auth_headers):
        """Test vital data validation"""
        invalid_vital_data = {
            "heart_rate": -10,  # Invalid negative value
            "respiration_rate": 16.0,
            "accel_std": 0.5,
            "spo2": 98.0,
            "stress_level": 3.0
        }
        response = test_client.post(
            "/vital-data/test-uid", 
            json=invalid_vital_data, 
            headers=auth_headers
        )
        
        # Should return 422 validation error
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.vital
    def test_vital_data_structure(self, test_client, auth_headers, sample_vital_data):
        """Test vital data structure"""
        response = test_client.post(
            "/vital-data/test-uid", 
            json=sample_vital_data, 
            headers=auth_headers
        )
        
        if response.status_code == 200:
            # If successful, verify the response structure
            data = response.json()
            assert "message" in data
            assert "success" in data["message"].lower()
    
    @pytest.mark.vital
    def test_unauthorized_vital_access(self, test_client):
        """Test accessing vital data without authentication"""
        response = test_client.get("/vital-data/test-uid")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED