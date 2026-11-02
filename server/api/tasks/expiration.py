from celery import shared_task
from datetime import timedelta
from django.utils import timezone

from api.models import Product, NotificationHistory
from api.services.firebase import send_push_notification


@shared_task
def check_expiring_products():

    today = timezone.localdate()

    products = Product.objects.filter(
        expiration_date=today + timedelta(days=1)
    )

    for product in products:

        already_sent = NotificationHistory.objects.filter(
            product=product,
            notification_type="expiration_1_day"
        ).exists()

        if already_sent:
            continue

        send_push_notification(
            user=product.user,
            title="Produkt traci ważność!",
            body=f"{product.name} kończy ważność jutro.",
            data={
                "product_id": str(product.id)
            }
        )

        NotificationHistory.objects.create(
            user=product.user,
            product=product,
            notification_type="expiration_1_day"
        )