from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import current_app, g, jsonify, request
from sqlalchemy import select

from .db import users


def issue_token(user_id: str, shop_id: str, role: str) -> str:
    ttl = timedelta(days=current_app.config["TOKEN_TTL_DAYS"])
    payload = {
        "sub": user_id,
        "shop": shop_id,
        "role": role,
        "exp": datetime.now(timezone.utc) + ttl,
    }
    return jwt.encode(payload, current_app.config["SECRET_KEY"], algorithm="HS256")


def error(message: str, status: int):
    return jsonify({"error": message}), status


def login_required(view):
    """Resolves the bearer token to an active user; every query is scoped to g.shop_id."""

    @wraps(view)
    def wrapper(*args, **kwargs):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return error("Missing token", 401)
        try:
            claims = jwt.decode(header[7:], current_app.config["SECRET_KEY"], algorithms=["HS256"])
        except jwt.PyJWTError:
            return error("Invalid or expired token", 401)
        with current_app.engine.connect() as conn:
            row = conn.execute(select(users).where(users.c.id == claims["sub"])).mappings().first()
        if row is None or not row["active"]:
            return error("Account disabled", 401)
        g.user = row
        g.shop_id = row["shop_id"]
        return view(*args, **kwargs)

    return wrapper


def owner_required(view):
    @wraps(view)
    @login_required
    def wrapper(*args, **kwargs):
        if g.user["role"] != "owner":
            return error("Only the shop owner can do this", 403)
        return view(*args, **kwargs)

    return wrapper


def public_user(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "email": row["email"],
        "role": row["role"],
        "shop_id": row["shop_id"],
    }
