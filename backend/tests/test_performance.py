import pytest
import time
from fastapi import status

@pytest.mark.performance
class TestPerformance:
    """CT09: Testes de performance"""
    
    def test_prediction_response_time(self, test_client, auth_headers, sample_vital_data):
        """CT09: Teste de performance - tempo de resposta"""
        start_time = time.time()
        
        response = test_client.post(
            "/ai/predict", 
            json=sample_vital_data, 
            headers=auth_headers
        )
        
        end_time = time.time()
        response_time = end_time - start_time
        
        assert response.status_code == status.HTTP_200_OK
        # Response should be under 2 seconds for good UX
        assert response_time < 2.0
        print(f"Prediction response time: {response_time:.3f} seconds")
    
    def test_multiple_requests_performance(self, test_client, auth_headers, sample_vital_data):
        """Test performance under multiple sequential requests"""
        times = []
        
        for i in range(5):
            start_time = time.time()
            response = test_client.post(
                "/ai/predict", 
                json=sample_vital_data, 
                headers=auth_headers
            )
            end_time = time.time()
            
            assert response.status_code == status.HTTP_200_OK
            times.append(end_time - start_time)
        
        # Average response time should be reasonable
        avg_time = sum(times) / len(times)
        max_time = max(times)
        
        assert avg_time < 1.5
        assert max_time < 2.5
        
        print(f"Average response time: {avg_time:.3f} seconds")
        print(f"Maximum response time: {max_time:.3f} seconds")
    
    def test_concurrent_login_performance(self, test_client, sample_user_data):
        """Test login performance"""
        # Create user first
        test_client.post("/users/", json=sample_user_data)
        
        login_data = {
            "email": sample_user_data["email"],
            "password": sample_user_data["password"]
        }
        
        start_time = time.time()
        response = test_client.post("/auth/login", json=login_data)
        end_time = time.time()
        
        assert response.status_code == status.HTTP_200_OK
        login_time = end_time - start_time
        
        # Login should be fast
        assert login_time < 1.0
        print(f"Login response time: {login_time:.3f} seconds")
    
    def test_user_creation_performance(self, test_client):
        """Test user creation performance"""
        user_data = {
            "username": "perfuser",
            "email": "perf@example.com",
            "password": "TestPassword123",
            "detection_time": "10:00:00",
            "emergency_contact": []
        }
        
        start_time = time.time()
        response = test_client.post("/users/", json=user_data)
        end_time = time.time()
        
        assert response.status_code == status.HTTP_200_OK
        creation_time = end_time - start_time
        
        # User creation should be reasonable
        assert creation_time < 2.0
        print(f"User creation time: {creation_time:.3f} seconds")