from locust import HttpUser, task, between, TaskSet
import random
import string

class AuthTasks(TaskSet):
    """Tarefas relacionadas à autenticação"""
    
    def on_start(self):
        """Executado quando um usuário virtual inicia"""
        # Gerar username alfanumérico (sem underscore)
        self.user_id = f"test{random.randint(1000, 9999)}"
        self.email = f"{self.user_id}@test.com"
        self.password = "Test12345"
        self.uid = None
        self.token = None
        self.headers = {}
        
        # Fluxo sequencial
        if self.register_user():
            if self.login():
                self.get_my_uid()
    
    def register_user(self):
        """Registrar usuário"""
        user_data = {
            "username": self.user_id,
            "email": self.email,
            "password": self.password,
            "detection_time": "12:00:00",
            "emergency_contact": [
                {
                    "name": "Test Contact",
                    "phone": "+5511999999999"
                }
            ]
        }
        
        with self.client.post("/users/", json=user_data, catch_response=True, name="/register") as response:
            if response.status_code in [200, 201]:
                print(f"✅ Registro bem-sucedido: {self.email}")
                return True
            else:
                print(f"❌ Falha no registro: {response.status_code} - {response.text}")
                response.failure(f"Register failed: {response.status_code}")
                return False
    
    def login(self):
        """Fazer login"""
        login_data = {
            "email": self.email,
            "password": self.password
        }
        
        with self.client.post("/auth/login", json=login_data, catch_response=True, name="/login") as response:
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    self.token = response_data.get("access_token")
                    if self.token:
                        self.headers = {"Authorization": f"Bearer {self.token}"}
                        print(f"✅ Login bem-sucedido: {self.email}")
                        return True
                    else:
                        response.failure("No token in response")
                        return False
                except Exception as e:
                    response.failure(f"Login parse error: {str(e)}")
                    return False
            else:
                response.failure(f"Login failed: {response.status_code}")
                return False
    
    def get_my_uid(self):
        """Obter UID da rota /me"""
        if self.headers:
            with self.client.get("/users/me", headers=self.headers, catch_response=True, name="/me") as response:
                if response.status_code == 200:
                    try:
                        response_data = response.json()
                        self.uid = response_data.get('uid')
                        if self.uid:
                            self.user.uid = self.uid
                            print(f"✅ UID obtido: {self.uid}")
                            response.success()
                        else:
                            response.failure("UID not found in /me response")
                    except Exception as e:
                        response.failure(f"Error parsing /me: {str(e)}")
                else:
                    response.failure(f"Failed to get /me: {response.status_code}")
    
    @task(3)
    def get_user_profile(self):
        """Buscar perfil do usuário"""
        if self.headers:
            self.client.get("/users/me", headers=self.headers, name="/users/me")

class VitalDataTasks(TaskSet):
    """Tarefas relacionadas a dados vitais"""
    
    @task(3)
    def submit_vital_data(self):
        """Enviar dados vitais"""
        if hasattr(self.user, 'uid') and self.user.uid and hasattr(self.user, 'headers') and self.user.headers:
            vital_data = {
                "heart_rate": random.uniform(60, 120),
                "respiration_rate": random.uniform(12, 25),
                "accel_std": random.uniform(0.05, 0.5),
                "spo2": random.uniform(90, 100),
                "stress_level": random.uniform(1, 10)
            }
            
            self.client.post(
                f"/vital-data/{self.user.uid}", 
                json=vital_data, 
                headers=self.user.headers,
                name="/vital-data"
            )
    
    @task(2)
    def get_vital_data(self):
        """Buscar dados vitais"""
        if hasattr(self.user, 'uid') and self.user.uid and hasattr(self.user, 'headers') and self.user.headers:
            self.client.get(
                f"/vital-data/{self.user.uid}",
                headers=self.user.headers,
                name="/vital-data"
            )

class AITasks(TaskSet):
    """Tarefas relacionadas à IA"""
    
    @task(3)
    def get_panic_prediction(self):
        """Obter predição de ataque de pânico"""
        if hasattr(self.user, 'headers') and self.user.headers:
            prediction_data = {
                "heart_rate": random.uniform(60, 120),
                "respiration_rate": random.uniform(12, 25),
                "accel_std": random.uniform(0.05, 0.5),
                "spo2": random.uniform(90, 100),
                "stress_level": random.uniform(1, 10)
            }
            
            self.client.post(
                "/ai/predict", 
                json=prediction_data, 
                headers=self.user.headers,
                name="/ai/predict"
            )
    
    @task(1)
    def submit_feedback(self):
        """Enviar feedback para IA"""
        if hasattr(self.user, 'uid') and self.user.uid and hasattr(self.user, 'headers') and self.user.headers:
            feedback_data = {
                "uid": self.user.uid,
                "features": {
                    "heart_rate": random.uniform(60, 120),
                    "respiration_rate": random.uniform(12, 25),
                    "accel_std": random.uniform(0.05, 0.5),
                    "spo2": random.uniform(90, 100),
                    "stress_level": random.uniform(1, 10)
                },
                "user_feedback": random.randint(0, 1)
            }
            
            self.client.post(
                "/feedback/", 
                json=feedback_data, 
                headers=self.user.headers,
                name="/feedback"
            )

class NormalUser(HttpUser):
    """Usuário normal"""
    wait_time = between(3, 8)
    tasks = [AuthTasks, VitalDataTasks, AITasks]
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.uid = None
        self.headers = {}

class HealthCheckUser(HttpUser):
    """Usuário apenas para health checks"""
    wait_time = between(2, 5)
    
    @task(10)
    def health_check(self):
        """Apenas health checks"""
        self.client.get("/", name="/health")

class SimpleAuthUser(HttpUser):
    """Usuário simples apenas com autenticação"""
    wait_time = between(5, 10)
    
    def on_start(self):
        self.user_id = f"user{random.randint(1000, 9999)}"
        self.email = f"{self.user_id}@test.com"
        self.password = "Test12345"
        self.uid = None
        self.token = None
        self.headers = {}
        
        with self.client.post("/auth/login", json={
            "email": self.email,
            "password": self.password
        }, catch_response=True) as response:
            if response.status_code == 200:
                try:
                    self.token = response.json().get("access_token")
                    if self.token:
                        self.headers = {"Authorization": f"Bearer {self.token}"}
                        print(f"✅ Login simples bem-sucedido: {self.email}")
                    else:
                        response.failure("No token in simple login")
                except Exception as e:
                    response.failure(f"Simple login parse error: {str(e)}")
            else:
                response.failure(f"Simple login failed: {response.status_code}")
    
    @task(5)
    def get_profile(self):
        """Acessar perfil"""
        if self.headers:
            self.client.get("/users/me", headers=self.headers)
    
    @task(3)
    def health_check(self):
        """Health check"""
        self.client.get("/", name="/health_simple")