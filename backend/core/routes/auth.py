from fastapi import APIRouter, Depends, HTTPException, status
from core.services.db_service import DBService
from core.db.connector import RTDBConnector
from core.security.jwt_handler import JWTHandler
from core.security.password import verify_password
from core.schemas.dto.user_dto import UserLoginDTO
from core.schemas.auth import Token, RefreshTokenRequest
from core.logger import get_logger
from core.dependencies import get_db_service

logger = get_logger(__name__)
router = APIRouter(tags=["authentication"])

@router.post("/login", response_model=Token)
async def login(
    credentials: UserLoginDTO, 
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"Login attempt for email: {credentials.email}")
        
        # Buscar usuário por email
        users = db_service.get_all_users() or {}
        logger.info(f"Available users: {list(users.keys())}")
        
        user_data = None
        user_uid = None
        
        for uid, user in users.items():
            logger.info(f"Checking user {uid}: {user.get('email')}")
            if user.get("email") == credentials.email:
                user_data = user
                user_uid = uid
                logger.info(f"User found with UID: {user_uid}")
                break
        
        if not user_data:
            logger.warning(f"Login attempt with non-existent email: {credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Verificar se a senha existe no usuário
        if 'password' not in user_data:
            logger.error(f"User {user_uid} has no password stored")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User configuration error"
            )
        
        if not verify_password(credentials.password, user_data["password"]):
            logger.warning(f"Invalid password attempt for user: {credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Gerar tokens
        access_token = JWTHandler.create_access_token({"sub": user_uid})
        refresh_token = JWTHandler.create_refresh_token({"sub": user_uid})
        
        logger.info(f"User {user_uid} logged in successfully")
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error during authentication"
        )

@router.post("/refresh", response_model=Token)
async def refresh_token(
    request: RefreshTokenRequest
):
    try:
        payload = JWTHandler.decode_token(request.refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Verificar se o usuário ainda existe
        try:
            connector = RTDBConnector()
            db_service = DBService(connector)
            user = db_service.get_user(user_id)
            if user is None:
                logger.warning(f"Refresh token for non-existent user: {user_id}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User no longer exists"
                )
        except Exception as e:
            logger.error(f"Error checking user existence: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user"
            )
        
        new_access_token = JWTHandler.create_access_token({"sub": user_id})
        
        logger.info(f"Token refreshed for user: {user_id}")
        return Token(
            access_token=new_access_token,
            token_type="bearer"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )