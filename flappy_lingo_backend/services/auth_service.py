import uuid
import sqlite3
import time
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext
from database.db import get_connection
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY  = os.getenv("JWT_SECRET", "fallback_secret")
ALGORITHM   = os.getenv("JWT_ALGORITHM", "HS256")
EXPIRE_MINS = int(os.getenv("JWT_EXPIRE_MINUTES", "10080"))

# Use a pure-python scheme to avoid bcrypt backend/runtime incompatibilities
# that were causing 500 errors during registration in local development.
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=EXPIRE_MINS)
    return jwt.encode(
        {"sub": user_id, "exp": expire},
        SECRET_KEY,
        algorithm=ALGORITHM,
    )

def decode_token(token: str) -> str:
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    return payload.get("sub")

def register_user(name: str, email: str, password: str) -> dict:
    for attempt in range(5):
        conn = None
        try:
            conn = get_connection()
            cursor = conn.cursor()

            existing = cursor.execute(
                "SELECT id FROM users WHERE email = ?", (email,)
            ).fetchone()

            if existing:
                return {"success": False, "status": 409, "message": "El correo ya se encuentra registrado"}

            user_id = str(uuid.uuid4())
            hashed = hash_password(password)

            cursor.execute(
                "INSERT INTO users (id, name, email, password) VALUES (?, ?, ?, ?)",
                (user_id, name, email, hashed),
            )
            conn.commit()
            return {"success": True, "status": 201, "message": "Usuario registrado correctamente"}
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e).lower() and attempt < 4:
                time.sleep(0.2)
                continue
            raise
        finally:
            if conn is not None:
                conn.close()

def login_user(email: str, password: str) -> dict:
    conn = get_connection()
    cursor = conn.cursor()

    row = cursor.execute(
        "SELECT id, name, email, password FROM users WHERE email = ?", (email,)
    ).fetchone()
    conn.close()

    if not row or not verify_password(password, row["password"]):
        return {"success": False, "status": 401, "message": "Credenciales inválidas"}

    token = create_token(row["id"])

    return {
        "success": True,
        "status": 200,
        "message": "Login exitoso",
        "data": {
            "token": token,
            "user": {
                "id":    row["id"],
                "name":  row["name"],
                "email": row["email"],
            },
        },
    }