"""add badges.emoji column

Revision ID: 0002_badge_emoji
Revises: 0001_init
Create Date: 2026-06-25
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_badge_emoji"
down_revision = "0001_init"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("badges", sa.Column("emoji", sa.String(length=16), nullable=True))


def downgrade() -> None:
    op.drop_column("badges", "emoji")
