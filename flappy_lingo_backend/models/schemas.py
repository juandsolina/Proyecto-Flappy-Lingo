from pydantic import BaseModel
from typing import Optional, List

class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str

class LoginResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class RegisterResponse(BaseModel):
    success: bool
    message: str

class SaveProgressRequest(BaseModel):
    user_id: str
    level: int
    score: int

class SaveProgressResponse(BaseModel):
    success: bool
    message: str

class LeaderboardEntry(BaseModel):
    name: str
    score: int

class LeaderboardResponse(BaseModel):
    success: bool
    data: Optional[List[LeaderboardEntry]] = None

class VocabularyRequest(BaseModel):
    topic: str
    difficulty: str

class VocabularyResponse(BaseModel):
    success: bool
    data: Optional[dict] = None
    message: Optional[str] = None