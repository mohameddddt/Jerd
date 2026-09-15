import uuid
from datetime import datetime, timedelta, timezone

from flask import Blueprint, current_app, g, jsonify, request
from sqlalchemy import func, insert, select, update
from sqlalchemy.exc import IntegrityError
from werkzeug.security import check_password_hash, generate_password_hash

from .auth import error, issue_token, login_required, owner_required, public_user
from .db import device_tokens, movements, normalize_iso, now_iso, products, shops, users
from .services import gemini
from .services.stock import crossed_reorder_point, low_stock, stock_for

api = Blueprint("api", __name__)

VALID_REASONS = {"received", "sold", "adjusted", "counted"}


def engine():
    return current_app.engine


def product_json(row) -> dict:
    return {
        "uuid": row["uuid"],
        "barcode": row["barcode"],
        "name": row["name"],
        "unit": row["unit"],
        "reorder_point": row["reorder_point"],
        "image_url": row["image_url"],
        "updated_at": row["updated_at"],
        "updated_by": row["updated_by"],
        "deleted": bool(row["deleted"]),
    }


def movement_json(row) -> dict:
    return {
        "uuid": row["uuid"],
        "product_uuid": row["product_uuid"],
        "delta": row["delta"],
        "reason": row["reason"],
        "note": row["note"],
        "created_at": row["created_at"],
        "user_id": row["user_id"],
        "user_name": row["user_name"],
    }


def json_body() -> dict:
    body = request.get_json(silent=True)
    return body if isinstance(body, dict) else {}


# ---------------------------------------------------------------- meta


@api.get("/health")
def health():
    with engine().connect() as conn:
        conn.execute(select(1))
    return jsonify({"status": "ok", "server_time": now_iso()})


@api.get("/app/version")
def app_version():
    cfg = current_app.config
    return jsonify(
        {
            "latest_version": cfg["LATEST_VERSION"],
            "latest_build": cfg["LATEST_BUILD"],
            "min_build": cfg["MIN_BUILD"],
            "apk_url": cfg["APK_URL"],
            "notes": cfg["RELEASE_NOTES"],
        }
    )


# ---------------------------------------------------------------- auth


@api.post("/auth/login")
def login():
    body = json_body()
    email = str(body.get("email", "")).strip().lower()
    password = str(body.get("password", ""))
    if not email or not password:
        return error("Email and password are required", 400)
    with engine().connect() as conn:
        user = conn.execute(select(users).where(users.c.email == email)).mappings().first()
        if user is None or not user["active"] or not check_password_hash(user["password_hash"], password):
            return error("Wrong email or password", 401)
        shop = conn.execute(select(shops.c.name).where(shops.c.id == user["shop_id"])).scalar_one()
    return jsonify(
        {
            "token": issue_token(user["id"], user["shop_id"], user["role"]),
            "user": {**public_user(user), "shop_name": shop},
        }
    )


@api.post("/auth/logout")
@login_required
def logout():
    # Tokens are stateless; the app forgets its copy. Remove this device's push token.
    with engine().begin() as conn:
        conn.execute(device_tokens.delete().where(device_tokens.c.user_id == g.user["id"]))
    return jsonify({"ok": True})


# ---------------------------------------------------------------- staff


@api.get("/staff")
@login_required
def list_staff():
    with engine().connect() as conn:
        rows = conn.execute(
            select(users)
            .where(users.c.shop_id == g.shop_id, users.c.active.is_(True))
            .order_by(users.c.role.desc(), users.c.name)
        ).mappings()
        return jsonify({"users": [public_user(row) for row in rows]})


@api.post("/staff")
@owner_required
def add_staff():
    body = json_body()
    name = str(body.get("name", "")).strip()
    email = str(body.get("email", "")).strip().lower()
    password = str(body.get("password", ""))
    role = body.get("role", "staff")
    if not name or "@" not in email or len(password) < 6 or role not in ("owner", "staff"):
        return error("Name, a valid email, a 6+ character password and a role are required", 400)
    with engine().begin() as conn:
        count = conn.execute(
            select(func.count()).select_from(users).where(users.c.shop_id == g.shop_id, users.c.active.is_(True))
        ).scalar_one()
        if count >= 5:
            return error("A shop can have at most 5 accounts", 400)
        row = {
            "id": str(uuid.uuid4()),
            "shop_id": g.shop_id,
            "name": name,
            "email": email,
            "password_hash": generate_password_hash(password),
            "role": role,
            "active": True,
            "created_at": now_iso(),
        }
        try:
            conn.execute(insert(users).values(**row))
        except IntegrityError:
            return error("This email is already used", 409)
    return jsonify({"user": public_user(row)}), 201


@api.delete("/staff/<user_id>")
@owner_required
def remove_staff(user_id):
    if user_id == g.user["id"]:
        return error("You cannot remove your own account", 403)
    with engine().begin() as conn:
        result = conn.execute(
            update(users).where(users.c.id == user_id, users.c.shop_id == g.shop_id).values(active=False)
        )
        conn.execute(device_tokens.delete().where(device_tokens.c.user_id == user_id))
    if result.rowcount == 0:
        return error("Not found", 404)
    return jsonify({"ok": True})


# ---------------------------------------------------------------- products


@api.get("/products")
@login_required
def get_products():
    """Everything changed since a timestamp (or all), optionally by barcode."""
    since = request.args.get("since")
    barcode = request.args.get("barcode")
    server_time = now_iso()
    query = select(products).where(products.c.shop_id == g.shop_id)
    if since:
        try:
            query = query.where(products.c.server_updated_at >= normalize_iso(since))
        except ValueError:
            return error("Invalid since", 400)
    if barcode:
        query = query.where(products.c.barcode == barcode, products.c.deleted.is_(False))
    with engine().connect() as conn:
        rows = conn.execute(query.order_by(products.c.server_updated_at)).mappings()
        return jsonify({"products": [product_json(row) for row in rows], "server_time": server_time})


@api.get("/products/<product_uuid>")
@login_required
def get_product(product_uuid):
    with engine().connect() as conn:
        row = conn.execute(
            select(products).where(products.c.uuid == product_uuid, products.c.shop_id == g.shop_id)
        ).mappings().first()
    if row is None:
        return error("Not found", 404)
    return jsonify({"product": product_json(row)})


@api.post("/products/upsert")
@login_required
def upsert_products():
    """Last-write-wins on the client's updated_at. A stale write gets the
    server's row back so the phone can apply it and report the conflict."""
    items = json_body().get("products")
    if not isinstance(items, list) or len(items) > current_app.config["MAX_BATCH"]:
        return error("products must be a list of at most 500 items", 400)
    results = []
    with engine().begin() as conn:
        for item in items:
            try:
                incoming = {
                    "uuid": str(uuid.UUID(str(item["uuid"]))),
                    "barcode": str(item["barcode"]).strip(),
                    "name": str(item["name"]).strip(),
                    "unit": str(item["unit"]).strip(),
                    "reorder_point": int(item.get("reorder_point", 0)),
                    "image_url": item.get("image_url"),
                    "updated_at": normalize_iso(str(item["updated_at"])),
                    "updated_by": str(item.get("updated_by") or g.user["name"]),
                    "deleted": bool(item.get("deleted", False)),
                }
            except (KeyError, ValueError, TypeError):
                return error("Invalid product in batch", 400)
            if not incoming["name"] or not incoming["barcode"] or incoming["reorder_point"] < 0:
                return error("Invalid product in batch", 400)

            current = conn.execute(select(products).where(products.c.uuid == incoming["uuid"])).mappings().first()
            if current is not None and current["shop_id"] != g.shop_id:
                return error("Invalid product in batch", 400)
            if current is not None and current["updated_at"] > incoming["updated_at"]:
                results.append({"uuid": incoming["uuid"], "status": "stale", "product": product_json(current)})
                continue
            values = {**incoming, "shop_id": g.shop_id, "server_updated_at": now_iso()}
            if current is None:
                conn.execute(insert(products).values(**values))
            else:
                conn.execute(update(products).where(products.c.uuid == incoming["uuid"]).values(**values))
            results.append({"uuid": incoming["uuid"], "status": "applied"})
    return jsonify({"results": results, "server_time": now_iso()})


# ---------------------------------------------------------------- movements


@api.post("/movements/push")
@login_required
def push_movements():
    """Accepts a batch. Inserts are keyed on the client UUID, so a retried
    request can never double-apply. Pushes an alert when an item crosses its
    reorder point."""
    items = json_body().get("movements")
    if not isinstance(items, list) or len(items) > current_app.config["MAX_BATCH"]:
        return error("movements must be a list of at most 500 items", 400)
    parsed = []
    for item in items:
        try:
            row = {
                "uuid": str(uuid.UUID(str(item["uuid"]))),
                "product_uuid": str(item["product_uuid"]),
                "delta": int(item["delta"]),
                "reason": str(item["reason"]),
                "note": (str(item["note"])[:500] if item.get("note") else None),
                "created_at": normalize_iso(str(item["created_at"])),
                "user_id": g.user["id"],
                "user_name": g.user["name"],
            }
        except (KeyError, ValueError, TypeError):
            return error("Invalid movement in batch", 400)
        if row["reason"] not in VALID_REASONS or row["delta"] == 0:
            return error("Invalid movement in batch", 400)
        parsed.append(row)

    accepted = []
    affected = {row["product_uuid"] for row in parsed}
    with engine().begin() as conn:
        before = stock_for(conn, g.shop_id, affected)
        existing = {
            uuid_ for (uuid_,) in conn.execute(
                select(movements.c.uuid).where(movements.c.uuid.in_([row["uuid"] for row in parsed]))
            )
        }
        received_at = now_iso()
        for row in parsed:
            if row["uuid"] not in existing:
                conn.execute(insert(movements).values(**row, shop_id=g.shop_id, server_received_at=received_at))
                existing.add(row["uuid"])
            accepted.append(row["uuid"])
        after = stock_for(conn, g.shop_id, affected)
        crossed = conn.execute(
            select(products).where(products.c.uuid.in_(affected), products.c.shop_id == g.shop_id)
        ).mappings().all()

    for product in crossed:
        if product["deleted"]:
            continue
        old, new = before.get(product["uuid"], 0), after.get(product["uuid"], 0)
        if crossed_reorder_point(old, new, product["reorder_point"]):
            title = f"{product['name']} is running low" if new > 0 else f"{product['name']} is out of stock"
            current_app.push.send_to_shop(
                g.shop_id,
                title=title,
                body=f"{new} {product['unit']} left (reorder at {product['reorder_point']}).",
                data={"type": "low_stock", "product_uuid": product["uuid"]},
            )
    return jsonify({"accepted": accepted, "server_time": now_iso()})


@api.get("/movements")
@login_required
def get_movements():
    since = request.args.get("since")
    product_uuid = request.args.get("product_uuid")
    start, end = request.args.get("from"), request.args.get("to")
    server_time = now_iso()
    query = select(movements).where(movements.c.shop_id == g.shop_id)
    try:
        if since:
            query = query.where(movements.c.server_received_at >= normalize_iso(since))
        if start:
            query = query.where(movements.c.created_at >= normalize_iso(start))
        if end:
            query = query.where(movements.c.created_at < normalize_iso(end))
    except ValueError:
        return error("Invalid timestamp", 400)
    if product_uuid:
        query = query.where(movements.c.product_uuid == product_uuid)
    with engine().connect() as conn:
        rows = conn.execute(query.order_by(movements.c.server_received_at)).mappings()
        return jsonify({"movements": [movement_json(row) for row in rows], "server_time": server_time})


@api.get("/stock")
@login_required
def get_stock():
    product_uuid = request.args.get("product_uuid")
    with engine().connect() as conn:
        if product_uuid:
            return jsonify({"stock": stock_for(conn, g.shop_id, [product_uuid]).get(product_uuid, 0)})
        return jsonify({"stocks": stock_for(conn, g.shop_id)})


@api.get("/alerts")
@login_required
def get_alerts():
    with engine().connect() as conn:
        items = low_stock(conn, g.shop_id)
    return jsonify({"alerts": [{"product": product_json(i["product"]), "stock": i["stock"]} for i in items]})


# ---------------------------------------------------------------- devices


@api.post("/device/register")
@login_required
def register_device():
    body = json_body()
    token = str(body.get("token", "")).strip()
    if not token:
        return error("token is required", 400)
    values = {
        "user_id": g.user["id"],
        "shop_id": g.shop_id,
        "platform": str(body.get("platform", "android"))[:16],
        "updated_at": now_iso(),
    }
    with engine().begin() as conn:
        exists = conn.execute(select(device_tokens.c.token).where(device_tokens.c.token == token)).first()
        if exists:
            conn.execute(update(device_tokens).where(device_tokens.c.token == token).values(**values))
        else:
            conn.execute(insert(device_tokens).values(token=token, **values))
    return jsonify({"ok": True, "topic": f"shop_{g.shop_id}"})


# ---------------------------------------------------------------- AI


@api.post("/ai/suggest")
@login_required
def ai_suggest():
    cfg = current_app.config
    if not cfg["GEMINI_API_KEY"]:
        return error("AI suggestions are not configured", 503)
    body = json_body()
    image = body.get("image_base64")
    if not isinstance(image, str) or not image or len(image) > 8_000_000:
        return error("image_base64 is required (max ~6 MB)", 400)
    mime = body.get("mime_type", "image/jpeg")
    if mime not in ("image/jpeg", "image/png", "image/webp"):
        return error("Unsupported image type", 400)
    try:
        return jsonify(gemini.suggest_product(cfg["GEMINI_API_KEY"], cfg["GEMINI_MODEL"], image, mime, body.get("barcode")))
    except gemini.GeminiError as exc:
        return error(str(exc), 502)


@api.get("/ai/reorder")
@login_required
def ai_reorder():
    cfg = current_app.config
    if not cfg["GEMINI_API_KEY"]:
        return error("AI suggestions are not configured", 503)
    since = (datetime.now(timezone.utc) - timedelta(days=14)).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    with engine().connect() as conn:
        stocks = stock_for(conn, g.shop_id)
        sold = dict(
            conn.execute(
                select(movements.c.product_uuid, func.sum(-movements.c.delta))
                .where(
                    movements.c.shop_id == g.shop_id,
                    movements.c.reason == "sold",
                    movements.c.created_at >= since,
                )
                .group_by(movements.c.product_uuid)
            ).all()
        )
        rows = conn.execute(
            select(products).where(products.c.shop_id == g.shop_id, products.c.deleted.is_(False))
        ).mappings().all()
    lines = [
        f"- {row['name']}: stock {stocks.get(row['uuid'], 0)} {row['unit']}, "
        f"reorder at {row['reorder_point']}, sold {int(sold.get(row['uuid']) or 0)} in 14 days"
        for row in rows
    ]
    if not lines:
        return jsonify({"suggestion": ""})
    language = {"ar": "Arabic", "fr": "French"}.get(request.accept_languages.best_match(["ar", "fr", "en"]) or "en", "English")
    try:
        return jsonify({"suggestion": gemini.reorder_suggestions(cfg["GEMINI_API_KEY"], cfg["GEMINI_MODEL"], lines[:80], language)})
    except gemini.GeminiError as exc:
        return error(str(exc), 502)
