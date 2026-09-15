"""Milestone 9 demo: send a low-stock push that opens a product when tapped.

    python -m scripts.send_test_push --shop <shop_id> --product <product_uuid>
"""

import argparse

from dotenv import load_dotenv

load_dotenv()

from app import create_app  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--shop", required=True)
    parser.add_argument("--product", required=True)
    parser.add_argument("--title", default="Olive oil 1L is running low")
    parser.add_argument("--body", default="3 bottles left (reorder at 6).")
    args = parser.parse_args()

    app = create_app()
    if not app.config["FIREBASE_CREDENTIALS"]:
        parser.error("Set FIREBASE_CREDENTIALS first")
    app.push.send_to_shop(args.shop, args.title, args.body, {"type": "low_stock", "product_uuid": args.product})
    print(f"Sent to topic shop_{args.shop}")


if __name__ == "__main__":
    main()
