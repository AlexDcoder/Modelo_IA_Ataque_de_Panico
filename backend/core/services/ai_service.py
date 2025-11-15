import pandas as pd
import numpy as np
from core.logger import get_logger
from core.config import DATA_PATH
from core.ai.model import PanicDetectionModel

logger = get_logger(__name__)

class AIService:
    def __init__(self) -> None:
        logger.info("🔄 [AI_SERVICE] Initializing AI Service")
        try:
            self._data = pd.read_csv(DATA_PATH)
            logger.info(f"✅ [AI_SERVICE] Data loaded successfully from {DATA_PATH}, shape: {self._data.shape}")
            self._model = PanicDetectionModel(data=self._data)
            self._model.start_model()
            logger.info("✅ [AI_SERVICE] AI Service initialized successfully")
        except Exception as e:
            logger.error(f"❌ [AI_SERVICE] Failed to initialize AI Service: {e}")
            raise
    
    def predict(self, info: dict) -> bool:
        """Faz predição baseada apenas nos dados vitais, sem UID"""
        logger.info(f"🔄 [AI_SERVICE] Starting prediction")
        logger.debug(f"📦 [AI_SERVICE] Prediction input data: {info}")
        
        try:
            result = self._model.predict_information(info=info)
            logger.info(f"✅ [AI_SERVICE] Prediction completed successfully")
            logger.debug(f"📄 [AI_SERVICE] Prediction result: {result}")
            return result
        except Exception as e:
            logger.error(f"❌ [AI_SERVICE] Prediction error: {e}")
            raise
    
    def set_feedback(self, features: dict, label: int):
        """Recebe feedback sem vincular a usuário específico"""
        logger.info(f"🔄 [AI_SERVICE] Starting feedback processing")
        logger.debug(f"📦 [AI_SERVICE] Feedback features: {features}, label: {label}")
        
        try:
            input_df = pd.DataFrame([features])
            match = self._data[
                self._data[list(features.keys())].apply(
                lambda row: np.all(np.isclose(row.values, input_df.values[0], atol=1e-4)),
                axis=1
            )]

            if not match.empty:
                self._data.loc[match.index, 'panic_attack'] = label
                logger.info(f"✅ [AI_SERVICE] Feedback added for existing data at index {match.index}")
            else:
                new_row = {**features, 'panic_attack': label}
                self._data = pd.concat([self._data, pd.DataFrame([new_row])], ignore_index=True)
                logger.info("✅ [AI_SERVICE] New feedback data added")

            self._data.to_csv(DATA_PATH, index=False)
            self._model.update_data(self._data)
            self._model.start_model()
            logger.info("✅ [AI_SERVICE] AI model retrained with new feedback")
        except Exception as e:
            logger.error(f"❌ [AI_SERVICE] Feedback processing error: {e}")
            raise