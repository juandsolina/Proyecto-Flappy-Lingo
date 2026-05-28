from fastapi import APIRouter, Query
from services.groq_service import generate_question, generate_questions_batch

router = APIRouter()

@router.get("/question")
async def get_question(category: str = Query(default="mixed")):
    question = await generate_question(category)
    return question

@router.get("/questions-batch")
async def get_questions_batch(category: str = Query(default="mixed"), count: int = Query(default=10, ge=5, le=20)):
    """
    Devuelve un lote de preguntas únicas generadas por Groq IA (o fallback si falla).
    """
    result = await generate_questions_batch(category, count)
    return result