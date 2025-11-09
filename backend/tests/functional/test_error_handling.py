import pytest
from fastapi import status

class TestErrorHandling:
    """Testes para tratamento de erros"""
    
    def test_invalid_json(self, test_client):
        """Testar envio de JSON inválido"""
        response = test_client.post(
            "/users/",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_nonexistent_endpoint(self, test_client):
        """Testar acesso a endpoint inexistente"""
        response = test_client.get("/nonexistent-endpoint")
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_method_not_allowed(self, test_client):
        """Testar método HTTP não permitido"""
        response = test_client.patch("/users/")
        
        assert response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED
    
    def test_missing_required_fields(self, test_client):
        """Testar criação de usuário com campos obrigatórios faltando"""
        incomplete_data = {
            "username": "testuser"
            # Faltam email, password, etc.
        }
        
        response = test_client.post("/users/", json=incomplete_data)
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY