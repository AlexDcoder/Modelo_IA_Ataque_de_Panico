from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression

class PanicDetectionModel:
    def __init__(self, data):
        self.data = data

    def train_model(self):
        ...
    
    def predict(self, info: dict):
        ...