import pytest
from fastapi import status

class TestAuthIntegration:
    """Testes de integração de autenticação"""
    
    def test_complete_auth_flow(self, test_client, mock_db_service, sample_user_data):
        """Fluxo completo: cadastro → login → acesso → logout"""
        # Configurar mocks
        mock_db_service.check_existing_user.return_value = (False, False)
        
        # Cadastro
        register_response = test_client.post("/users/", json=sample_user_data)
        assert register_response.status_code == status.HTTP_200_OK
        
        # Login (com mock de verificação de senha)
        with pytest.MonkeyPatch().context() as m:
            m.setattr('core.routes.auth.verify_password', lambda x, y: True)
            login_response = test_client.post("/auth/login", json={
                "email": sample_user_data["email"],
                "password": sample_user_data["password"]
            })
            assert login_response.status_code == status.HTTP_200_OK
        
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Acesso a rota protegida
        profile_response = test_client.get("/users/me", headers=headers)
        assert profile_response.status_code == status.HTTP_200_OK