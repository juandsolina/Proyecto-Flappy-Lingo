from fastapi import APIRouter, HTTPException, Depends
from models.schemas import VocabularyRequest
from services.groq_service import generate_vocabulary
from middleware.auth_middleware import require_auth

router = APIRouter()

@router.post("")
async def vocabulary(body: VocabularyRequest, user_id: str = Depends(require_auth)):
    if not body.topic or not body.difficulty:
        raise HTTPException(status_code=400, detail="Tema y dificultad son requeridos")
    try:
        result = await generate_vocabulary(body.topic, body.difficulty)
        return {"success": True, "data": result}
    except Exception:
        raise HTTPException(status_code=500, detail="Error al generar contenido con IA")