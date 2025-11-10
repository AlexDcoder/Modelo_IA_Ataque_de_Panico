import pytest
from fastapi import status

class TestEndToEnd:
    """Testes end-to-end do fluxo completo"""
    
    def test_complete_user_journey(self, test_client, mock_db_service, sample_user_data, sample_vital_data):
        """Fluxo completo: registro → login → dados vitais → predição → feedback"""
        # 1. Registro
        mock_db_service.check_existing_user.return_value = (False, False)
        register_response = test_client.post("/users/", json=sample_user_data)
        assert register_response.status_code == status.HTTP_200_OK
        
        # 2. Login
        with pytest.MonkeyPatch().context() as m:
            m.setattr('core.routes.auth.verify_password', lambda x, y: True)
            login_response = test_client.post("/auth/login", json={
                "email": sample_user_data["email"],
                "password": sample_user_data["password"]
            })
            assert login_response.status_code == status.HTTP_200_OK
        
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 3. Enviar dados vitais
        vital_response = test_client.post(
            f"/vital-data/{register_response.json()['uid']}",
            json=sample_vital_data,
            headers=headers
        )
        assert vital_response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
        
        # 4. Fazer predição
        prediction_response = test_client.post(
            "/ai/predict",
            json=sample_vital_data,
            headers=headers
        )
        assert prediction_response.status_code == status.HTTP_200_OK
        
        # 5. Enviar feedback
        feedback_data = {
            "uid": register_response.json()['uid'],
            "features": sample_vital_data,
            "user_feedback": 1
        }
        
        feedback_response = test_client.post(
            "/feedback/",
            json=feedback_data,
            headers=headers
        )
        assert feedback_response.status_code == status.HTTP_200_OK