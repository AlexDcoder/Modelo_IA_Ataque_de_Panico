from fastapi import FastAPI, HTTPException
from server.models.user import UserInformation

app = FastAPI()

# Lista de instâncias UserInformation
USERS: list[UserInformation] = []

@app.get("/")
async def read_users():
    """Retorna todos os usuários cadastrados."""
    return USERS

@app.get("/user_data/{user_id}")
async def read_user_data(user_id: str):
    """
    Busca usuário pelo user_id.
    Se não existir, retorna 404.
    """
    matched = [user for user in USERS if user.user_id == user_id]
    if not matched:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user_data": matched}

@app.post("/user_data/", response_model=UserInformation)
async def create_user_data(user_info: UserInformation):
    """
    Adiciona um novo usuário.
    Retorna o próprio modelo cadastrado.
    """
    USERS.append(user_info)
    return user_info
