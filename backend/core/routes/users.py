from fastapi import APIRouter, Depends, HTTPException, status
from core.services.db_service import DBService
from core.logger import get_logger
from core.schemas.dto.user_dto import UserCreateDTO, UserResponseDTO, UserUpdateDTO, UserPublicDTO
from core.security.password import hash_password
from core.security.auth_middleware import get_current_user
from datetime import datetime
from core.dependencies import get_db_service

logger = get_logger(__name__)
router = APIRouter(prefix='', tags=['users'])

@router.get("/", response_model=dict)
async def get_all_users(
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    """
    Apenas para administradores - retorna todos os usuários
    """
    try:
        users = db_service.get_all_users() or {}
        logger.info(f"Found {len(users)} users in database")
        
        # Remover senhas dos dados retornados
        for uid in users:
            if 'password' in users[uid]:
                del users[uid]['password']
                
        return users
    except Exception as e:
        logger.error(f"Error getting all users: {e}")
        raise HTTPException(status_code=500, detail="Error getting users")

@router.get("/me", response_model=UserResponseDTO)
async def get_current_user_info(
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    """Retorna informações do usuário atual"""
    try:
        logger.info(f"Searching for user with UID: {current_user}")
        user = db_service.get_user(current_user)
        
        if user is None:
            logger.warning(f"User not found with UID: {current_user}")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        logger.info(f"User found: {user.get('username')} - {user.get('email')}")
        
        # Remover senha antes de retornar
        if 'password' in user:
            del user['password']
            
        return UserResponseDTO(uid=current_user, **user)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting user")

@router.get("/{uid}", response_model=UserPublicDTO)
async def get_user_public(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    """Retorna informações públicas de um usuário (sem dados sensíveis)"""
    try:
        logger.info(f"Searching for public user data with UID: {uid}")
        
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            logger.warning(f"User not found with UID: {uid}")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        logger.info(f"Public user data found for: {user.get('username')}")
        
        # Remover dados sensíveis
        user_public = {
            'uid': uid,
            'username': user.get('username'),
            'email': user.get('email'),
            'detection_time': user.get('detection_time')
        }
        
        return UserPublicDTO(**user_public)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting user")

@router.post("/", response_model=UserResponseDTO)
async def create_user(
    user_data: UserCreateDTO, 
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"Attempting to create user: {user_data.email}")
        
        # Verificar se email ou username já existem
        email_exists, username_exists = db_service.check_existing_user(
            email=user_data.email, 
            username=user_data.username
        )
        
        if email_exists:
            logger.warning(f"Attempt to create user with existing email: {user_data.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists"
            )
            
        if username_exists:
            logger.warning(f"Attempt to create user with existing username: {user_data.username}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this username already exists"
            )
        
        # Resto do código permanece igual...
        data_copy = user_data.model_dump()
        
        if isinstance(data_copy.get('detection_time'), datetime):
            data_copy['detection_time'] = data_copy['detection_time'].strftime('%H:%M:%S')
        
        data_copy['password'] = hash_password(data_copy['password'])
        logger.info("Password hashed successfully")
        
        result = db_service.create_user(None, data_copy)
        generated_uid = result.get("uid")
        
        if not generated_uid:
            logger.error("Failed to generate UID for new user")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user: no UID generated"
            )
        
        data_copy_without_password = data_copy.copy()
        if 'password' in data_copy_without_password:
            del data_copy_without_password['password']
            
        logger.info(f"User created successfully with UID: {generated_uid}")
        return UserResponseDTO(uid=generated_uid, **data_copy_without_password)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error creating user: {str(e)}")

@router.put("/{uid}", response_model=UserResponseDTO)
async def update_user(
    uid: str, 
    user_data: UserUpdateDTO, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this user"
            )
            
        existing_user = db_service.get_user(uid)
        if existing_user is None:
            raise HTTPException(status_code=404, detail="User not found")
        
        update_data = user_data.model_dump(exclude_unset=True)
        
        # Verificar se está tentando alterar email ou username para valores que já existem
        if 'email' in update_data or 'username' in update_data:
            email_to_check = update_data.get('email')
            username_to_check = update_data.get('username')
            
            email_exists, username_exists = db_service.check_existing_user(
                email=email_to_check,
                username=username_to_check
            )
            
            # Filtrar para excluir o próprio usuário
            if email_exists:
                # Verificar se o email pertence a outro usuário
                all_users = db_service.get_all_users() or {}
                for existing_uid, user in all_users.items():
                    if user.get("email") == email_to_check and existing_uid != uid:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Email already in use by another user"
                        )
            
            if username_exists:
                # Verificar se o username pertence a outro usuário
                all_users = db_service.get_all_users() or {}
                for existing_uid, user in all_users.items():
                    if user.get("username") == username_to_check and existing_uid != uid:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Username already in use by another user"
                        )
        
        # Resto do código permanece igual...
        if 'detection_time' in update_data and isinstance(update_data['detection_time'], datetime):
            update_data['detection_time'] = update_data['detection_time'].isoformat()
        
        if 'password' in update_data:
            update_data['password'] = hash_password(update_data['password'])
        
        db_service.update_user(uid, update_data)
        
        updated_user = db_service.get_user(uid)
        
        if 'password' in updated_user:
            del updated_user['password']
            
        return UserResponseDTO(uid=uid, **updated_user)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        raise HTTPException(status_code=500, detail="Error updating user")

@router.delete("/{uid}")
async def delete_user(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        # Verificar autorização
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this user"
            )
            
        # Verificar se usuário existe
        existing_user = db_service.get_user(uid)
        if existing_user is None:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Deletar usuário e seus dados vitais
        db_service.delete_user(uid)
        
        # Também deletar dados vitais associados
        try:
            db_service.delete_vital(uid)  # CORREÇÃO: Usar método do serviço
        except Exception as e:
            logger.warning(f"Could not delete vital data for user {uid}: {e}")
        
        return {"message": "User deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting user: {e}")
        raise HTTPException(status_code=500, detail="Error deleting user")