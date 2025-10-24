import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from typing import Any, Dict

class PanicDetectionModel:
    def __init__(self, data: pd.DataFrame) -> None:
        self._data = data
        self._pipeline: Pipeline = Pipeline([
            ("scaler", StandardScaler()),
            ("classifier", LogisticRegression())
        ])
        self._feature_order: list[str] = []

    def start_model(self) -> None:
        X_df = self._data.iloc[:, :-1]
        y = self._data.iloc[:, -1].values

        self._feature_order = X_df.columns.tolist()

        X_train, _, y_train, _ = train_test_split(
            X_df, y, test_size=0.2, stratify=y, random_state=42
        )

        self._pipeline.fit(X_train, y_train)

    def predict_information(self, info: Dict[str, float]) -> Any:
        final_df = pd.DataFrame([[info[col] for col in self._feature_order]],
                                columns=self._feature_order)
        return self._pipeline.predict(final_df)[0]

    def update_data(self, new_data: pd.DataFrame) -> None:
        self._data = new_data