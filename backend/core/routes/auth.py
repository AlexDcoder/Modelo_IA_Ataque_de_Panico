from fastapi import APIRouter, Depends, HTTPException, status
from core.services.db_service import DBService
from core.db.connector import RTDBConnector
from core.security.jwt_handler import JWTHandler
from core.security.password import verify_password
from core.schemas.dto.user_dto import UserLoginDTO
from core.schemas.auth import Token, RefreshTokenRequest
from core.logger import get_logger
from core.dependencies import get_db_service
from jose import JWTError

logger = get_logger(__name__)
router = APIRouter(tags=["authentication"])

@router.post("/login", response_model=Token)
async def login(
    credentials: UserLoginDTO, 
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"🔄 [AUTH_LOGIN] Login attempt for email: {credentials.email}")
        
        # Buscar usuário por email
        users = db_service.get_all_users() or {}
        logger.info(f"📊 [AUTH_LOGIN] Available users count: {len(users)}")
        
        user_data = None
        user_uid = None
        
        for uid, user in users.items():
            logger.debug(f"🔍 [AUTH_LOGIN] Checking user {uid}: {user.get('email')}")
            if user.get("email") == credentials.email:
                user_data = user
                user_uid = uid
                logger.info(f"✅ [AUTH_LOGIN] User found with UID: {user_uid}")
                break
        
        if not user_data:
            logger.warning(f"⚠️ [AUTH_LOGIN] Login attempt with non-existent email: {credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Verificar se a senha existe no usuário
        if 'password' not in user_data:
            logger.error(f"❌ [AUTH_LOGIN] User {user_uid} has no password stored")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="User configuration error"
            )
        
        if not verify_password(credentials.password, user_data["password"]):
            logger.warning(f"⚠️ [AUTH_LOGIN] Invalid password attempt for user: {credentials.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Gerar tokens
        access_token = JWTHandler.create_access_token({"sub": user_uid})
        refresh_token = JWTHandler.create_refresh_token({"sub": user_uid})
        
        logger.info(f"✅ [AUTH_LOGIN] User {user_uid} logged in successfully")
        logger.debug(f"🔑 [AUTH_LOGIN] Access token generated, refresh token generated")
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [AUTH_LOGIN] Error during login: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error during authentication"
        )

@router.post("/refresh", response_model=Token)
async def refresh_token(
    request: RefreshTokenRequest,
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info("🔄 [AUTH_REFRESH] Refresh token request received")
        
        # Decodificar o refresh token
        payload = JWTHandler.decode_token(request.refresh_token)
        
        # Verificar se é um refresh token
        if payload.get("type") != "refresh":
            logger.warning("⚠️ [AUTH_REFRESH] Invalid token type for refresh")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = payload.get("sub")
        if not user_id:
            logger.warning("⚠️ [AUTH_REFRESH] Refresh token without subject")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Verificar se o usuário ainda existe
        user = db_service.get_user(user_id)
        if user is None:
            logger.warning(f"⚠️ [AUTH_REFRESH] Refresh token for non-existent user: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User no longer exists"
            )
        
        # Gerar novo access token
        new_access_token = JWTHandler.create_access_token({"sub": user_id})
        
        # Opcional: gerar novo refresh token (rotacionar)
        new_refresh_token = JWTHandler.create_refresh_token({"sub": user_id})
        
        logger.info(f"✅ [AUTH_REFRESH] Token refreshed successfully for user: {user_id}")
        return Token(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            token_type="bearer"
        )
        
    except JWTError as e:
        logger.warning(f"⚠️ [AUTH_REFRESH] Invalid refresh token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [AUTH_REFRESH] Error refreshing token: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error refreshing token"
        )