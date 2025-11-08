from locust import HttpUser, task, between
import random
import json

class PanicDetectionUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Login when a user starts"""
        self.user_id = f"test-user-{random.randint(1000, 9999)}"
        self.email = f"test{random.randint(1000, 9999)}@example.com"
        self.username = f"user{random.randint(1000, 9999)}"
        self.login()
    
    def login(self):
        # Try to login first, if fails, register
        login_data = {
            "email": self.email,
            "password": "TestPassword123"
        }
        response = self.client.post("/auth/login", json=login_data)
        
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            self.headers = {"Authorization": f"Bearer {self.token}"}
        else:
            # If login fails, register new user
            self.register()
            self.login()
    
    def register(self):
        user_data = {
            "username": self.username,
            "email": self.email,
            "password": "TestPassword123",
            "detection_time": "10:00:00",
            "emergency_contact": [
                {
                    "name": "Emergency Contact",
                    "phone": "+5511999999999"
                }
            ]
        }
        response = self.client.post("/users/", json=user_data)
        if response.status_code == 200:
            self.user_id = response.json().get("uid", self.user_id)
    
    @task(3)
    def predict_panic_attack(self):
        """CT05, CT09: Simulate panic attack prediction requests"""
        vital_data = {
            "heart_rate": random.uniform(60, 120),
            "respiration_rate": random.uniform(12, 25),
            "accel_std": random.uniform(0.1, 2.0),
            "spo2": random.uniform(90, 100),
            "stress_level": random.uniform(1, 10)
        }
        self.client.post("/ai/predict", json=vital_data, headers=self.headers)
    
    @task(2)
    def update_vital_data(self):
        """CT04: Simulate vital data updates"""
        vital_data = {
            "heart_rate": random.uniform(60, 120),
            "respiration_rate": random.uniform(12, 25),
            "accel_std": random.uniform(0.1, 2.0),
            "spo2": random.uniform(90, 100),
            "stress_level": random.uniform(1, 10)
        }
        self.client.post(f"/vital-data/{self.user_id}", json=vital_data, headers=self.headers)
    
    @task(1)
    def send_feedback(self):
        """CT07: Simulate user feedback"""
        feedback_data = {
            "uid": self.user_id,
            "features": {
                "heart_rate": random.uniform(60, 120),
                "respiration_rate": random.uniform(12, 25),
                "accel_std": random.uniform(0.1, 2.0),
                "spo2": random.uniform(90, 100),
                "stress_level": random.uniform(1, 10)
            },
            "user_feedback": random.randint(0, 1)
        }
        self.client.post("/feedback/", json=feedback_data, headers=self.headers)
    
    @task(1)
    def get_user_info(self):
        """Get current user information"""
        self.client.get("/users/me", headers=self.headers)
    
    @task(1)
    def get_vital_data(self):
        """Get user vital data"""
        self.client.get(f"/vital-data/{self.user_id}", headers=self.headers)

class WebsiteUser(HttpUser):
    wait_time = between(5, 9)
    
    @task(3)
    def health_check(self):
        """Health check endpoint"""
        self.client.get("/")
    
    @task(1)
    def public_endpoints(self):
        """Test public endpoints"""
        self.client.get("/docs")
        self.client.get("/redoc")

class HighLoadUser(HttpUser):
    wait_time = between(0.1, 0.5)
    
    def on_start(self):
        """Quick login for high load testing"""
        self.headers = {"Authorization": "Bearer mock-token-for-load-testing"}
    
    @task(10)
    def rapid_predictions(self):
        """Rapid fire predictions for stress testing"""
        vital_data = {
            "heart_rate": random.uniform(60, 120),
            "respiration_rate": random.uniform(12, 25),
            "accel_std": random.uniform(0.1, 2.0),
            "spo2": random.uniform(90, 100),
            "stress_level": random.uniform(1, 10)
        }
        self.client.post("/ai/predict", json=vital_data, headers=self.headers)