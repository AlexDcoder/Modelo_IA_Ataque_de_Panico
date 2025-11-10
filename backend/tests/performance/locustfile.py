from locust import HttpUser, task, between
import random
import json
import time
from datetime import datetime, timedelta

class PanicAttackUser(HttpUser):
    """Usuário virtual completo para teste de carga com agendamento de dados vitais"""
    wait_time = between(1, 3)
    
    def on_start(self):
        """Setup inicial para cada usuário virtual"""
        self.user_id = f"loadtest{random.randint(10000, 99999)}"
        self.email = f"{self.user_id}@test.com"
        self.password = "TestPassword123!"
        self.uid = None
        self.token = None
        self.refresh_token = None
        self.headers = {}
        
        # Configuração do detection_time (intervalo entre envios de dados vitais)
        self.detection_interval = random.randint(10, 30)  # 10-30 segundos entre envios
        self.last_vital_send = 0  # Timestamp do último envio
        self.vital_data_count = 0  # Contador de envios
        
        print(f"🔄 Iniciando usuário: {self.user_id} (detection_interval: {self.detection_interval}s)")
        
        # Fluxo inicial obrigatório (registro → login → perfil)
        if not self.register_user():
            print("❌ Falha no registro. Encerrando usuário.")
            self.stop(True)
            return
        
        if not self.login_user():
            print("❌ Falha no login. Encerrando usuário.")
            self.stop(True)
            return
        
        if not self.get_user_profile():
            print("⚠️  Não foi possível obter o perfil. Encerrando usuário.")
            self.stop(True)
            return

    # ===============================================================
    # MÉTODO CENTRAL DE VALIDAÇÃO
    # ===============================================================
    def ensure_authenticated(self):
        """Garante que o usuário ainda tem token e UID válidos."""
        if not self.headers or not self.token or not self.uid:
            print("⚠️  Usuário não autenticado. Encerrando execução deste usuário.")
            self.stop(True)
            return False
        return True

    def should_send_vital_data(self):
        """Verifica se é hora de enviar dados vitais baseado no detection_interval"""
        current_time = time.time()
        if current_time - self.last_vital_send >= self.detection_interval:
            self.last_vital_send = current_time
            return True
        return False

    # ===============================================================
    # REGISTRO, LOGIN E PERFIL
    # ===============================================================
    def register_user(self):
        """ROTA: POST /users/ - Criação de usuário"""
        user_data = {
            "username": self.user_id,
            "email": self.email,
            "password": self.password,
            "detection_time": f"{random.randint(0,23):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}",
            "emergency_contact": [
                {"name": "Emergency Contact 1", "phone": "+5511999999999"}
            ]
        }
        
        with self.client.post("/users/", json=user_data, catch_response=True, name="01-register-user") as response:
            if response.status_code in [200, 201]:
                try:
                    data = response.json()
                    self.uid = data.get("uid")
                    if self.uid:
                        print(f"✅ Registro bem-sucedido. UID: {self.uid}")
                        return True
                    else:
                        response.failure("UID não retornado")
                except json.JSONDecodeError:
                    response.failure("Resposta não é JSON válido")
            else:
                print(f"❌ Falha no registro: {response.status_code} - {response.text}")
                response.failure("Falha no registro")
        return False

    def login_user(self):
        """ROTA: POST /auth/login - Autenticação"""
        login_data = {"email": self.email, "password": self.password}
        
        with self.client.post("/auth/login", json=login_data, catch_response=True, name="02-login-user") as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    self.token = data.get("access_token")
                    self.refresh_token = data.get("refresh_token")
                    if self.token:
                        self.headers = {"Authorization": f"Bearer {self.token}"}
                        print("✅ Login bem-sucedido")
                        return True
                    else:
                        response.failure("Token não recebido")
                except json.JSONDecodeError:
                    response.failure("Resposta de login inválida")
            else:
                print(f"❌ Falha no login: {response.status_code}")
                response.failure("Falha no login")
        return False

    def get_user_profile(self):
        """ROTA: GET /users/me"""
        if not self.ensure_authenticated():
            return False
        
        with self.client.get("/users/me", headers=self.headers, catch_response=True, name="03-get-user-profile") as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if not self.uid and 'uid' in data:
                        self.uid = data['uid']
                    print("✅ Perfil obtido com sucesso")
                    return True
                except json.JSONDecodeError:
                    response.failure("Resposta inválida do perfil")
            else:
                response.failure(f"Get profile failed: {response.status_code}")
        return False

    # ===============================================================
    # TASKS PRINCIPAIS COM TIMING DIFERENCIADO
    # ===============================================================

    @task(3)
    def refresh_token_task(self):
        """ROTA: POST /auth/refresh - Executada ocasionalmente"""
        if not self.refresh_token:
            return
        refresh_data = {"refresh_token": self.refresh_token}
        with self.client.post("/auth/refresh", json=refresh_data, catch_response=True, name="04-refresh-token") as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    new_token = data.get("access_token")
                    if new_token:
                        self.token = new_token
                        self.headers = {"Authorization": f"Bearer {new_token}"}
                        print("✅ Token renovado com sucesso")
                except json.JSONDecodeError:
                    response.failure("Resposta inválida no refresh")
            else:
                response.failure("Falha ao renovar token")

    @task(8)  # Alta frequência para verificar se deve enviar dados vitais
    def scheduled_vital_data(self):
        """Task que verifica o agendamento e envia dados vitais quando necessário"""
        if not self.ensure_authenticated(): 
            return
        
        # Verifica se é hora de enviar dados vitais
        if self.should_send_vital_data():
            self.send_vital_data()
        else:
            # Se não for hora, apenas registra que verificou
            # Isso mantém a task ativa sem gerar requests
            pass

    def send_vital_data(self):
        """Função interna para enviar dados vitais (chamada pelo agendador)"""
        vital_data = {
            "heart_rate": round(random.uniform(60.0, 120.0), 2),
            "respiration_rate": round(random.uniform(12.0, 25.0), 2),
            "accel_std": round(random.uniform(0.1, 3.0), 2),
            "spo2": round(random.uniform(90.0, 100.0), 2),
            "stress_level": round(random.uniform(1.0, 10.0), 2)
        }
        
        self.vital_data_count += 1
        print(f"❤️  [{self.vital_data_count}] Enviando dados vitais para {self.uid} (intervalo: {self.detection_interval}s)")
        
        with self.client.post(f"/vital-data/{self.uid}", json=vital_data, headers=self.headers,
                              catch_response=True, name="07-send-vital-data") as response:
            if response.status_code in [200, 201]:
                print(f"✅ Dados vitais [{self.vital_data_count}] enviados com sucesso")
            else:
                response.failure(f"Send vital data failed: {response.status_code}")

    @task(6)  # Frequência média - operações comuns do usuário
    def get_profile_repeated(self):
        """ROTA: GET /users/me - Verificação periódica do perfil"""
        if not self.ensure_authenticated(): 
            return
        self.client.get("/users/me", headers=self.headers, name="05-get-profile-repeated")

    @task(2)  # Baixa frequência - atualizações ocasionais
    def update_user_task(self):
        """ROTA: PUT /users/{uid} - Atualizações esporádicas"""
        if not self.ensure_authenticated(): 
            return
        update_data = {"username": f"{self.user_id}_updated", "detection_time": "15:45:00"}
        with self.client.put(f"/users/{self.uid}", json=update_data, headers=self.headers,
                             catch_response=True, name="06-update-user") as response:
            if response.status_code == 200:
                print("✅ Usuário atualizado com sucesso")
            else:
                response.failure(f"Update user failed: {response.status_code}")

    @task(4)  # Frequência média - verificações de dados
    def get_vital_data(self):
        """ROTA: GET /vital-data/{uid} - Consulta de dados armazenados"""
        if not self.ensure_authenticated(): 
            return
        with self.client.get(f"/vital-data/{self.uid}", headers=self.headers,
                             catch_response=True, name="08-get-vital-data") as response:
            if response.status_code == 200:
                print("✅ Dados vitais obtidos com sucesso")
            elif response.status_code == 404:
                print("⚠️  Dados vitais não encontrados (esperado para primeiro acesso)")
            else:
                response.failure(f"Get vital data failed: {response.status_code}")

    @task(5)  # Frequência média-alta - predições importantes
    def predict_panic_attack(self):
        """ROTA: POST /ai/predict - Predições regulares"""
        if not self.ensure_authenticated(): 
            return
        prediction_data = {
            "heart_rate": round(random.uniform(60.0, 150.0), 2),
            "respiration_rate": round(random.uniform(10.0, 30.0), 2),
            "accel_std": round(random.uniform(0.1, 5.0), 2),
            "spo2": round(random.uniform(85.0, 100.0), 2),
            "stress_level": round(random.uniform(1.0, 10.0), 2)
        }
        with self.client.post("/ai/predict", json=prediction_data, headers=self.headers,
                              catch_response=True, name="09-ai-predict") as response:
            if response.status_code == 200:
                try:
                    result = response.json()
                    panic_status = "DETECTADO" if result.get('panic_attack_detected', False) else "não detectado"
                    print(f"✅ Predição: Ataque de pânico {panic_status}")
                except json.JSONDecodeError:
                    response.failure("Resposta inválida da IA")
            else:
                response.failure(f"Predict failed: {response.status_code}")

    @task(1)  # Baixa frequência - feedbacks esporádicos
    def send_feedback(self):
        """ROTA: POST /feedback/ - Feedbacks ocasionais"""
        if not self.ensure_authenticated(): 
            return
        feedback_data = {
            "uid": self.uid,
            "features": {
                "heart_rate": round(random.uniform(60.0, 120.0), 2),
                "respiration_rate": round(random.uniform(12.0, 25.0), 2),
                "accel_std": round(random.uniform(0.1, 3.0), 2),
                "spo2": round(random.uniform(90.0, 100.0), 2),
                "stress_level": round(random.uniform(1.0, 10.0), 2)
            },
            "user_feedback": random.randint(0, 1)
        }
        with self.client.post("/feedback/", json=feedback_data, headers=self.headers,
                              catch_response=True, name="10-send-feedback") as response:
            if response.status_code == 200:
                feedback_type = "positivo" if feedback_data['user_feedback'] == 1 else "negativo"
                print(f"✅ Feedback {feedback_type} enviado")
            else:
                response.failure(f"Send feedback failed: {response.status_code}")

    @task(15)  # Muito frequente - health checks constantes
    def health_check(self):
        """ROTA: GET / - Health check (pública) - Muito frequente"""
        self.client.get("/", name="11-health-check")

    @task(2)  # Baixa frequência - verificações públicas
    def get_public_user_info(self):
        """ROTA: GET /users/{uid} - Consulta pública ocasional"""
        if not self.uid:
            return

        headers = self.headers if self.headers else {}

        with self.client.get(f"/users/{self.uid}",
                            headers=headers,
                            catch_response=True,
                            name="12-get-public-user") as response:

            if response.status_code == 200:
                print("✅ Informações públicas do usuário obtidas com sucesso")
                response.success()
            elif response.status_code == 404:
                print("⚠️  Usuário não encontrado (provavelmente já deletado)")
                response.success()
            elif response.status_code == 401:
                print("⚠️  Acesso negado — rota requer autenticação")
                response.failure("Rota pública requer token")
            else:
                response.failure(f"Falha ao obter info pública: {response.status_code}")

    @task(1)  # Muito baixa frequência - limpeza rara
    def cleanup_user(self):
        """ROTA: DELETE /users/{uid} - Limpeza muito ocasional"""
        if not self.ensure_authenticated(): 
            return
        if random.random() < 0.05:  # Apenas 5% de chance a cada execução
            print(f"🗑️  Tentando deletar o usuário: {self.uid}")
            with self.client.delete(f"/users/{self.uid}", headers=self.headers,
                                    catch_response=True, name="13-delete-user") as response:
                if response.status_code == 200:
                    print(f"✅ Usuário {self.uid} deletado com sucesso. Encerrando este usuário.")
                    self.uid = None
                    self.token = None
                    self.refresh_token = None
                    self.headers = {}
                    self.stop(True)
                elif response.status_code == 404:
                    print(f"⚠️  Usuário {self.uid} já não existe. Encerrando execução.")
                    self.uid = None
                    self.token = None
                    self.refresh_token = None
                    self.headers = {}
                    self.stop(True)
                else:
                    response.failure(f"Falha ao deletar usuário: {response.status_code}")

    def on_stop(self):
        print(f"🛑 Usuário {getattr(self, 'user_id', 'unknown')} finalizado. Total de dados vitais enviados: {getattr(self, 'vital_data_count', 0)}")