import logging

from flask import Flask, jsonify

from .config import Config
from .db import make_engine, metadata
from .routes import api
from .services.push import PushSender


def create_app(config: type[Config] | Config = Config, push: PushSender | None = None) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config)
    logging.basicConfig(level=logging.INFO)

    if app.config["SENTRY_DSN"] and not app.config["TESTING"]:
        import sentry_sdk

        sentry_sdk.init(dsn=app.config["SENTRY_DSN"], traces_sample_rate=0.2, send_default_pii=False)

    app.engine = make_engine(app.config["DATABASE_URL"])
    # Creates missing tables; on Supabase you can run schema.sql instead.
    metadata.create_all(app.engine)
    app.push = push or PushSender(app.config["FIREBASE_CREDENTIALS"])

    app.register_blueprint(api)

    @app.errorhandler(404)
    def not_found(_):
        return jsonify({"error": "Not found"}), 404

    @app.errorhandler(405)
    def not_allowed(_):
        return jsonify({"error": "Method not allowed"}), 405

    @app.errorhandler(500)
    def server_error(_):
        return jsonify({"error": "Server error"}), 500

    return app
