from fastapi import APIRouter, HTTPException, Query
from database.db import get_connection

router = APIRouter()

@router.get("")
def get_leaderboard(limit: int = Query(default=10, ge=1, le=100)):
    try:
        conn = get_connection()
        rows = conn.execute(
            "SELECT name, score FROM leaderboard ORDER BY score DESC LIMIT ?",
            (limit,),
        ).fetchall()
        conn.close()
        return {
            "success": True,
            "data": [{"name": r["name"], "score": r["score"]} for r in rows],
        }
    except Exception:
        raise HTTPException(status_code=500, detail="Error al obtener leaderboard")