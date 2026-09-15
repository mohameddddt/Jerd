"""Firebase Cloud Messaging. The device never polls for alerts; the server pushes."""

import json
import logging
import os

log = logging.getLogger(__name__)
_app = None
_disabled = False


def _init(credentials_setting: str):
    global _app, _disabled
    if _app is not None or _disabled:
        return _app
    if not credentials_setting:
        _disabled = True
        log.warning("FIREBASE_CREDENTIALS not set; push notifications are disabled")
        return None
    import firebase_admin
    from firebase_admin import credentials

    if os.path.exists(credentials_setting):
        cred = credentials.Certificate(credentials_setting)
    else:
        cred = credentials.Certificate(json.loads(credentials_setting))
    _app = firebase_admin.initialize_app(cred)
    return _app


class PushSender:
    """Swappable in tests; records what would have been sent."""

    def __init__(self, credentials_setting: str = ""):
        self.credentials_setting = credentials_setting
        self.sent: list[dict] = []

    def send_to_shop(self, shop_id: str, title: str, body: str, data: dict | None = None) -> None:
        message = {"topic": f"shop_{shop_id}", "title": title, "body": body, "data": data or {}}
        self.sent.append(message)
        app = _init(self.credentials_setting)
        if app is None:
            return
        from firebase_admin import messaging

        try:
            messaging.send(
                messaging.Message(
                    topic=message["topic"],
                    notification=messaging.Notification(title=title, body=body),
                    data={key: str(value) for key, value in message["data"].items()},
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(channel_id="stock_alerts"),
                    ),
                )
            )
        except Exception:  # A failed push must never fail a sync.
            log.exception("FCM send failed")
