from locust import HttpUser, task, between, TaskSet
import random
import time
import json

class PanicAttackUser(HttpUser):
    """Usuário virtual completo para teste de carga"""
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
        
        print(f"🔄 Iniciando usuário: {self.user_id}")
        
        # Fluxo inicial obrigatório
        if self.register_user():
            time.sleep(1)
            if self.login_user():
                time.sleep(1)
                self.get_user_profile()
    
    def register_user(self):
        """ROTA: POST /users/ - UserCreateDTO schema"""
        user_data = {
            "username": self.user_id,
            "email": self.email,
            "password": self.password,
            "detection_time": "14:30:00",
            "emergency_contact": [
                {
                    "name": "Emergency Contact 1",
                    "phone": "+5511999999999"
                }
            ]
        }
        
        with self.client.post("/users/", 
                            json=user_data, 
                            catch_response=True, 
                            name="01-register-user") as response:
            
            if response.status_code in [200, 201]:
                try:
                    response_data = response.json()
                    self.uid = response_data.get('uid')
                    if self.uid:
                        print(f"✅ Registro bem-sucedido. UID: {self.uid}")
                        return True
                    else:
                        response.failure("UID não retornado no registro")
                        return False
                except json.JSONDecodeError:
                    response.failure("Resposta não é JSON válido")
                    return False
            else:
                print(f"❌ Falha no registro: {response.status_code} - {response.text}")
                response.failure(f"Register failed: {response.status_code}")
                return False
    
    def login_user(self):
        """ROTA: POST /auth/login - UserLoginDTO schema"""
        login_data = {
            "email": self.email,
            "password": self.password
        }
        
        with self.client.post("/auth/login", 
                            json=login_data, 
                            catch_response=True, 
                            name="02-login-user") as response:
            
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    self.token = response_data.get("access_token")
                    self.refresh_token = response_data.get("refresh_token")
                    
                    if self.token:
                        self.headers = {"Authorization": f"Bearer {self.token}"}
                        print(f"✅ Login bem-sucedido")
                        return True
                    else:
                        response.failure("Token não recebido")
                        return False
                except json.JSONDecodeError:
                    response.failure("Resposta de login não é JSON válido")
                    return False
            else:
                print(f"❌ Falha no login: {response.status_code}")
                response.failure(f"Login failed: {response.status_code}")
                return False
    
    def get_user_profile(self):
        """ROTA: GET /users/me - UserResponseDTO schema"""
        if not self.headers:
            return False
            
        with self.client.get("/users/me", 
                           headers=self.headers, 
                           catch_response=True, 
                           name="03-get-user-profile") as response:
            
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    if not self.uid and 'uid' in response_data:
                        self.uid = response_data.get('uid')
                    print(f"✅ Perfil obtido com sucesso")
                    return True
                except json.JSONDecodeError:
                    response.failure("Resposta do perfil não é JSON válido")
                    return False
            else:
                print(f"❌ Falha ao obter perfil: {response.status_code}")
                response.failure(f"Get profile failed: {response.status_code}")
                return False

    # ========== TASKS PRINCIPAIS ==========
    
    @task(3)
    def refresh_token_task(self):
        """ROTA: POST /auth/refresh - RefreshTokenRequest schema"""
        if not hasattr(self, 'refresh_token') or not self.refresh_token:
            return
            
        refresh_data = {
            "refresh_token": self.refresh_token
        }
        
        with self.client.post("/auth/refresh", 
                            json=refresh_data, 
                            catch_response=True, 
                            name="04-refresh-token") as response:
            
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    new_token = response_data.get("access_token")
                    if new_token:
                        self.token = new_token
                        self.headers = {"Authorization": f"Bearer {new_token}"}
                        print(f"✅ Token renovado com sucesso")
                except json.JSONDecodeError:
                    response.failure("Resposta do refresh não é JSON válido")
            else:
                response.failure(f"Refresh failed: {response.status_code}")
    
    @task(5)
    def get_profile_repeated(self):
        """ROTA: GET /users/me - UserResponseDTO schema"""
        if self.headers and self.uid:
            self.client.get("/users/me", 
                          headers=self.headers,
                          name="05-get-profile-repeated")
    
    @task(2)
    def update_user_task(self):
        """ROTA: PUT /users/{uid} - UserUpdateDTO schema"""
        if not self.headers or not self.uid:
            return False
            
        update_data = {
            "username": f"{self.user_id}_updated",
            "detection_time": "15:45:00"
        }
        
        with self.client.put(f"/users/{self.uid}", 
                           json=update_data, 
                           headers=self.headers, 
                           catch_response=True,
                           name="06-update-user") as response:
            
            if response.status_code == 200:
                print(f"✅ Usuário atualizado com sucesso")
                return True
            else:
                response.failure(f"Update user failed: {response.status_code}")
                return False

    # ========== DADOS VITAIS (AGORA FUNCIONANDO) ==========
    
    @task(8)  # Alta frequência - dados vitais são enviados frequentemente
    def send_vital_data(self):
        """ROTA: POST /vital-data/{uid} - UserVitalData schema"""
        if not self.headers or not self.uid:
            print("❌ Headers ou UID não disponíveis para enviar dados vitais")
            return False
            
        # Gerar dados vitais realistas
        vital_data = {
            "heart_rate": round(random.uniform(60.0, 120.0), 2),
            "respiration_rate": round(random.uniform(12.0, 25.0), 2),
            "accel_std": round(random.uniform(0.1, 3.0), 2),
            "spo2": round(random.uniform(90.0, 100.0), 2),
            "stress_level": round(random.uniform(1.0, 10.0), 2)
        }
        
        print(f"❤️  Enviando dados vitais para usuário {self.uid}")
        
        with self.client.post(f"/vital-data/{self.uid}", 
                            json=vital_data, 
                            headers=self.headers, 
                            catch_response=True,
                            name="07-send-vital-data") as response:
            
            if response.status_code in [200, 201]:
                print(f"✅ Dados vitais enviados com sucesso")
                return True
            else:
                print(f"❌ Falha ao enviar dados vitais: {response.status_code} - {response.text}")
                response.failure(f"Send vital data failed: {response.status_code}")
                return False
    
    @task(4)
    def get_vital_data(self):
        """ROTA: GET /vital-data/{uid} - VitalResponseDTO schema"""
        if not self.headers or not self.uid:
            return False
            
        with self.client.get(f"/vital-data/{self.uid}", 
                           headers=self.headers, 
                           catch_response=True,
                           name="08-get-vital-data") as response:
            
            if response.status_code == 200:
                print(f"✅ Dados vitais obtidos com sucesso")
                return True
            elif response.status_code == 404:
                print(f"⚠️  Dados vitais não encontrados (esperado para primeiro acesso)")
                return True  # 404 é válido se não houver dados ainda
            else:
                response.failure(f"Get vital data failed: {response.status_code}")
                return False

    # ========== IA & PREDIÇÕES ==========
    
    @task(6)
    def predict_panic_attack(self):
        """ROTA: POST /ai/predict - UserVitalData schema"""
        if not self.headers:
            return False
            
        # Dados para predição (podem ser diferentes dos dados vitais reais)
        prediction_data = {
            "heart_rate": round(random.uniform(60.0, 150.0), 2),  # Faixa mais ampla para teste
            "respiration_rate": round(random.uniform(10.0, 30.0), 2),
            "accel_std": round(random.uniform(0.1, 5.0), 2),
            "spo2": round(random.uniform(85.0, 100.0), 2),
            "stress_level": round(random.uniform(1.0, 10.0), 2)
        }
        
        with self.client.post("/ai/predict", 
                            json=prediction_data, 
                            headers=self.headers, 
                            catch_response=True,
                            name="09-ai-predict") as response:
            
            if response.status_code == 200:
                try:
                    result = response.json()
                    panic_detected = result.get("panic_attack_detected", False)
                    print(f"✅ Predição realizada: Ataque de pânico = {panic_detected}")
                    return True
                except json.JSONDecodeError:
                    response.failure("Resposta da predição não é JSON válido")
                    return False
            else:
                response.failure(f"Predict failed: {response.status_code}")
                return False
    
    @task(2)
    def send_feedback(self):
        """ROTA: POST /feedback/ - FeedbackInput schema"""
        if not self.headers or not self.uid:
            return False
            
        feedback_data = {
            "uid": self.uid,
            "features": {
                "heart_rate": round(random.uniform(60.0, 120.0), 2),
                "respiration_rate": round(random.uniform(12.0, 25.0), 2),
                "accel_std": round(random.uniform(0.1, 3.0), 2),
                "spo2": round(random.uniform(90.0, 100.0), 2),
                "stress_level": round(random.uniform(1.0, 10.0), 2)
            },
            "user_feedback": random.randint(0, 1)  # 0 ou 1
        }
        
        with self.client.post("/feedback/", 
                            json=feedback_data, 
                            headers=self.headers, 
                            catch_response=True,
                            name="10-send-feedback") as response:
            
            if response.status_code == 200:
                print(f"✅ Feedback enviado: {feedback_data['user_feedback']}")
                return True
            else:
                response.failure(f"Send feedback failed: {response.status_code}")
                return False

    # ========== HEALTH CHECKS ==========
    
    @task(10)
    def health_check(self):
        """ROTA: GET / - Health check (pública)"""
        self.client.get("/", name="11-health-check")
    
    @task(3)
    def get_public_user_info(self):
        """ROTA: GET /users/{uid} - UserPublicDTO schema"""
        if self.uid:
            self.client.get(f"/users/{self.uid}", 
                          name="12-get-public-user")
    
    @task(1)
    def cleanup_user(self):
        """ROTA: DELETE /users/{uid} - Limpeza opcional"""
        # Esta task tem baixa frequência para não interferir nos testes principais
        if self.headers and self.uid and random.random() < 0.1:  # 10% de chance
            print(f"🗑️  Executando limpeza do usuário: {self.uid}")
            
            with self.client.delete(f"/users/{self.uid}", 
                                  headers=self.headers, 
                                  catch_response=True,
                                  name="13-delete-user") as response:
                
                if response.status_code == 200:
                    print(f"✅ Usuário deletado com sucesso")
                    # Interrompe este usuário virtual
                    self.stop(True)
                else:
                    print(f"❌ Falha na deleção: {response.status_code}")

    def on_stop(self):
        """Limpeza quando usuário para"""
        print(f"🛑 Usuário {getattr(self, 'user_id', 'unknown')} finalizado")