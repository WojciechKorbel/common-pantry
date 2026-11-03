from datetime import timedelta
from decimal import Decimal
import random
import secrets

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from api.models import (
    Category,
    Household,
    Membership,
    MembershipRole,
    PantryItem,
    Product,
    ProductType,
    ItemStatus,
)


class Command(BaseCommand):
    help = "Creates a demo household with food waste statistics data."

    PRODUCT_DATA = [
        ("Milk 1L", "Example Brand"),
        ("Natural Yogurt", "Example Brand"),
        ("Cheese", "Example Brand"),
        ("White Bread", "Example Brand"),
        ("Apples", None),
        ("Tomatoes", None),
        ("Chicken Breast", None),
        ("Rice", "Example Brand"),
        ("Orange Juice", "Example Brand"),
        ("Frozen Pizza", "Example Brand"),
        ("Chocolate", "Example Brand"),
        ("Bananas", None),
        ("Butter", "Example Brand"),
        ("Cucumbers", None),
        ("Spaghetti", "Example Brand"),
        ("Eggs", None),
        ("Carrots", None),
        ("Ham", "Example Brand"),
        ("Orange", None),
        ("Biscuits", "Example Brand"),
        ("Potatoes", None),
        ("Onions", None),
        ("Salmon", None),
        ("Ground Beef", None),
        ("Cream", "Example Brand"),
        ("Strawberries", None),
        ("Grapes", None),
        ("Lettuce", None),
        ("Cereal", "Example Brand"),
        ("Oat Milk", "Example Brand"),
    ]

    HISTORY_ITEMS = 180
    ACTIVE_ITEMS = 15
    HISTORY_DAYS = 365

    def add_arguments(self, parser):
        parser.add_argument("--name", required=True)
        parser.add_argument("--username", required=True)

    @transaction.atomic
    def handle(self, *args, **options):
        name = options["name"]
        username = options["username"]

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(
                f"User '{username}' does not exist."
            )

        if Membership.objects.filter(user=user).exists():
            self.stdout.write(
                self.style.WARNING(
                    "User already belongs to a household. "
                    "A new household will also be created."
                )
            )

        household = Household.objects.create(
            name=name,
            invite_code=self.generate_invite_code(),
        )

        Membership.objects.create(
            user=user,
            household=household,
            role=MembershipRole.OWNER,
        )

        categories = self.create_categories()

        products = self.create_products(
            household,
            categories,
        )

        self.create_pantry_history(
            household,
            user,
            products,
        )

        self.stdout.write(
            self.style.SUCCESS(
                f"Demo household '{name}' created successfully!"
            )
        )

        self.stdout.write(f"Household ID: {household.id}")
        self.stdout.write(f"Owner: {user.username}")
        self.stdout.write(
            f"Products created: {len(products)}"
        )
        self.stdout.write(
            f"Historical items: {self.HISTORY_ITEMS}"
        )
        self.stdout.write(
            f"Active items: {self.ACTIVE_ITEMS}"
        )

    @staticmethod
    def generate_invite_code():
        while True:
            code = "".join(
                str(secrets.randbelow(10))
                for _ in range(6)
            )

            if not Household.objects.filter(
                invite_code=code
            ).exists():
                return code

    def create_categories(self):
        categories = {
            category.name.lower(): category
            for category in Category.objects.all()
        }

        if not categories:
            raise CommandError(
                "No categories found in database. "
                "Create categories before running the seed command."
            )

        return list(categories.values())

    def create_products(self, household, categories):
        products = []

        for name, brand in self.PRODUCT_DATA:
            product = Product.objects.create(
                household=household,
                name=name,
                brand=brand,
                product_type=ProductType.CUSTOM,
                category=random.choice(categories),
            )

            products.append(product)

        return products

    def create_pantry_history(
        self,
        household,
        user,
        products,
    ):
        today = timezone.localdate()
        now = timezone.now()

        history = []

        for i in range(self.HISTORY_ITEMS):
            # Spread records over the last 365 days.
            days_ago = random.randint(
                0,
                self.HISTORY_DAYS - 1,
            )

            added_date = today - timedelta(days=days_ago)

            # Around 35% wasted and 65% eaten.
            item_status = (
                ItemStatus.WASTED
                if random.random() < 0.35
                else ItemStatus.EATEN
            )

            # Generate expiry dates relative to added date.
            expiry_offset = random.randint(-5, 14)

            expiry_date = (
                added_date + timedelta(days=expiry_offset)
            )

            # Closing date should always be after added date.
            days_until_closed = random.randint(0, 5)

            closed_date = min(
                added_date + timedelta(days=days_until_closed),
                today,
            )

            # Make some wasted items expired and some not expired.
            if item_status == ItemStatus.WASTED:
                if random.random() < 0.7:
                    expiry_date = closed_date - timedelta(
                        days=random.randint(1, 7)
                    )
                else:
                    expiry_date = closed_date + timedelta(
                        days=random.randint(0, 5)
                    )

            closed_at = timezone.make_aware(
                timezone.datetime.combine(
                    closed_date,
                    timezone.datetime.min.time(),
                )
            ) + timedelta(
                hours=random.randint(8, 21),
                minutes=random.randint(0, 59),
            )

            # Do not generate future closing timestamps.
            closed_at = min(closed_at, now)

            history.append(
                PantryItem(
                    household=household,
                    product=random.choice(products),
                    added_by=user,
                    expiry_date=expiry_date,
                    status=item_status,
                    created_at=timezone.make_aware(
                        timezone.datetime.combine(
                            added_date,
                            timezone.datetime.min.time(),
                        )
                    ),
                    closed_at=closed_at,
                )
            )

        PantryItem.objects.bulk_create(history)

        # Current active pantry products.
        active_items = []

        for _ in range(self.ACTIVE_ITEMS):
            added_days_ago = random.randint(0, 20)

            active_items.append(
                PantryItem(
                    household=household,
                    product=random.choice(products),
                    added_by=user,
                    expiry_date=today + timedelta(
                        days=random.randint(-3, 14)
                    ),
                    status=ItemStatus.ACTIVE,
                    created_at=now - timedelta(
                        days=added_days_ago
                    ),
                )
            )

        PantryItem.objects.bulk_create(active_items)
