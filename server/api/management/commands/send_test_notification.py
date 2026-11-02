from django.core.management.base import BaseCommand
from firebase_admin import messaging

from api.models import Device
from api.services.firebase import send_push_notification


class Command(BaseCommand):
    help = "Send a test push notification to all active devices."

    def handle(self, *args, **options):
        devices = Device.objects.filter(
            is_active=True,
        ).exclude(
            user=None,
        )

        sent_count = 0
        error_count = 0
        deleted_count = 0

        for device in devices:
            try:
                send_push_notification(
                    token=device.fcm_token,
                    title="Common Pantry - TEST",
                    body="To jest testowe powiadomienie push!",
                    data={
                        "type": "test_notification",
                        "message": "Hello from Django!",
                    },
                )

                sent_count += 1

                self.stdout.write(
                    self.style.SUCCESS(
                        f"Notification sent to device {device.id}"
                    )
                )

            except messaging.UnregisteredError:
                device.delete()
                deleted_count += 1

                self.stderr.write(
                    self.style.WARNING(
                        f"Device {device.id} deleted: FCM token is unregistered."
                    )
                )

            except messaging.InvalidArgumentError as exc:
                error_count += 1

                self.stderr.write(
                    self.style.ERROR(
                        f"Invalid argument for device {device.id}: {exc}. "
                        "Device was not deleted."
                    )
                )

            except Exception as exc:
                error_count += 1

                self.stderr.write(
                    self.style.ERROR(
                        f"FCM error for device {device.id}: {exc}"
                    )
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"Test notifications completed. "
                f"Sent: {sent_count}, "
                f"Errors: {error_count}, "
                f"Deleted devices: {deleted_count}"
            )
        )
