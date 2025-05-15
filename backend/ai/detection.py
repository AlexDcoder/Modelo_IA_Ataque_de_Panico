from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
import pandas as pd
import numpy as np
from typing import Any

class PanicDetectionModel:
    def __init__(self, data: pd.DataFrame) -> None:
        self._data = data
        self._model = LogisticRegression()
        self._scaler = StandardScaler()

    def start_model(self) -> None:
        X = self._data[
            [col for col in self._data.columns[: self._data.shape[1] - 1]]
        ]
        y = self._data[self._data.columns[self._data.shape[1] - 1]]

        X_train, X_test, y_train, _ = train_test_split(
            X, y, test_size=0.2, stratify=y, random_state=42)

        
        X_train = self._scaler.fit_transform(X_train)
        X_test = self._scaler.transform(X_test)
        
        self._model.fit(X_train, y_train)
    
    def predict_information(self, info: dict) -> Any:
        print(info.values())
        normalized_data = self._scaler.transform([list(info.values())])
        return self._model.predict(normalized_data)