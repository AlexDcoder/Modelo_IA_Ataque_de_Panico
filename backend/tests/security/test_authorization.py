import pytest
from fastapi import status

class TestAuthorization:
    """Testes de autorização"""
    
    def test_user_authorization_scope(self, test_client, authenticated_user, mock_db_service):
        """Validação de escopo de usuário"""
        if authenticated_user:
            # Primeiro garantir que o usuário "other_user_id" existe no mock
            other_user_data = {
                "username": "otheruser",
                "email": "other@example.com", 
                "password": "OtherPass123",
                "detection_time": "10:00:00",
                "emergency_contact": []
            }
            mock_db_service.create_user("other_user_id", other_user_data)
            
            # Usuário não deve poder modificar dados de outros usuários
            update_response = test_client.put(
                "/users/other_user_id", 
                json={"username": "hacked"},
                headers=authenticated_user["headers"]
            )
            assert update_response.status_code == status.HTTP_403_FORBIDDEN
            
            # Usuário não deve poder deletar outros usuários
            delete_response = test_client.delete(
                "/users/other_user_id",
                headers=authenticated_user["headers"]
            )
            assert delete_response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_user_cannot_access_other_user_vital_data(self, test_client, authenticated_user, mock_db_service):
        """Usuário não pode acessar dados vitais de outros usuários"""
        if authenticated_user:
            # Criar dados vitais para outro usuário
            other_user_vital_data = {
                "heart_rate": 80.0,
                "respiration_rate": 18.0,
                "accel_std": 0.2,
                "spo2": 97.0,
                "stress_level": 5.0
            }
            mock_db_service.set_vital("other_user_id", other_user_vital_data)
            
            # Tentar acessar dados vitais de outro usuário
            response = test_client.get(
                "/vital-data/other_user_id",
                headers=authenticated_user["headers"]
            )
            assert response.status_code == status.HTTP_403_FORBIDDEN