from datetime import timedelta
from decimal import Decimal
import secrets
import random

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
            raise CommandError(f"User '{username}' does not exist.")

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

        return categories

    def create_products(self, household, categories):
        product_data = [
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
        ]

        available_categories = list(categories.values())

        if not available_categories:
            raise CommandError("No categories available in database.")

        products = []

        for name, brand in product_data:
            product = Product.objects.create(
                household=household,
                name=name,
                brand=brand,
                product_type=ProductType.CUSTOM,
                category=random.choice(available_categories),
            )

            products.append(product)

        return products

    def create_pantry_history(self, household, user, products):
        today = timezone.localdate()

        # Each tuple: product index, days ago, status, expiry offset
        history = [
            (0, 30, ItemStatus.WASTED, -5),
            (1, 28, ItemStatus.EATEN, 3),
            (2, 25, ItemStatus.WASTED, -2),
            (3, 23, ItemStatus.EATEN, 5),
            (4, 20, ItemStatus.EATEN, 4),
            (5, 18, ItemStatus.WASTED, -1),
            (6, 15, ItemStatus.EATEN, 3),
            (7, 12, ItemStatus.WASTED, -3),
            (8, 10, ItemStatus.EATEN, 5),
            (9, 8, ItemStatus.WASTED, 0),
            (10, 7, ItemStatus.EATEN, 4),
            (11, 6, ItemStatus.EATEN, 2),
            (12, 5, ItemStatus.WASTED, -1),
            (13, 4, ItemStatus.EATEN, 5),
            (14, 3, ItemStatus.WASTED, -2),
            (15, 2, ItemStatus.EATEN, 3),
        ]

        for index, days_ago, item_status, expiry_offset in history:
            added_date = today - timedelta(days=days_ago)

            item = PantryItem.objects.create(
                household=household,
                product=products[index],
                added_by=user,
                expiry_date=added_date + timedelta(
                    days=expiry_offset
                ),
                status=item_status,
                created_at=added_date,
            )

            if item_status != ItemStatus.ACTIVE:
                item.closed_at = timezone.now() - timedelta(
                    days=days_ago - 1
                )
                item.save(update_fields=["closed_at"])

        # Current active pantry products
        for index, product in enumerate(products[:8]):
            PantryItem.objects.create(
                household=household,
                product=product,
                added_by=user,
                expiry_date=today + timedelta(days=index - 2),
                status=ItemStatus.ACTIVE,
            )
