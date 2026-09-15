import os


class Config:
    """Everything secret lives here, on the server — never in the app."""

    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-only-change-me")
    # Supabase: Project settings → Database → Connection string (URI), with
    # the "postgresql+psycopg://" scheme. SQLite is for local runs and tests.
    DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///jerd-dev.db")
    TOKEN_TTL_DAYS = int(os.environ.get("TOKEN_TTL_DAYS", "30"))

    # Firebase service-account JSON: a file path or the JSON itself.
    FIREBASE_CREDENTIALS = os.environ.get("FIREBASE_CREDENTIALS", "")
    GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
    GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
    SENTRY_DSN = os.environ.get("SENTRY_DSN", "")
    # Shared secret for scheduler-triggered jobs such as the nightly digest.
    CRON_SECRET = os.environ.get("CRON_SECRET", "")

    # In-app upgrade check for the privately distributed APK.
    LATEST_VERSION = os.environ.get("LATEST_VERSION", "0.1.0")
    LATEST_BUILD = int(os.environ.get("LATEST_BUILD", "1"))
    MIN_BUILD = int(os.environ.get("MIN_BUILD", "1"))
    APK_URL = os.environ.get("APK_URL", "")
    RELEASE_NOTES = os.environ.get("RELEASE_NOTES", "")

    MAX_BATCH = 500
    TESTING = False
