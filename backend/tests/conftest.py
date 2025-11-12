import sys
import os
from pathlib import Path
import pytest
from dotenv import load_dotenv
import uuid
import time
from ..core.logger import get_logger

logger = get_logger(__name__)

# Adiciona o diretório raiz do projeto ao Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Carrega variáveis de ambiente de teste
load_dotenv(project_root / '.env.test')

from main import app
from fastapi.testclient import TestClient

@pytest.fixture(scope="session")
def client():
    """Cliente de teste para a API"""
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture
def test_user_data():
    """Dados de usuário para testes - com email único"""
    unique_id = uuid.uuid4().hex[:8]
    return {
        "username": f"testuser_{unique_id}",
        "email": f"test_{unique_id}@example.com",
        "password": "testpassword123",
        "detection_time": "12:00:00",
        "emergency_contact": [
            {
                "name": "Emergency Contact",
                "phone": "+5511999999999"
            }
        ]
    }

def delete_user_safely(client, uid, token=None, max_retries=3):
    """
    Deleta um usuário de forma segura, sem tentar deletar dados vitais
    """
    logger.info(f"🔄 Iniciando deleção segura do usuário {uid}")
    
    for attempt in range(max_retries):
        try:
            headers = {"Authorization": f"Bearer {token}"} if token else {}
            
            # Apenas deletar o usuário (dados vitais serão limpos automaticamente pelo Firebase ou ficarão órfãos)
            try:
                user_response = client.delete(f"/users/{uid}", headers=headers)
                if user_response.status_code == 200:
                    logger.info(f"  ✅ Usuário {uid} deletado com sucesso")
                    return True
                elif user_response.status_code == 404:
                    logger.info(f"  ℹ️  Usuário {uid} já não existe")
                    return True
                else:
                    logger.warning(f"  ⚠️ Status {user_response.status_code} ao deletar usuário")
            except Exception as e:
                logger.error(f"  ❌ Erro ao deletar usuário: {e}")
            
        except Exception as e:
            logger.error(f"  ❌ Tentativa {attempt + 1} falhou: {e}")
        
        # Espera antes da próxima tentativa
        if attempt < max_retries - 1:
            time.sleep(1)
            logger.info(f"  🔄 Tentativa {attempt + 2} de {max_retries}")
    
    logger.error(f"  ❌ Falha ao deletar usuário {uid} após {max_retries} tentativas")
    return False

@pytest.fixture
def cleanup_user(client):
    """Fixture para limpeza manual de UM usuário por teste"""
    user_to_cleanup = None
    
    def _register_user_for_cleanup(uid, token=None):
        """Registra UM usuário para cleanup automático após o teste"""
        nonlocal user_to_cleanup
        if user_to_cleanup:
            logger.warning(f"⚠️  Substituindo usuário {user_to_cleanup[0]} por {uid} - apenas um usuário por teste é suportado")
        user_to_cleanup = (uid, token)
        logger.info(f"📝 Usuário {uid} registrado para cleanup automático")
        return uid
    
    yield _register_user_for_cleanup
    
    # Cleanup após o teste - executa apenas para o usuário registrado
    if user_to_cleanup:
        uid, token = user_to_cleanup
        logger.info(f"🧹 Iniciando cleanup para usuário {uid}")
        
        if delete_user_safely(client, uid, token):
            logger.info(f"✅ Cleanup concluído para usuário {uid}")
        else:
            logger.error(f"❌ Cleanup falhou para usuário {uid}")

@pytest.fixture(scope="session", autouse=True)
def final_cleanup(client):
    """
    Cleanup final de segurança - remove qualquer usuário de teste restante
    Executa após TODOS os testes
    """
    yield
    
    logger.info("\n" + "="*60)
    logger.info("🧹🛡️  CLEANUP FINAL DE SEGURANÇA")
    logger.info("="*60)
    
    try:
        # Buscar todos os usuários
        response = client.get("/users/")
        if response.status_code == 200:
            users = response.json() or {}
            test_users = []
            
            # Identificar usuários de teste
            for uid, user_data in users.items():
                if not isinstance(user_data, dict):
                    continue
                    
                email = user_data.get('email', '')
                username = user_data.get('username', '')
                
                # Critérios para identificar usuários de teste
                is_test_user = (
                    email.startswith('test_') or 
                    username.startswith('testuser_') or
                    'test' in email.lower() or
                    'example.com' in email
                )
                
                if is_test_user:
                    test_users.append((uid, user_data))
            
            if test_users:
                logger.info(f"📋 Encontrados {len(test_users)} usuário(s) de teste para limpeza final")
                
                for uid, user_data in test_users:
                    email = user_data.get('email', 'Unknown')
                    logger.info(f"  🗑️  Removendo usuário {uid} ({email})")
                    
                    # Tentar login com senhas padrão de teste
                    token = None
                    passwords_to_try = [
                        "testpassword123",
                        user_data.get('password', '')
                    ]
                    
                    for password in passwords_to_try:
                        if not password:
                            continue
                            
                        try:
                            login_response = client.post("/auth/login", json={
                                "email": email,
                                "password": password
                            })
                            
                            if login_response.status_code == 200:
                                token = login_response.json()["access_token"]
                                logger.info(f"    🔑 Token obtido para {email}")
                                break
                        except:
                            continue
                    
                    # Deletar usuário de forma segura
                    delete_user_safely(client, uid, token)
            else:
                logger.info("✅ Nenhum usuário de teste encontrado para limpeza final")
        else:
            logger.warning(f"⚠️  Não foi possível buscar usuários (status {response.status_code})")
            
    except Exception as e:
        logger.error(f"❌ Erro durante cleanup final: {e}")
    
    logger.info("="*60)
    logger.info("✅ Cleanup final de segurança concluído")

@pytest.fixture
def test_user(client, test_user_data, cleanup_user):
    """Cria UM usuário de teste e registra automaticamente para cleanup"""
    # Criar usuário
    response = client.post("/users/", json=test_user_data)
    assert response.status_code == 200, f"Falha ao criar usuário: {response.text}"
    user_response = response.json()
    user_uid = user_response["uid"]
    
    # Fazer login para obter token
    login_data = {
        "email": test_user_data["email"],
        "password": test_user_data["password"]
    }
    login_response = client.post("/auth/login", json=login_data)
    assert login_response.status_code == 200, f"Falha no login: {login_response.text}"
    token = login_response.json()["access_token"]
    
    user_info = {
        **test_user_data,
        "uid": user_uid,
        "token": token
    }
    
    # Registrar para cleanup manual automático (APENAS ESTE USUÁRIO)
    cleanup_user(user_uid, token)
    
    logger.info(f"👤 Usuário de teste criado: {user_uid} ({test_user_data['email']})")
    return user_info

@pytest.fixture
def auth_headers(test_user):
    """Headers de autenticação para testes"""
    return {"Authorization": f"Bearer {test_user['token']}"}

@pytest.fixture
def test_vital_data():
    """Dados vitais para testes"""
    return {
        "heart_rate": 75.0,
        "respiration_rate": 16.0,
        "accel_std": 0.5,
        "spo2": 98.0,
        "stress_level": 3.0
    }

@pytest.fixture
def panic_vital_data():
    """Dados vitais que indicam possível pânico"""
    return {
        "heart_rate": 120.0,
        "respiration_rate": 25.0,
        "accel_std": 2.5,
        "spo2": 85.0,
        "stress_level": 8.5
    }