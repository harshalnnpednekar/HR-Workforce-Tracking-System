"""
Database connection helper for SQLite.

Automatically creates the users.db file and handles initialization.
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "users.db")

def get_connection():
    """Return a new sqlite3 connection to the local database."""
    conn = sqlite3.connect(DB_PATH)
    # This allows accessing columns by name like row["Email"]
    conn.row_factory = sqlite3.Row
    return conn

def init_db() -> None:
    """Create the Users table and seed the default admin if not present."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS Users (
            Id          TEXT PRIMARY KEY,
            Name        TEXT NOT NULL,
            Email       TEXT NOT NULL UNIQUE,
            Role        TEXT NOT NULL DEFAULT 'employee',
            Password    TEXT NOT NULL,
            CreatedAt   DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    """)

    # Check for default admin
    cursor.execute("SELECT 1 FROM Users WHERE Email = ?", ("admin@hr.com",))
    if not cursor.fetchone():
        cursor.execute("""
            INSERT INTO Users (Id, Name, Email, Role, Password)
            VALUES (?, ?, ?, ?, ?);
        """, ('admin-1', 'System Admin', 'admin@hr.com', 'admin', 'password123'))
        conn.commit()

    conn.close()
    print("Database initialized - Users table ready.")
