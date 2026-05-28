import sqlite3
import os
import shutil

_PROJECT_DB_PATH = os.path.join(os.path.dirname(__file__), "flappy_lingo.db")
_DEFAULT_DB_DIR = os.path.join(
    os.getenv("LOCALAPPDATA", os.path.expanduser("~")),
    "flappy_lingo_backend",
)
_DB_DIR = os.getenv("FLAPPY_DB_DIR", _DEFAULT_DB_DIR)
os.makedirs(_DB_DIR, exist_ok=True)

DB_PATH = os.path.join(_DB_DIR, "flappy_lingo.db")

# Migra automáticamente la BD existente del proyecto al directorio local
# para evitar locks frecuentes cuando el proyecto está dentro de OneDrive.
if not os.path.exists(DB_PATH) and os.path.exists(_PROJECT_DB_PATH):
    shutil.copy2(_PROJECT_DB_PATH, DB_PATH)

def get_connection():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA busy_timeout = 10000")
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id          TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            email       TEXT UNIQUE NOT NULL,
            password    TEXT NOT NULL,
            created_at  TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS progress (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     TEXT NOT NULL,
            level       INTEGER NOT NULL,
            score       INTEGER NOT NULL,
            saved_at    TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS leaderboard (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     TEXT NOT NULL,
            name        TEXT NOT NULL,
            score       INTEGER NOT NULL,
            saved_at    TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
    """)

    conn.commit()
    conn.close()