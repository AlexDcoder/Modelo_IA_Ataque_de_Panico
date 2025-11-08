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
        # Mock é rápido, deve responder em menos de 1 segundo
        assert response_time < 1.0
        print(f"✅ Prediction response time: {response_time:.3f} seconds")
    
    def test_multiple_requests_performance(self, test_client, auth_headers, sample_vital_data):
        """Test performance under multiple sequential requests"""
        times = []
        
        for i in range(10):
            start_time = time.time()
            response = test_client.post(
                "/ai/predict", 
                json=sample_vital_data, 
                headers=auth_headers
            )
            end_time = time.time()
            
            assert response.status_code == status.HTTP_200_OK
            times.append(end_time - start_time)
        
        # Calculate statistics
        avg_time = sum(times) / len(times)
        max_time = max(times)
        min_time = min(times)
        
        # Mock é muito rápido
        assert avg_time < 0.5
        assert max_time < 1.0
        
        print(f"📊 Performance Results:")
        print(f"  Average response time: {avg_time:.3f} seconds")
        print(f"  Maximum response time: {max_time:.3f} seconds")
        print(f"  Minimum response time: {min_time:.3f} seconds")
        print(f"  Total requests: {len(times)}")
    
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
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_401_UNAUTHORIZED]
        login_time = end_time - start_time
        
        # Login should be fast
        assert login_time < 1.0
        print(f"✅ Login response time: {login_time:.3f} seconds")
    
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
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]
        creation_time = end_time - start_time
        
        # User creation should be reasonable
        assert creation_time < 1.0
        print(f"✅ User creation time: {creation_time:.3f} seconds")
    
    def test_bulk_vital_data_performance(self, test_client, auth_headers):
        """Test performance with multiple vital data submissions"""
        vital_data_points = [
            {
                "heart_rate": 80.0 + i,
                "respiration_rate": 16.0 + i,
                "accel_std": 0.5 + (i * 0.1),
                "spo2": 98.0 - i,
                "stress_level": 3.0 + i
            }
            for i in range(5)
        ]
        
        start_time = time.time()
        
        for vital_data in vital_data_points:
            response = test_client.post(
                "/vital-data/test-uid", 
                json=vital_data, 
                headers=auth_headers
            )
            assert response.status_code in [200, 403]
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # Bulk operations should be efficient
        assert total_time < 2.0
        print(f"✅ Bulk vital data submission time: {total_time:.3f} seconds")