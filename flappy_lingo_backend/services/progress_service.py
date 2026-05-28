import sqlite3
import time
from database.db import get_connection

def save_progress(user_id: str, level: int, score: int) -> dict:
    for attempt in range(5):
        conn = None
        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute(
                "INSERT INTO progress (user_id, level, score) VALUES (?, ?, ?)",
                (user_id, level, score),
            )

            existing = cursor.execute(
                "SELECT id, score FROM leaderboard WHERE user_id = ?", (user_id,)
            ).fetchone()

            user = cursor.execute(
                "SELECT name FROM users WHERE id = ?", (user_id,)
            ).fetchone()

            if user:
                if existing is None:
                    cursor.execute(
                        "INSERT INTO leaderboard (user_id, name, score) VALUES (?, ?, ?)",
                        (user_id, user["name"], score),
                    )
                elif score > existing["score"]:
                    cursor.execute(
                        "UPDATE leaderboard SET score = ?, saved_at = datetime('now') WHERE user_id = ?",
                        (score, user_id),
                    )

            conn.commit()
            return {"success": True, "message": "Progreso guardado correctamente"}
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e).lower() and attempt < 4:
                time.sleep(0.2)
                continue
            raise
        finally:
            if conn is not None:
                conn.close()