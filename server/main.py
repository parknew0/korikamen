import os
import sqlite3
from contextlib import asynccontextmanager, contextmanager

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# 환경 변수로 운영 값 주입 (Docker / .env 에서 설정)
DB_PATH = os.environ.get("DB_PATH", "scores.db")
API_KEY = os.environ.get("API_KEY") or None        # 설정 시 POST 에 X-API-Key 헤더 요구
MAX_TIME_MS = 24 * 60 * 60 * 1000                  # 24시간 초과 기록은 비정상으로 보고 차단


def init_db() -> None:
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS scores (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                nickname   TEXT    NOT NULL,
                time_ms    INTEGER NOT NULL,
                created_at TEXT    NOT NULL DEFAULT (datetime('now'))
            )
            """
        )
        conn.execute("CREATE INDEX IF NOT EXISTS idx_scores_time ON scores(time_ms)")


@contextmanager
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="Korikamen Ranking API", version="1.0.0", lifespan=lifespan)

# 브라우저(웹 리더보드 등)에서 fetch 할 수 있도록 CORS 허용. 공개 읽기 API라 모든 출처 허용.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ScoreIn(BaseModel):
    nickname: str = Field(min_length=1, max_length=12)
    timeMs: int = Field(gt=0, le=MAX_TIME_MS)


class ScoreOut(BaseModel):
    rank: int
    nickname: str
    timeMs: int


def require_api_key(x_api_key: str | None = Header(default=None)) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid api key")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/scores", dependencies=[Depends(require_api_key)])
def submit_score(score: ScoreIn):
    """게임 클리어 시 닉네임과 기록(ms)을 저장한다."""
    nickname = score.nickname.strip()
    if not nickname:
        raise HTTPException(status_code=422, detail="nickname is empty")
    with get_db() as conn:
        conn.execute(
            "INSERT INTO scores (nickname, time_ms) VALUES (?, ?)",
            (nickname, score.timeMs),
        )
    return {"ok": True}


@app.get("/scores", response_model=list[ScoreOut])
def list_scores(limit: int = 20):
    """기록이 빠른 순(time_ms 오름차순)으로 랭킹을 반환한다."""
    limit = max(1, min(limit, 100))
    with get_db() as conn:
        rows = conn.execute(
            "SELECT nickname, time_ms FROM scores "
            "ORDER BY time_ms ASC, created_at ASC LIMIT ?",
            (limit,),
        ).fetchall()
    return [
        ScoreOut(rank=i + 1, nickname=row["nickname"], timeMs=row["time_ms"])
        for i, row in enumerate(rows)
    ]
