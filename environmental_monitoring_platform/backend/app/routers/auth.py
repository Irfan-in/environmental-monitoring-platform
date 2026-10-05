import hashlib
from fastapi import APIRouter, HTTPException
from app.schemas import UserLoginRequest, UserLoginResponse
from app.crud import get_user_by_username, create_user

router = APIRouter(prefix="/api/auth", tags=["Authentication & Access Control"])


@router.post("/login", response_model=UserLoginResponse)
def login(creds: UserLoginRequest):
    """
    Authenticate user.
    Default seeded accounts:
    - Admin: admin / admin123 (full access to modify alert thresholds)
    - Viewer: user / user123 (read-only telemetry & charts)
    """
    user = get_user_by_username(creds.username)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    entered_hash = hashlib.sha256(creds.password.encode()).hexdigest()
    if user["password_hash"] != entered_hash:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    # Generate lightweight session token
    token = f"token_{user['username']}_{user['role']}"
    return {
        "success": True,
        "username": user["username"],
        "role": user["role"],
        "token": token,
        "message": f"Welcome back, {user['username']}! Logged in as {user['role'].capitalize()}."
    }


@router.post("/register")
def register(creds: UserLoginRequest):
    """Register a new viewer account."""
    existing = get_user_by_username(creds.username)
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")

    p_hash = hashlib.sha256(creds.password.encode()).hexdigest()
    success = create_user(creds.username, p_hash, role="viewer")
    if not success:
        raise HTTPException(status_code=500, detail="Failed to create user")

    return {"success": True, "message": "User registered successfully"}
