from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from firebase_admin import messaging

from api.models import (
    Device,
    ItemStatus,
    Membership,
    PantryItem,
    SentExpiryNotification,
)
from api.services.firebase import send_push_notification


class Command(BaseCommand):
    help = "Send notifications about pantry products expiring in 1-3 days."

    def handle(self, *args, **options):
        today = timezone.localdate()

        target_dates = [
            today + timedelta(days=days)
            for days in range(1, 4)
        ]

        items = (
            PantryItem.objects
            .filter(
                status=ItemStatus.ACTIVE,
                expiry_date__in=target_dates,
            )
            .select_related("product", "household")
        )

        sent_count = 0
        error_count = 0
        processed_count = 0
        deleted_count = 0

        for item in items:
            with transaction.atomic():
                locked_item = (
                    PantryItem.objects
                    .select_for_update()
                    .filter(
                        pk=item.pk,
                        status=ItemStatus.ACTIVE,
                        expiry_date__in=target_dates,
                    )
                    .first()
                )

                if locked_item is None:
                    continue

                if SentExpiryNotification.objects.filter(
                    pantry_item=locked_item
                ).exists():
                    continue

                user_ids = Membership.objects.filter(
                    household_id=locked_item.household_id,
                ).values_list("user_id", flat=True)

                devices = list(
                    Device.objects.filter(
                        user_id__in=user_ids,
                        is_active=True,
                    ).exclude(user=None)
                )

                product_name = locked_item.product.name
                household_name = locked_item.household.name

                days_left = (
                    locked_item.expiry_date - today
                ).days

                if days_left == 1:
                    body = (
                        f"{product_name} traci ważność jutro! "
                        f"({household_name})"
                    )
                else:
                    body = (
                        f"{product_name} traci ważność za {days_left} dni! "
                        f"({household_name})"
                    )

                item_has_errors = False

                for device in devices:
                    try:
                        send_push_notification(
                            token=device.fcm_token,
                            title="Common Pantry",
                            body=body,
                            data={
                                "type": "expiry_reminder",
                                "pantry_item_id": locked_item.id,
                                "product_name": product_name,
                                "days_left": days_left,
                            },
                        )

                        sent_count += 1

                    except messaging.UnregisteredError:
                        device.delete()
                        deleted_count += 1

                        self.stderr.write(
                            self.style.WARNING(
                                f"Device {device.id} deleted: "
                                "FCM token is unregistered."
                            )
                        )

                    except messaging.InvalidArgumentError as exc:
                        error_count += 1
                        item_has_errors = True

                        self.stderr.write(
                            self.style.ERROR(
                                f"Invalid FCM argument for device "
                                f"{device.id}: {exc}"
                            )
                        )

                    except Exception as exc:
                        error_count += 1
                        item_has_errors = True

                        self.stderr.write(
                            self.style.ERROR(
                                f"FCM error for device {device.id}: {exc}"
                            )
                        )

                # Record notification only if all remaining sends succeeded.
                # This allows retrying after temporary errors.
                if not item_has_errors:
                    SentExpiryNotification.objects.create(
                        pantry_item=locked_item,
                    )
                    processed_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                "Expiry notifications processed. "
                f"Items: {processed_count}, "
                f"Sent: {sent_count}, "
                f"Errors: {error_count}, "
                f"Deleted devices: {deleted_count}"
            )
        )
