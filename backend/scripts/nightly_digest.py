"""Nightly digest: one push per shop listing what needs restocking.
Scheduled as a Render cron job (see render.yaml)."""

from dotenv import load_dotenv
from sqlalchemy import select

load_dotenv()

from app import create_app  # noqa: E402
from app.db import shops  # noqa: E402
from app.services.stock import low_stock  # noqa: E402


def run(app) -> int:
    sent = 0
    with app.engine.connect() as conn:
        for shop in conn.execute(select(shops)).mappings().all():
            items = low_stock(conn, shop["id"])
            if not items:
                continue
            names = ", ".join(item["product"]["name"] for item in items[:3])
            more = f" and {len(items) - 3} more" if len(items) > 3 else ""
            app.push.send_to_shop(
                shop["id"],
                title=f"{len(items)} item{'' if len(items) == 1 else 's'} to restock",
                body=f"{names}{more}.",
                data={"type": "digest"},
            )
            sent += 1
    return sent


if __name__ == "__main__":
    print(f"Digest sent to {run(create_app())} shops")
