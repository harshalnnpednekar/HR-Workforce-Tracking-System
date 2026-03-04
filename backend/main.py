"""
HR Workforce Tracking System â€” FastAPI Backend

Provides /api/register and /api/login endpoints backed by MSSQL.
"""

import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import get_connection, init_db

# â”€â”€ App setup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
app = FastAPI(title="HR Workforce API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Flutter dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    """Ensure the Users table exists when the server starts."""
    init_db()


# â”€â”€ Request / Response models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    role: str           # "admin" or "employee"


class LoginRequest(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    role: str


# â”€â”€ Endpoints â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@app.post("/api/register", response_model=UserResponse)
def register(body: RegisterRequest):
    """Register a new user and persist to MSSQL."""
    conn = get_connection()
    cursor = conn.cursor()

    # Check duplicate email
    cursor.execute("SELECT Id FROM Users WHERE Email = ?", (body.email,))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=409, detail="User already exists with this email.")

    user_id = str(int(datetime.datetime.now().timestamp() * 1000))

    cursor.execute(
        "INSERT INTO Users (Id, Name, Email, Role, Password) VALUES (?, ?, ?, ?, ?)",
        (user_id, body.name, body.email, body.role.lower(), body.password),
    )
    conn.commit()
    cursor.close()
    conn.close()

    return UserResponse(id=user_id, name=body.name, email=body.email, role=body.role.lower())


@app.post("/api/login", response_model=UserResponse)
def login(body: LoginRequest):
    """Authenticate an existing user against MSSQL."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT Id, Name, Email, Role, Password FROM Users WHERE Email = ?", (body.email,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="User not found. Please register first.")

    if row["Password"] != body.password:
        raise HTTPException(status_code=401, detail="Invalid password.")

    return UserResponse(id=row["Id"], name=row["Name"], email=row["Email"], role=row["Role"])


@app.get("/api/health")
def health():
    """Simple health-check endpoint."""
    return {"status": "ok"}

