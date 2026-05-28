import os
import sqlite3

def check_user_in_db(email):
    db_dir = os.getenv("LOCALAPPDATA", os.path.expanduser("~"))
    db_path = os.path.join(db_dir, "flappy_lingo_backend", "flappy_lingo.db")

    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        conn.close()

        if user:
            print(f"User found: {user}")
        else:
            print("User not found.")
    except sqlite3.Error as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    check_user_in_db("test@example.com")