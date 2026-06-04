from fastapi import APIRouter, Depends, HTTPException, Query
from middleware.auth_middleware import require_auth
from models.schemas import (
    CustomVocabularyCreateRequest,
    CustomVocabularyUpdateRequest,
)
from services.custom_vocabulary_service import (
    list_custom_vocabulary,
    create_custom_vocabulary,
    update_custom_vocabulary,
    delete_custom_vocabulary,
)

router = APIRouter()


@router.get("")
def list_items(
    category: str | None = Query(default=None),
    user_id: str = Depends(require_auth),
):
    data = list_custom_vocabulary(user_id, category)
    return {"success": True, "data": data}


@router.post("")
def create_item(
    body: CustomVocabularyCreateRequest,
    user_id: str = Depends(require_auth),
):
    try:
        data = create_custom_vocabulary(
            user_id=user_id,
            word_in_spanish=body.word_in_spanish,
            correct_answer=body.correct_answer,
            wrong_answer=body.wrong_answer,
            category=body.category,
        )
        return {"success": True, "message": "Palabra creada", "data": data}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        raise HTTPException(status_code=500, detail="Error al crear palabra")


@router.put("/{item_id}")
def update_item(
    item_id: int,
    body: CustomVocabularyUpdateRequest,
    user_id: str = Depends(require_auth),
):
    payload = body.model_dump(exclude_none=True)
    if not payload:
        raise HTTPException(status_code=400, detail="No hay campos para actualizar")

    try:
        data = update_custom_vocabulary(user_id, item_id, payload)
        return {"success": True, "message": "Palabra actualizada", "data": data}
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        raise HTTPException(status_code=500, detail="Error al actualizar palabra")


@router.delete("/{item_id}")
def delete_item(item_id: int, user_id: str = Depends(require_auth)):
    deleted = delete_custom_vocabulary(user_id, item_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Registro no encontrado")
    return {"success": True, "message": "Palabra eliminada"}
