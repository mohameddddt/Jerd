"""Schema and connection. Mirrors the app's SQLite tables plus users, shops
and device tokens. `schema.sql` is the same thing as plain Postgres DDL."""

from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Index,
    Integer,
    MetaData,
    String,
    Table,
    Text,
    create_engine,
)
from sqlalchemy.pool import StaticPool

metadata = MetaData()

shops = Table(
    "shops",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("name", String(120), nullable=False),
    Column("created_at", String(32), nullable=False),
)

users = Table(
    "users",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("shop_id", String(36), ForeignKey("shops.id"), nullable=False),
    Column("name", String(80), nullable=False),
    Column("email", String(254), nullable=False, unique=True),
    Column("password_hash", String(255), nullable=False),
    Column("role", String(16), nullable=False, default="staff"),
    Column("active", Boolean, nullable=False, default=True),
    Column("created_at", String(32), nullable=False),
)

products = Table(
    "products",
    metadata,
    Column("uuid", String(36), primary_key=True),
    Column("shop_id", String(36), ForeignKey("shops.id"), nullable=False),
    Column("barcode", String(32), nullable=False),
    Column("name", String(120), nullable=False),
    Column("unit", String(24), nullable=False),
    Column("reorder_point", Integer, nullable=False, default=0),
    Column("image_url", Text),
    # Client clock: decides last-write-wins between phones.
    Column("updated_at", String(32), nullable=False),
    Column("updated_by", String(80), nullable=False, default=""),
    Column("deleted", Boolean, nullable=False, default=False),
    # Server clock: drives "changed since" pulls.
    Column("server_updated_at", String(32), nullable=False),
    Index("idx_products_shop_changed", "shop_id", "server_updated_at"),
    Index("idx_products_shop_barcode", "shop_id", "barcode"),
)

movements = Table(
    "movements",
    metadata,
    Column("uuid", String(36), primary_key=True),
    Column("shop_id", String(36), ForeignKey("shops.id"), nullable=False),
    Column("product_uuid", String(36), nullable=False),
    Column("delta", Integer, nullable=False),
    Column("reason", String(16), nullable=False),
    Column("note", Text),
    Column("created_at", String(32), nullable=False),
    Column("user_id", String(36), nullable=False),
    Column("user_name", String(80), nullable=False, default=""),
    Column("server_received_at", String(32), nullable=False),
    Index("idx_movements_shop_received", "shop_id", "server_received_at"),
    Index("idx_movements_product", "product_uuid"),
)

device_tokens = Table(
    "device_tokens",
    metadata,
    Column("token", String(512), primary_key=True),
    Column("user_id", String(36), ForeignKey("users.id"), nullable=False),
    Column("shop_id", String(36), ForeignKey("shops.id"), nullable=False),
    Column("platform", String(16), nullable=False),
    Column("updated_at", String(32), nullable=False),
)


def now_iso() -> str:
    """Fixed-width UTC timestamps sort correctly as strings in any database."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def normalize_iso(value: str) -> str:
    """Accepts any ISO-8601 string from a client and returns the canonical form."""
    text = value.strip().replace("Z", "+00:00")
    parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def make_engine(url: str):
    if url.startswith("sqlite") and ":memory:" in url:
        return create_engine(url, connect_args={"check_same_thread": False}, poolclass=StaticPool)
    if url.startswith("postgres://"):
        url = "postgresql+psycopg://" + url[len("postgres://"):]
    elif url.startswith("postgresql://"):
        url = "postgresql+psycopg://" + url[len("postgresql://"):]
    return create_engine(url, pool_pre_ping=True)
