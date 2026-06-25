from fastapi import APIRouter, Depends
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import WaitlistSignup

router = APIRouter(prefix="/waitlist", tags=["waitlist"])

# A small head-start so the public counter never looks empty.
SEED_COUNT = 4823


class WaitlistCreate(BaseModel):
    email: EmailStr
    name: str | None = Field(default=None, max_length=120)
    username: str | None = Field(default=None, max_length=60)


class WaitlistOut(BaseModel):
    ok: bool
    count: int
    already_joined: bool = False


def _total(db: Session) -> int:
    return SEED_COUNT + (db.scalar(select(func.count()).select_from(WaitlistSignup)) or 0)


@router.get("/count", response_model=WaitlistOut)
def waitlist_count(db: Session = Depends(get_db)):
    return WaitlistOut(ok=True, count=_total(db))


@router.post("", response_model=WaitlistOut, status_code=201)
def join_waitlist(body: WaitlistCreate, db: Session = Depends(get_db)):
    email = body.email.lower().strip()
    existing = db.scalar(select(WaitlistSignup).where(WaitlistSignup.email == email))
    if existing:
        return WaitlistOut(ok=True, count=_total(db), already_joined=True)
    db.add(WaitlistSignup(
        email=email,
        name=(body.name or None),
        desired_username=(body.username or None),
        source="landing",
    ))
    db.commit()
    return WaitlistOut(ok=True, count=_total(db))
