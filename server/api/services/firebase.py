import os

import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings


def get_firebase_app():
    """Initialize Firebase Admin SDK once."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        credentials_path = settings.FIREBASE_CREDENTIALS

        credential = credentials.Certificate(credentials_path)

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
