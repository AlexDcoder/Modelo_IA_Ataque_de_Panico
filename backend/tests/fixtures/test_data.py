def create_test_user():
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123",
        "detection_time": "12:00:00",
        "emergency_contact": [
            {
                "name": "Emergency Contact",
                "phone": "+5511999999999"
            }
        ]
    }

def create_test_vital_data():
    return {
        "heart_rate": 75.0,
        "respiration_rate": 16.0,
        "accel_std": 0.5,
        "spo2": 98.0,
        "stress_level": 3.0
    }

def create_panic_vital_data():
    return {
        "heart_rate": 120.0,
        "respiration_rate": 25.0,
        "accel_std": 2.5,
        "spo2": 85.0,
        "stress_level": 8.5
    }