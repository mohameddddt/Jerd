"""Create a shop and its owner account.

    python -m scripts.seed --shop "Karim's shop" --name Karim --email karim@example.com --password secret123
"""

import argparse
import uuid

from dotenv import load_dotenv
from sqlalchemy import insert, select
from werkzeug.security import generate_password_hash

load_dotenv()

from app import create_app  # noqa: E402
from app.db import now_iso, shops, users  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--shop", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    if len(args.password) < 6:
        parser.error("password must be at least 6 characters")

    app = create_app()
    email = args.email.strip().lower()
    with app.engine.begin() as conn:
        if conn.execute(select(users.c.id).where(users.c.email == email)).first():
            parser.error(f"{email} already exists")
        shop_id = str(uuid.uuid4())
        conn.execute(insert(shops).values(id=shop_id, name=args.shop, created_at=now_iso()))
        conn.execute(
            insert(users).values(
                id=str(uuid.uuid4()),
                shop_id=shop_id,
                name=args.name,
                email=email,
                password_hash=generate_password_hash(args.password),
                role="owner",
                active=True,
                created_at=now_iso(),
            )
        )
    print(f"Created shop {args.shop!r} ({shop_id}) with owner {email}")


if __name__ == "__main__":
    main()
