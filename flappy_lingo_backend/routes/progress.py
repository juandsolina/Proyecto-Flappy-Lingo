from fastapi import APIRouter, HTTPException, Depends
from models.schemas import SaveProgressRequest
from services.progress_service import save_progress
from middleware.auth_middleware import require_auth

router = APIRouter()

@router.post("/save")
def save(body: SaveProgressRequest, user_id: str = Depends(require_auth)):
    if body.level is None or body.score is None:
        raise HTTPException(status_code=400, detail="Datos incompletos")

    # Evita que un cliente escriba progreso para otro usuario.
    if body.user_id and body.user_id != user_id:
        raise HTTPException(status_code=403, detail="No autorizado para guardar progreso de otro usuario")

    result = save_progress(user_id, body.level, body.score)
    return result