import uvicorn
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database.db import init_db, DB_PATH
from routes.auth        import router as auth_router
from routes.progress    import router as progress_router
from routes.leaderboard import router as leaderboard_router
from routes.vocabulary  import router as vocabulary_router
from routes.questions   import router as questions_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    if not os.path.exists(DB_PATH):
        init_db()
    yield


app = FastAPI(title="Flappy Lingo API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router,        prefix="/api/auth")
app.include_router(progress_router,    prefix="/api/progress")
app.include_router(leaderboard_router, prefix="/api/leaderboard")
app.include_router(vocabulary_router,  prefix="/api/ai/vocabulary")
app.include_router(questions_router,   prefix="/api/v1")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)