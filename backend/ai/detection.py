import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from typing import Any, Dict

class PanicDetectionModel:
    def __init__(self, data: pd.DataFrame) -> None:
        self._data = data
        self._model = LogisticRegression()
        self._scaler = StandardScaler()
        # Mantém a ordem das colunas para o predict
        self._feature_order: list[str] = []

    def start_model(self) -> None:
        # Separa X e y como DataFrame, mas depois converte para array
        X_df = self._data.iloc[:, :-1]
        y = self._data.iloc[:, -1].values

        # Guarda a ordem original das features
        self._feature_order = X_df.columns.tolist()

        # Converte para NumPy arrays
        X = X_df.values

        # Treina/testa
        X_train, X_test, y_train, _ = train_test_split(
            X, y, test_size=0.2, stratify=y, random_state=42
        )

        # Fit e train usando arrays
        self._scaler.fit(X_train)
        X_train_scaled = self._scaler.transform(X_train)
        self._model.fit(X_train_scaled, y_train)

    def predict_information(self, info: Dict[str, float]) -> Any:
        # Constrói o array na mesma ordem de colunas usada no fit
        final_array = np.array([[info[col] for col in self._feature_order]])
        # Aplica o scaler (não há feature_names_in_ armazenado)
        normalized_data = self._scaler.transform(final_array)
        return self._model.predict(normalized_data)

    def update_data(self, new_data: pd.DataFrame) -> None:
        self._data = new_data
