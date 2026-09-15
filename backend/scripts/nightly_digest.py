"""Nightly digest, run by hand. In production GitHub Actions calls
POST /jobs/nightly-digest instead (see .github/workflows/nightly-digest.yml)."""

from dotenv import load_dotenv

load_dotenv()

from app import create_app  # noqa: E402
from app.services.digest import send_digest  # noqa: E402


def run(app) -> int:
    return send_digest(app.engine, app.push)


if __name__ == "__main__":
    print(f"Digest sent to {run(create_app())} shops")
