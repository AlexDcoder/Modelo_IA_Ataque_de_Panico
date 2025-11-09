import pytest
from fastapi import status

class TestMeSecurity:
    """Testes de segurança para a rota /me"""
    
    def test_me_prevents_user_impersonation(self, test_client, authenticated_user, mock_db_service):
        """Testar que /me sempre retorna o usuário do token, não permitindo impersonation"""
        if authenticated_user:
            # Configurar mock para retornar dados de outro usuário
            other_user_data = {
                "username": "otheruser",
                "email": "other@example.com",
                "detection_time": "10:00:00",
                "emergency_contact": []
            }
            mock_db_service.get_user.return_value = other_user_data
            
            response = test_client.get("/users/me", headers=authenticated_user["headers"])
            
            # A rota /me deve retornar o UID do usuário autenticado, não dos dados do mock
            assert response.status_code == status.HTTP_200_OK
            assert response.json()["uid"] == authenticated_user["uid"]  # Deve ser o UID do token
    
    def test_me_no_sql_injection(self, test_client, authenticated_user):
        """Testar que /me não é vulnerável a SQL injection através do token"""
        if authenticated_user:
            # Tentar token com caracteres especiais
            malicious_headers = {"Authorization": "Bearer ' OR '1'='1"}
            response = test_client.get("/users/me", headers=malicious_headers)
            
            # Deve retornar erro de autenticação, não erro de servidor
            assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_me_rate_limiting(self, test_client, authenticated_user):
        """Testar limitação de taxa para /me (se implementado)"""
        if authenticated_user:
            # Fazer múltiplas requisições rápidas
            for i in range(20):
                response = test_client.get("/users/me", headers=authenticated_user["headers"])
                
                # Se houver rate limiting, deve retornar 429 após certo ponto
                # Caso contrário, deve continuar retornando 200
                if response.status_code == 429:
                    break
            
            # Pelo menos as primeiras requisições devem ser bem-sucedidas
            assert response.status_code in [200, 429]