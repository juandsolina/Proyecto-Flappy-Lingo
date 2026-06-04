import sqlite3
import time
from database.db import get_connection

ALLOWED_CATEGORIES = {"verbs", "animals", "travel", "food", "mixed"}


def normalize_category(category: str) -> str:
    value = category.strip().lower()
    aliases = {
        "verbos": "verbs",
        "animales": "animals",
        "viaje": "travel",
        "viajes": "travel",
        "comida": "food",
        "alimentos": "food",
    }
    return aliases.get(value, value)


def validate_payload(word_in_spanish: str, correct_answer: str, wrong_answer: str, category: str) -> tuple[str, str, str, str]:
    word = word_in_spanish.strip()
    correct = correct_answer.strip()
    wrong = wrong_answer.strip()
    normalized_category = normalize_category(category)

    if not word or not correct or not wrong:
        raise ValueError("Todos los campos son obligatorios")
    if correct.lower() == wrong.lower():
        raise ValueError("La respuesta correcta y la incorrecta no pueden ser iguales")
    if normalized_category not in ALLOWED_CATEGORIES:
        raise ValueError("Categoría inválida")

    return word, correct, wrong, normalized_category


def list_custom_vocabulary(user_id: str, category: str | None = None) -> list[dict]:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        if category:
            normalized = normalize_category(category)
            rows = cursor.execute(
                """
                SELECT id, user_id, word_in_spanish, correct_answer, wrong_answer, category, created_at, updated_at
                FROM custom_vocabulary
                WHERE user_id = ? AND category = ?
                ORDER BY updated_at DESC, id DESC
                """,
                (user_id, normalized),
            ).fetchall()
        else:
            rows = cursor.execute(
                """
                SELECT id, user_id, word_in_spanish, correct_answer, wrong_answer, category, created_at, updated_at
                FROM custom_vocabulary
                WHERE user_id = ?
                ORDER BY updated_at DESC, id DESC
                """,
                (user_id,),
            ).fetchall()

        return [dict(row) for row in rows]
    finally:
        conn.close()


def create_custom_vocabulary(user_id: str, word_in_spanish: str, correct_answer: str, wrong_answer: str, category: str) -> dict:
    word, correct, wrong, normalized_category = validate_payload(
        word_in_spanish,
        correct_answer,
        wrong_answer,
        category,
    )

    for attempt in range(5):
        conn = None
        try:
            conn = get_connection()
            cursor = conn.cursor()

            cursor.execute(
                """
                INSERT INTO custom_vocabulary (user_id, word_in_spanish, correct_answer, wrong_answer, category)
                VALUES (?, ?, ?, ?, ?)
                """,
                (user_id, word, correct, wrong, normalized_category),
            )

            row = cursor.execute(
                """
                SELECT id, user_id, word_in_spanish, correct_answer, wrong_answer, category, created_at, updated_at
                FROM custom_vocabulary
                WHERE id = last_insert_rowid()
                """
            ).fetchone()
            conn.commit()
            return dict(row)
        except sqlite3.IntegrityError:
            raise ValueError("Ya existe una palabra con esa categoría")
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e).lower() and attempt < 4:
                time.sleep(0.2)
                continue
            raise
        finally:
            if conn is not None:
                conn.close()


def update_custom_vocabulary(user_id: str, item_id: int, payload: dict) -> dict:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        existing = cursor.execute(
            """
            SELECT id, user_id, word_in_spanish, correct_answer, wrong_answer, category, created_at, updated_at
            FROM custom_vocabulary
            WHERE id = ? AND user_id = ?
            """,
            (item_id, user_id),
        ).fetchone()

        if not existing:
            raise LookupError("Registro no encontrado")

        merged = {
            "word_in_spanish": payload.get("word_in_spanish", existing["word_in_spanish"]),
            "correct_answer": payload.get("correct_answer", existing["correct_answer"]),
            "wrong_answer": payload.get("wrong_answer", existing["wrong_answer"]),
            "category": payload.get("category", existing["category"]),
        }

        word, correct, wrong, normalized_category = validate_payload(
            merged["word_in_spanish"],
            merged["correct_answer"],
            merged["wrong_answer"],
            merged["category"],
        )

        cursor.execute(
            """
            UPDATE custom_vocabulary
            SET word_in_spanish = ?,
                correct_answer = ?,
                wrong_answer = ?,
                category = ?,
                updated_at = datetime('now')
            WHERE id = ? AND user_id = ?
            """,
            (word, correct, wrong, normalized_category, item_id, user_id),
        )
        conn.commit()

        updated = cursor.execute(
            """
            SELECT id, user_id, word_in_spanish, correct_answer, wrong_answer, category, created_at, updated_at
            FROM custom_vocabulary
            WHERE id = ? AND user_id = ?
            """,
            (item_id, user_id),
        ).fetchone()
        return dict(updated)
    except sqlite3.IntegrityError:
        raise ValueError("Ya existe una palabra con esa categoría")
    finally:
        conn.close()


def delete_custom_vocabulary(user_id: str, item_id: int) -> bool:
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            "DELETE FROM custom_vocabulary WHERE id = ? AND user_id = ?",
            (item_id, user_id),
        )
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()
