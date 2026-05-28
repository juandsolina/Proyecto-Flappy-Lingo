from fastapi import APIRouter, HTTPException
import re
from models.schemas import LoginRequest, RegisterRequest
from services.auth_service import login_user, register_user

router = APIRouter()

@router.post("/login")
def login(body: LoginRequest):
    if not body.email or not body.password:
        raise HTTPException(status_code=400, detail="Email y contraseña son requeridos")
    email_regex = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    if not re.match(email_regex, body.email):
        raise HTTPException(status_code=400, detail="El correo no es válido")
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="La contraseña debe tener al menos 6 caracteres")
    result = login_user(body.email, body.password)
    if not result["success"]:
        raise HTTPException(status_code=result["status"], detail=result["message"])
    # Mantener el esquema esperado por el frontend: user.name
    return {"success": True, "message": result["message"], "data": result["data"]}

@router.post("/register")
def register(body: RegisterRequest):
    if not body.name or not body.email or not body.password:
        raise HTTPException(status_code=400, detail="Todos los campos son obligatorios")
    email_regex = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    if not re.match(email_regex, body.email):
        raise HTTPException(status_code=400, detail="El correo no es válido")
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="La contraseña debe tener al menos 6 caracteres")
    result = register_user(body.name, body.email, body.password)
    if not result["success"]:
        raise HTTPException(status_code=result["status"], detail=result["message"])
    return {
        "success": True,
        "message": result["message"],
        "data": {"user": {"name": body.name, "email": body.email}},
    }