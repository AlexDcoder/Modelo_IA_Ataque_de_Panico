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
        logger.info(f"🔄 [GET_ALL_USERS] Iniciando busca por todos os usuários. Usuário atual: {current_user}")
        
        users = db_service.get_all_users() or {}
        logger.info(f"✅ [GET_ALL_USERS] Encontrados {len(users)} usuários no banco de dados")
        
        # Remover senhas dos dados retornados
        for uid in users:
            if 'password' in users[uid]:
                del users[uid]['password']
                
        logger.info(f"✅ [GET_ALL_USERS] Retornando {len(users)} usuários sem dados sensíveis")
        return users
        
    except Exception as e:
        logger.error(f"❌ [GET_ALL_USERS] Erro ao buscar todos os usuários: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error getting users")

@router.get("/me", response_model=UserResponseDTO)
async def get_current_user_info(
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    """Retorna informações do usuário atual"""
    try:
        logger.info(f"🔄 [GET_CURRENT_USER] Buscando usuário com UID: {current_user}")
        user = db_service.get_user(current_user)
        
        if user is None:
            logger.warning(f"⚠️ [GET_CURRENT_USER] Usuário não encontrado com UID: {current_user}")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        logger.info(f"✅ [GET_CURRENT_USER] Usuário encontrado: {user.get('username')} - {user.get('email')}")
        
        # Remover senha antes de retornar
        if 'password' in user:
            del user['password']
            logger.debug("🔒 [GET_CURRENT_USER] Senha removida dos dados de retorno")
            
        return UserResponseDTO(uid=current_user, **user)
        
    except HTTPException as he:
        logger.warning(f"⚠️ [GET_CURRENT_USER] HTTPException: {he.detail} - Status: {he.status_code}")
        raise he
    except Exception as e:
        logger.error(f"❌ [GET_CURRENT_USER] Erro inesperado ao buscar usuário: {str(e)}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting user")

@router.get("/{uid}", response_model=UserPublicDTO)
async def get_user_public(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    """Retorna informações públicas de um usuário (sem dados sensíveis)"""
    try:
        logger.info(f"🔄 [GET_USER_PUBLIC] Buscando dados públicos do usuário com UID: {uid}")
        
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            logger.warning(f"⚠️ [GET_USER_PUBLIC] Usuário não encontrado com UID: {uid}")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        logger.info(f"✅ [GET_USER_PUBLIC] Dados públicos encontrados para: {user.get('username')}")
        
        # Remover dados sensíveis
        user_public = {
            'uid': uid,
            'username': user.get('username'),
            'email': user.get('email'),
            'detection_time': user.get('detection_time')
        }
        
        logger.debug(f"📋 [GET_USER_PUBLIC] Dados públicos a retornar: {user_public}")
        return UserPublicDTO(**user_public)
        
    except HTTPException as he:
        logger.warning(f"⚠️ [GET_USER_PUBLIC] HTTPException: {he.detail} - Status: {he.status_code}")
        raise he
    except Exception as e:
        logger.error(f"❌ [GET_USER_PUBLIC] Erro inesperado ao buscar usuário público: {str(e)}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting user")

@router.post("/", response_model=UserResponseDTO)
async def create_user(
    user_data: UserCreateDTO, 
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"🔄 [CREATE_USER] Tentativa de criar usuário: {user_data.email} - Username: {user_data.username}")
        logger.debug(f"📦 [CREATE_USER] Dados recebidos: {user_data.model_dump()}")
        
        # Verificar se email ou username já existem
        email_exists, username_exists = db_service.check_existing_user(
            email=user_data.email, 
            username=user_data.username
        )
        
        logger.info(f"🔍 [CREATE_USER] Verificação de duplicados - Email existe: {email_exists}, Username existe: {username_exists}")
        
        if email_exists:
            logger.warning(f"⚠️ [CREATE_USER] Tentativa de criar usuário com email existente: {user_data.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists"
            )
            
        if username_exists:
            logger.warning(f"⚠️ [CREATE_USER] Tentativa de criar usuário com username existente: {user_data.username}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this username already exists"
            )
        
        # Preparar dados para criação
        data_copy = user_data.model_dump()
        logger.debug(f"📝 [CREATE_USER] Dados copiados para processamento: {data_copy}")
        
        if isinstance(data_copy.get('detection_time'), datetime):
            data_copy['detection_time'] = data_copy['detection_time'].strftime('%H:%M:%S')
            logger.debug(f"⏰ [CREATE_USER] detection_time convertido para string: {data_copy['detection_time']}")
        
        # Hash da senha
        original_password = data_copy['password']
        data_copy['password'] = hash_password(data_copy['password'])
        logger.info("🔒 [CREATE_USER] Senha hash gerada com sucesso")
        logger.debug(f"🔑 [CREATE_USER] Senha original: {original_password[:2]}... -> Hash: {data_copy['password'][:10]}...")
        
        # Criar usuário no banco
        logger.info("💾 [CREATE_USER] Chamando db_service.create_user...")
        result = db_service.create_user(None, data_copy)
        logger.info(f"📄 [CREATE_USER] Resultado do db_service.create_user: {result}")
        
        # Adicionar verificação detalhada do resultado
        if not result:
            logger.error("❌ [CREATE_USER] db_service.create_user retornou None ou vazio")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user: no response from database"
            )
        
        generated_uid = result.get("uid")
        if not generated_uid:
            logger.error(f"❌ [CREATE_USER] Falha ao gerar UID para novo usuário. Result completo: {result}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user: no UID generated"
            )
        
        # Preparar resposta sem senha
        data_copy_without_password = data_copy.copy()
        if 'password' in data_copy_without_password:
            del data_copy_without_password['password']
            
        logger.info(f"✅ [CREATE_USER] Usuário criado com sucesso. UID: {generated_uid}, Email: {user_data.email}")
        logger.debug(f"📤 [CREATE_USER] Dados a retornar: {data_copy_without_password}")
        
        return UserResponseDTO(uid=generated_uid, **data_copy_without_password)
        
    except HTTPException as he:
        logger.warning(f"⚠️ [CREATE_USER] HTTPException: {he.detail} - Status: {he.status_code}")
        raise he
    except Exception as e:
        logger.error(f"❌ [CREATE_USER] Erro inesperado ao criar usuário: {str(e)}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error creating user: {str(e)}")
    
@router.put("/{uid}", response_model=UserResponseDTO)
async def update_user(
    uid: str, 
    user_data: UserUpdateDTO, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"🔄 [UPDATE_USER] Iniciando atualização do usuário. UID: {uid}, Usuário atual: {current_user}")
        logger.debug(f"📦 [UPDATE_USER] Dados recebidos para atualização: {user_data.model_dump(exclude_unset=True)}")
        
        # Verificar autorização
        if uid != current_user:
            logger.warning(f"🚫 [UPDATE_USER] Tentativa de atualização não autorizada. UID: {uid}, Usuário atual: {current_user}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this user"
            )
            
        # Verificar se usuário existe
        logger.info(f"🔍 [UPDATE_USER] Verificando existência do usuário: {uid}")
        existing_user = db_service.get_user(uid)
        if existing_user is None:
            logger.warning(f"⚠️ [UPDATE_USER] Usuário não encontrado para atualização: {uid}")
            raise HTTPException(status_code=404, detail="User not found")
        
        logger.info(f"✅ [UPDATE_USER] Usuário encontrado: {existing_user.get('username')}")
        
        # Preparar dados para atualização
        update_data = user_data.model_dump(exclude_unset=True)
        logger.info(f"📝 [UPDATE_USER] Campos para atualização: {list(update_data.keys())}")
        logger.debug(f"🔧 [UPDATE_USER] Dados completos para atualização: {update_data}")
        
        # Verificar se está tentando alterar email ou username para valores que já existem
        if 'email' in update_data or 'username' in update_data:
            email_to_check = update_data.get('email')
            username_to_check = update_data.get('username')
            
            logger.info(f"🔍 [UPDATE_USER] Verificando duplicados - Email: {email_to_check}, Username: {username_to_check}")
            
            email_exists, username_exists = db_service.check_existing_user(
                email=email_to_check,
                username=username_to_check
            )
            
            logger.info(f"🔍 [UPDATE_USER] Resultado verificação - Email existe: {email_exists}, Username existe: {username_exists}")
            
            # Filtrar para excluir o próprio usuário
            if email_exists:
                # Verificar se o email pertence a outro usuário
                all_users = db_service.get_all_users() or {}
                for existing_uid, user in all_users.items():
                    if user.get("email") == email_to_check and existing_uid != uid:
                        logger.warning(f"⚠️ [UPDATE_USER] Email já em uso por outro usuário: {email_to_check}")
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Email already in use by another user"
                        )
            
            if username_exists:
                # Verificar se o username pertence a outro usuário
                all_users = db_service.get_all_users() or {}
                for existing_uid, user in all_users.items():
                    if user.get("username") == username_to_check and existing_uid != uid:
                        logger.warning(f"⚠️ [UPDATE_USER] Username já em uso por outro usuário: {username_to_check}")
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Username already in use by another user"
                        )
        
        # Processar campos especiais
        if 'detection_time' in update_data and isinstance(update_data['detection_time'], datetime):
            update_data['detection_time'] = update_data['detection_time'].isoformat()
            logger.debug(f"⏰ [UPDATE_USER] detection_time convertido: {update_data['detection_time']}")
        
        if 'password' in update_data:
            original_password = update_data['password']
            update_data['password'] = hash_password(update_data['password'])
            logger.info("🔒 [UPDATE_USER] Senha atualizada com hash")
            logger.debug(f"🔑 [UPDATE_USER] Senha original: {original_password[:2]}... -> Hash: {update_data['password'][:10]}...")
        
        # Executar atualização no banco
        logger.info(f"💾 [UPDATE_USER] Chamando db_service.update_user para UID: {uid}")
        logger.debug(f"📤 [UPDATE_USER] Dados enviados para update_user: {update_data}")
        
        update_result = db_service.update_user(uid, update_data)
        logger.info(f"📄 [UPDATE_USER] Resultado do update_user: {update_result}")
        
        if not update_result:
            logger.error(f"❌ [UPDATE_USER] db_service.update_user retornou False para UID: {uid}")
            raise HTTPException(status_code=500, detail="Database update failed")
        
        # Buscar usuário atualizado
        logger.info(f"🔍 [UPDATE_USER] Buscando usuário atualizado: {uid}")
        updated_user = db_service.get_user(uid)
        
        if updated_user is None:
            logger.error(f"❌ [UPDATE_USER] Não foi possível recuperar usuário após atualização: {uid}")
            raise HTTPException(status_code=500, detail="Failed to retrieve updated user")
        
        # Remover senha antes de retornar
        if 'password' in updated_user:
            del updated_user['password']
            logger.debug("🔒 [UPDATE_USER] Senha removida dos dados de retorno")
            
        logger.info(f"✅ [UPDATE_USER] Usuário atualizado com sucesso: {uid}")
        logger.debug(f"📤 [UPDATE_USER] Dados retornados: {updated_user}")
        
        return UserResponseDTO(uid=uid, **updated_user)
        
    except HTTPException as he:
        logger.warning(f"⚠️ [UPDATE_USER] HTTPException: {he.detail} - Status: {he.status_code}")
        raise he
    except Exception as e:
        logger.error(f"❌ [UPDATE_USER] Erro inesperado ao atualizar usuário: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error updating user: {str(e)}")

@router.delete("/{uid}")
async def delete_user(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        logger.info(f"🔄 [DELETE_USER] Iniciando exclusão do usuário. UID: {uid}, Usuário atual: {current_user}")
        
        # Verificar autorização
        if uid != current_user:
            logger.warning(f"🚫 [DELETE_USER] Tentativa de exclusão não autorizada. UID: {uid}, Usuário atual: {current_user}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this user"
            )
            
        # Verificar se usuário existe
        logger.info(f"🔍 [DELETE_USER] Verificando existência do usuário: {uid}")
        existing_user = db_service.get_user(uid)
        if existing_user is None:
            logger.warning(f"⚠️ [DELETE_USER] Usuário não encontrado para exclusão: {uid}")
            raise HTTPException(status_code=404, detail="User not found")
        
        logger.info(f"✅ [DELETE_USER] Usuário encontrado para exclusão: {existing_user.get('username')}")
        
        # Deletar usuário
        logger.info(f"🗑️ [DELETE_USER] Chamando db_service.delete_user para UID: {uid}")
        delete_result = db_service.delete_user(uid)
        logger.info(f"📄 [DELETE_USER] Resultado do delete_user: {delete_result}")
        
        # Também deletar dados vitais associados
        try:
            logger.info(f"🗑️ [DELETE_USER] Tentando deletar dados vitais do usuário: {uid}")
            db_service.delete_vital(uid)
            logger.info(f"✅ [DELETE_USER] Dados vitais deletados com sucesso: {uid}")
        except Exception as e:
            logger.warning(f"⚠️ [DELETE_USER] Não foi possível deletar dados vitais do usuário {uid}: {str(e)}")
        
        logger.info(f"✅ [DELETE_USER] Usuário deletado com sucesso: {uid}")
        return {"message": "User deleted successfully"}
        
    except HTTPException as he:
        logger.warning(f"⚠️ [DELETE_USER] HTTPException: {he.detail} - Status: {he.status_code}")
        raise he
    except Exception as e:
        logger.error(f"❌ [DELETE_USER] Erro inesperado ao deletar usuário: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error deleting user: {str(e)}")