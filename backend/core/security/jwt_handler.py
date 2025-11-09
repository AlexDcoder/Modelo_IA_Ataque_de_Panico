from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError, ExpiredSignatureError
from fastapi import HTTPException, status
from core.config import JWT_SECRET_KEY, ACCESS_TOKEN_EXPIRE_MINUTES, REFRESH_TOKEN_EXPIRE_DAYS, JWT_ALGORITHM

class JWTHandler:
    # Adicionar constantes da configuração
    SECRET_KEY = JWT_SECRET_KEY
    ALGORITHM = JWT_ALGORITHM
    ACCESS_TOKEN_EXPIRE_MINUTES = ACCESS_TOKEN_EXPIRE_MINUTES
    REFRESH_TOKEN_EXPIRE_DAYS = REFRESH_TOKEN_EXPIRE_DAYS
    
    @staticmethod
    def _now() -> datetime:
        return datetime.now(timezone.utc)
    
    @staticmethod
    def create_access_token(data: dict) -> str:
        expire = JWTHandler._now() + timedelta(minutes=JWTHandler.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {**data, "exp": expire}
        encoded_jwt = jwt.encode(to_encode, JWTHandler.SECRET_KEY, algorithm=JWTHandler.ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def create_refresh_token(data: dict) -> str:
        expire = JWTHandler._now() + timedelta(days=JWTHandler.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode = {**data, "exp": expire, "iat": JWTHandler._now(), "type": "refresh"}
        return jwt.encode(to_encode, JWTHandler.SECRET_KEY, algorithm=JWTHandler.ALGORITHM)
    
    @staticmethod
    def decode_token(token: str) -> dict:
        try:
            return jwt.decode(token, JWTHandler.SECRET_KEY, algorithms=[JWTHandler.ALGORITHM])
        except ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired"
            )
        except JWTError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail=f"Invalid token: {str(e)}"
            )