import pandas as pd
import numpy as np
from core.logger import get_logger
from core.config import DATA_PATH
from core.ai.model import PanicDetectionModel

logger = get_logger(__name__)

class AIService:
    def __init__(self) -> None:
        self._data = pd.read_csv(DATA_PATH)
        self._model = PanicDetectionModel(data=self._data)
        self._model.start_model()
    
    def predict(self, info: dict) -> bool:
        """Faz predição baseada apenas nos dados vitais, sem UID"""
        logger.info(f"Realizing prediction with data: {info}")
        
        result = self._model.predict_information(info=info)
        
        logger.info(f"Prediction result: {result}")
        return result
    
    def set_feedback(self, features: dict, label: int):
        """Recebe feedback sem vincular a usuário específico"""
        logger.info(f"Receiving feedback: {features} -> {label}")
        
        input_df = pd.DataFrame([features])
        match = self._data[
            self._data[list(features.keys())].apply(
            lambda row: np.all(np.isclose(row.values, input_df.values[0], atol=1e-4)),
            axis=1
        )]

        if not match.empty:
            self._data.loc[match.index, 'panic_attack'] = label
            logger.info("Feedback added for existing data")
        else:
            new_row = {**features, 'panic_attack': label}
            self._data = pd.concat([self._data, pd.DataFrame([new_row])], ignore_index=True)
            logger.info("New feedback data added")

        self._data.to_csv(DATA_PATH, index=False)
        self._model.update_data(self._data)
        self._model.start_model()
        logger.info("AI model retrained with new feedback")