import json
import os

import firebase_admin
from django.conf import settings
from firebase_admin import credentials, messaging


def get_firebase_app():
    """Initialize Firebase Admin SDK once."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        credentials_json = os.environ.get("FIREBASE_CREDENTIALS_JSON")

        if credentials_json:
            cred_dict = json.loads(credentials_json)
            credential = credentials.Certificate(cred_dict)
        else:
            credential = credentials.Certificate(settings.FIREBASE_CREDENTIALS)

        return firebase_admin.initialize_app(credential)


def send_push_notification(token, title, body, data=None):
    """Send a push notification to one device."""
    app = get_firebase_app()

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            str(key): str(value)
            for key, value in (data or {}).items()
        },
        token=token,
    )

    return messaging.send(message, app=app)
