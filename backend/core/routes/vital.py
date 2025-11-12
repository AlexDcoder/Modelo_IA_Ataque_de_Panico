from fastapi import APIRouter, Depends, HTTPException, status
from core.services.db_service import DBService
from core.logger import get_logger
from core.schemas.user import UserVitalData
from core.schemas.dto.user_dto import VitalResponseDTO
from core.security.auth_middleware import get_current_user
from core.dependencies import get_db_service

logger = get_logger(__name__)
router = APIRouter(prefix="", tags=["vitals"])

@router.get("/")
async def get_all_vital_data(
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        vital_data = db_service._connector.get_data("vital_data") or {}
        return vital_data
    except Exception as e:
        logger.error(f"Error getting all vital data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting vital data")

# Buscar dados vitais do usuário
@router.get("/{uid}", response_model=VitalResponseDTO)
async def get_user_vital_data(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        # Verificar autorização
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this user's vital data"
            )
            
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Buscar dados vitais
        vital_data = db_service.get_user_vital_data(uid)
        if vital_data is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vital data not found")
        
        return VitalResponseDTO(uid=uid, **vital_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting vital data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error getting vital data")

# Criar/atualizar dados vitais
@router.post("/{uid}")
async def create_vital_data(
    uid: str, 
    vital_data: UserVitalData, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        # Verificar autorização
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this user's vital data"
            )
            
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUNDtus.HTTP_404_NOT_FOUND, detail="User not found")
        
        vital_dict = vital_data.model_dump()
        
        # Verificar se dados já existem
        existing_data = db_service.get_user_vital_data(uid)
        
        if existing_data:
            # Atualizar dados existentes
            db_service.update_vital(uid, vital_dict)
            return {"message": "Vital data updated successfully"}
        else:
            # Criar novos dados
            db_service.set_vital(uid, vital_dict)
            return {"message": "Vital data created successfully"}
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating/updating vital data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error saving vital data")

# Atualizar dados vitais
@router.put("/{uid}")
async def update_vital_data(
    uid: str, 
    vital_data: UserVitalData, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        # Verificar autorização
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this user's vital data"
            )
            
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
        # Verificar se dados vitais existem
        existing_data = db_service.get_user_vital_data(uid)
        if existing_data is None:
            raise HTTPException(status_code=404, detail="Vital data not found")
        
        vital_dict = vital_data.model_dump()
        db_service.update_vital(uid, vital_dict)
        
        return {"message": "Vital data updated successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating vital data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error updating vital data")
    
# Deletar dados vitais
@router.delete("/{uid}")
async def delete_vital_data(
    uid: str, 
    current_user: str = Depends(get_current_user),
    db_service: DBService = Depends(get_db_service)
):
    try:
        # Verificar autorização
        if uid != current_user:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this user's vital data"
            )
            
        # Verificar se usuário existe
        user = db_service.get_user(uid)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="User not found"
            )
        
        # Deletar dados vitais
        result = db_service.delete_vital(uid)
        
        logger.info(f"Vital data deleted for user {uid}")
        return {"message": "Vital data deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting vital data: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail="Error deleting vital data"
        )