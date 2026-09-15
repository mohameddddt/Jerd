import uuid

import pytest
from sqlalchemy import insert
from werkzeug.security import generate_password_hash

from app import create_app
from app.config import Config
from app.db import now_iso, shops, users
from app.services.push import PushSender


class TestConfig(Config):
    TESTING = True
    DATABASE_URL = "sqlite:///:memory:"
    SECRET_KEY = "test"


def uid() -> str:
    return str(uuid.uuid4())


@pytest.fixture()
def app():
    app = create_app(TestConfig, push=PushSender(""))
    with app.engine.begin() as conn:
        for shop_id, name in (("shop-a", "A"), ("shop-b", "B")):
            conn.execute(insert(shops).values(id=shop_id, name=name, created_at=now_iso()))
        for user_id, shop_id, name, email, role in (
            ("karim", "shop-a", "Karim", "karim@example.com", "owner"),
            ("amina", "shop-a", "Amina", "amina@example.com", "staff"),
            ("other", "shop-b", "Other", "other@example.com", "owner"),
        ):
            conn.execute(
                insert(users).values(
                    id=user_id,
                    shop_id=shop_id,
                    name=name,
                    email=email,
                    password_hash=generate_password_hash("secret123"),
                    role=role,
                    active=True,
                    created_at=now_iso(),
                )
            )
    return app


@pytest.fixture()
def client(app):
    return app.test_client()


def login(client, email="karim@example.com"):
    response = client.post("/auth/login", json={"email": email, "password": "secret123"})
    assert response.status_code == 200, response.json
    return {"Authorization": f"Bearer {response.json['token']}"}


def product(uuid_=None, name="Olive oil 1L", barcode="6130000100010", updated_at="2026-09-14T10:00:00.000Z", reorder=6):
    return {
        "uuid": uuid_ or uid(),
        "barcode": barcode,
        "name": name,
        "unit": "bottles",
        "reorder_point": reorder,
        "image_url": None,
        "updated_at": updated_at,
        "updated_by": "Karim",
        "deleted": False,
    }


def movement(product_uuid, delta, reason="sold", uuid_=None):
    return {
        "uuid": uuid_ or uid(),
        "product_uuid": product_uuid,
        "delta": delta,
        "reason": reason,
        "note": None,
        "created_at": "2026-09-14T10:05:00.000Z",
    }


def test_health_and_version(client):
    assert client.get("/health").json["status"] == "ok"
    assert "latest_build" in client.get("/app/version").json


def test_login_rejects_bad_credentials(client):
    assert client.post("/auth/login", json={"email": "karim@example.com", "password": "nope"}).status_code == 401
    assert client.get("/products").status_code == 401
    assert client.get("/products", headers={"Authorization": "Bearer junk"}).status_code == 401


def test_login_returns_user_and_shop(client):
    response = client.post("/auth/login", json={"email": " KARIM@example.com ", "password": "secret123"})
    assert response.json["user"]["role"] == "owner"
    assert response.json["user"]["shop_name"] == "A"


def test_products_upsert_and_pull_since(client):
    headers = login(client)
    first = client.get("/products", headers=headers).json
    p = product()
    result = client.post("/products/upsert", json={"products": [p]}, headers=headers).json
    assert result["results"] == [{"uuid": p["uuid"], "status": "applied"}]

    pulled = client.get("/products", query_string={"since": first["server_time"]}, headers=headers).json
    assert [row["name"] for row in pulled["products"]] == ["Olive oil 1L"]
    later = client.get("/products", query_string={"since": pulled["server_time"]}, headers=headers).json
    assert later["products"] == []


def test_last_write_wins_returns_server_row_to_the_loser(client):
    headers = login(client)
    p = product(name="Pasta 500g", updated_at="2026-09-14T11:02:00Z")
    client.post("/products/upsert", json={"products": [p]}, headers=headers)
    stale = {**p, "name": "Spaghetti 500g", "updated_at": "2026-09-14T10:58:00Z"}
    result = client.post("/products/upsert", json={"products": [stale]}, headers=login(client, "amina@example.com")).json
    assert result["results"][0]["status"] == "stale"
    assert result["results"][0]["product"]["name"] == "Pasta 500g"


def test_movement_push_is_idempotent(client):
    headers = login(client)
    p = product()
    client.post("/products/upsert", json={"products": [p]}, headers=headers)
    batch = [movement(p["uuid"], 25, "received"), movement(p["uuid"], -1)]
    first = client.post("/movements/push", json={"movements": batch}, headers=headers).json
    retry = client.post("/movements/push", json={"movements": batch}, headers=headers).json
    assert set(first["accepted"]) == set(retry["accepted"]) == {m["uuid"] for m in batch}
    assert client.get("/stock", query_string={"product_uuid": p["uuid"]}, headers=headers).json["stock"] == 24
    assert len(client.get("/movements", headers=headers).json["movements"]) == 2


def test_movements_from_two_phones_are_both_kept(client):
    p = product()
    client.post("/products/upsert", json={"products": [p]}, headers=login(client))
    client.post("/movements/push", json={"movements": [movement(p["uuid"], 10, "received")]}, headers=login(client))
    client.post("/movements/push", json={"movements": [movement(p["uuid"], -1)]}, headers=login(client))
    client.post("/movements/push", json={"movements": [movement(p["uuid"], -1)]}, headers=login(client, "amina@example.com"))
    assert client.get("/stock", query_string={"product_uuid": p["uuid"]}, headers=login(client)).json["stock"] == 8


def test_crossing_the_reorder_point_pushes_once(app, client):
    headers = login(client)
    p = product(reorder=6)
    client.post("/products/upsert", json={"products": [p]}, headers=headers)
    client.post("/movements/push", json={"movements": [movement(p["uuid"], 10, "received")]}, headers=headers)
    assert app.push.sent == []
    client.post("/movements/push", json={"movements": [movement(p["uuid"], -5)]}, headers=headers)
    client.post("/movements/push", json={"movements": [movement(p["uuid"], -1)]}, headers=headers)
    assert len(app.push.sent) == 1
    sent = app.push.sent[0]
    assert sent["topic"] == "shop_shop-a"
    assert sent["data"] == {"type": "low_stock", "product_uuid": p["uuid"]}


def test_alerts_are_most_urgent_first(client):
    headers = login(client)
    oil, semolina, water = product(reorder=6), product(name="Semolina", barcode="2", reorder=10), product(name="Water", barcode="3", reorder=5)
    client.post("/products/upsert", json={"products": [oil, semolina, water]}, headers=headers)
    client.post(
        "/movements/push",
        json={"movements": [movement(oil["uuid"], 3, "received"), movement(water["uuid"], 48, "received")]},
        headers=headers,
    )
    alerts = client.get("/alerts", headers=headers).json["alerts"]
    assert [a["product"]["name"] for a in alerts] == ["Semolina", "Olive oil 1L"]


def test_shops_are_isolated(client):
    p = product()
    client.post("/products/upsert", json={"products": [p]}, headers=login(client))
    other = login(client, "other@example.com")
    assert client.get("/products", headers=other).json["products"] == []
    assert client.get(f"/products/{p['uuid']}", headers=other).status_code == 404
    hijack = client.post("/products/upsert", json={"products": [{**p, "name": "Mine now", "updated_at": "2030-01-01T00:00:00Z"}]}, headers=other)
    assert hijack.status_code == 400


def test_invalid_batches_are_rejected(client):
    headers = login(client)
    assert client.post("/movements/push", json={"movements": [{"uuid": "x"}]}, headers=headers).status_code == 400
    assert client.post("/movements/push", json={"movements": [movement(uid(), 0)]}, headers=headers).status_code == 400
    assert client.post("/products/upsert", json={"products": [product(name="")]}, headers=headers).status_code == 400


def test_only_owner_manages_staff(client):
    staff = login(client, "amina@example.com")
    body = {"name": "Yacine", "email": "yacine@example.com", "password": "secret123", "role": "staff"}
    assert client.post("/staff", json=body, headers=staff).status_code == 403

    owner = login(client)
    created = client.post("/staff", json=body, headers=owner)
    assert created.status_code == 201
    assert client.post("/staff", json=body, headers=owner).status_code == 409
    assert len(client.get("/staff", headers=staff).json["users"]) == 3

    new_id = created.json["user"]["id"]
    assert client.delete(f"/staff/{new_id}", headers=owner).status_code == 200
    assert client.post("/auth/login", json={"email": "yacine@example.com", "password": "secret123"}).status_code == 401
    assert client.delete("/staff/karim", headers=owner).status_code == 403


def test_device_register_and_ai_not_configured(client):
    headers = login(client)
    assert client.post("/device/register", json={"token": "fcm-token", "platform": "android"}, headers=headers).json["topic"] == "shop_shop-a"
    assert client.post("/ai/suggest", json={"image_base64": "abc"}, headers=headers).status_code == 503


def test_nightly_digest(app, client):
    from scripts.nightly_digest import run

    headers = login(client)
    client.post("/products/upsert", json={"products": [product()]}, headers=headers)
    assert run(app) == 1
    assert app.push.sent[-1]["title"] == "1 item to restock"
