"""Nightly digest: one push per shop listing what needs restocking."""

from sqlalchemy import select

from ..db import shops
from .stock import low_stock


def send_digest(engine, push) -> int:
    sent = 0
    with engine.connect() as conn:
        for shop in conn.execute(select(shops)).mappings().all():
            items = low_stock(conn, shop["id"])
            if not items:
                continue
            names = ", ".join(item["product"]["name"] for item in items[:3])
            more = f" and {len(items) - 3} more" if len(items) > 3 else ""
            push.send_to_shop(
                shop["id"],
                title=f"{len(items)} item{'' if len(items) == 1 else 's'} to restock",
                body=f"{names}{more}.",
                data={"type": "digest"},
            )
            sent += 1
    return sent
