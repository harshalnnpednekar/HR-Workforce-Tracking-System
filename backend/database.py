"""
Database connection helper for Microsoft SQL Server via pymssql.

Reads connection parameters from .env file.
Supports both SQL Server Authentication and Windows Authentication.
"""

import os
import pymssql
from dotenv import load_dotenv

load_dotenv()

MSSQL_SERVER = os.getenv("MSSQL_SERVER", "localhost")
MSSQL_DATABASE = os.getenv("MSSQL_DATABASE", "HRWorkforceDB")
MSSQL_USERNAME = os.getenv("MSSQL_USERNAME", "")
MSSQL_PASSWORD = os.getenv("MSSQL_PASSWORD", "")


def get_connection():
    """Return a new pymssql connection to the configured MSSQL instance."""
    return pymssql.connect(
        server=MSSQL_SERVER,
        user=MSSQL_USERNAME if MSSQL_USERNAME else None,
        password=MSSQL_PASSWORD if MSSQL_PASSWORD else None,
        database=MSSQL_DATABASE,
    )


def init_db() -> None:
    """Create the Users table and seed the default admin if not present."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
        BEGIN
            CREATE TABLE Users (
                Id          NVARCHAR(50)   PRIMARY KEY,
                Name        NVARCHAR(100)  NOT NULL,
                Email       NVARCHAR(150)  NOT NULL UNIQUE,
                Role        NVARCHAR(20)   NOT NULL DEFAULT 'employee',
                Password    NVARCHAR(255)  NOT NULL,
                CreatedAt   DATETIME2      NOT NULL DEFAULT GETDATE()
            );
        END
    """)

    cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@hr.com')
        BEGIN
            INSERT INTO Users (Id, Name, Email, Role, Password)
            VALUES ('admin-1', 'System Admin', 'admin@hr.com', 'admin', 'password123');
        END
    """)

    conn.commit()
    cursor.close()
    conn.close()
    print("✅ Database initialized — Users table ready.")
