import sys
import os
from pathlib import Path
import pytest
from dotenv import load_dotenv
import uuid
import time
import logging

# Configure logging for tests
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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

def delete_user_completely(client, uid, token=None, max_retries=3):
    """
    Deleta um usuário completamente com todas as tentativas necessárias
    """
    logger.info(f"🔄 Iniciando deleção completa do usuário {uid}")
    
    for attempt in range(max_retries):
        try:
            headers = {"Authorization": f"Bearer {token}"} if token else {}
            
            # 1. Deletar dados vitais
            try:
                vital_response = client.delete(f"/vital-data/{uid}", headers=headers)
                if vital_response.status_code in [200, 404]:
                    logger.info(f"  ✅ Dados vitais de {uid} removidos")
                else:
                    logger.warning(f"  ⚠️ Status {vital_response.status_code} ao remover dados vitais")
            except Exception as e:
                logger.warning(f"  ⚠️ Erro ao remover dados vitais: {e}")
            
            # 2. Deletar o usuário principal
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
    """Fixture para limpeza manual robusta de usuários"""
    users_to_cleanup = []
    
    def _register_user_for_cleanup(uid, token=None):
        """Registra um usuário para cleanup automático após o teste"""
        users_to_cleanup.append((uid, token))
        logger.info(f"📝 Usuário {uid} registrado para cleanup automático")
        return uid
    
    yield _register_user_for_cleanup
    
    # Cleanup após o teste - executa para todos os usuários registrados
    if users_to_cleanup:
        logger.info(f"🧹 Iniciando cleanup manual para {len(users_to_cleanup)} usuário(s)")
        
        success_count = 0
        for uid, token in users_to_cleanup:
            logger.info(f"  🗑️  Processando usuário {uid}")
            if delete_user_completely(client, uid, token):
                success_count += 1
        
        logger.info(f"✅ Cleanup manual concluído: {success_count}/{len(users_to_cleanup)} usuários removidos")

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
                        "password123",
                        "test123",
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
                    
                    # Deletar usuário completamente
                    delete_user_completely(client, uid, token)
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
    """Cria um usuário de teste e registra automaticamente para cleanup"""
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
    
    # Registrar para cleanup manual automático
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

@pytest.fixture
def unique_user_data():
    """Gera dados de usuário únicos para testes que precisam criar múltiplos usuários"""
    unique_id = uuid.uuid4().hex[:8]
    return {
        "username": f"unique_{unique_id}",
        "email": f"unique_{unique_id}@example.com",
        "password": "testpassword123",
        "detection_time": "12:00:00",
        "emergency_contact": [
            {
                "name": "Test Contact",
                "phone": "+5511999999999"
            }
        ]
    }