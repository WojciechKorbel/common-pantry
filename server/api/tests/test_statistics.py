from datetime import timedelta
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, ItemStatus, PantryItem
from api.tests.factories import make_household, make_product, make_user


class FoodWasteStatisticsAPITests(APITestCase):
    def setUp(self):
        # Create users
        self.user = make_user("stats_user")
        self.other_user = make_user("other_stats_user")

        # Create households
        self.household = make_household(self.user, name="Stats Household")
        self.other_household = make_household(self.other_user, name="Other Stats Household")

        # Create categories and products
        self.dairy_category, _ = Category.objects.get_or_create(name="Dairy")
        self.bakery_category, _ = Category.objects.get_or_create(name="Bakery")

        self.milk = make_product("Milk", household=self.household, category="Dairy")
        self.bread = make_product("Bread", household=self.household, category="Bakery")

        # Authenticate
        self.client.force_authenticate(user=self.user)

    def test_food_waste_summary_calculation(self):
        """Verify calculation of eaten, wasted, and waste percentage."""
        now = timezone.now()

        # Create 3 eaten items and 1 wasted item
        for _ in range(3):
            PantryItem.objects.create(
                household=self.household,
                product=self.milk,
                expiry_date=now.date(),
                status=ItemStatus.EATEN,
                closed_at=now,
                added_by=self.user,
            )

        PantryItem.objects.create(
            household=self.household,
            product=self.bread,
            expiry_date=now.date(),
            status=ItemStatus.WASTED,
            closed_at=now,
            added_by=self.user,
        )

        # 1 active item
        PantryItem.objects.create(
            household=self.household,
            product=self.milk,
            expiry_date=now.date() + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("food-waste-statistics", args=[self.household.id])
        response = self.client.get(f"{url}?period=30d")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        summary = response.data["summary"]

        self.assertEqual(summary["eaten_count"], 3)
        self.assertEqual(summary["wasted_count"], 1)
        self.assertEqual(summary["active_count"], 1)
        # waste_percentage = (1 / 4) * 100 = 25.0
        self.assertEqual(summary["waste_percentage"], 25.0)

    def test_invalid_period_returns_bad_request(self):
        """Invalid period query parameter returns 400 Bad Request."""
        url = reverse("food-waste-statistics", args=[self.household.id])
        response = self.client.get(f"{url}?period=invalid_period")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("detail"), "Invalid period.")

    def test_statistics_categories_and_top_products(self):
        """Verify category breakdown and top wasted products listing."""
        now = timezone.now()

        # Create 2 wasted breads and 1 wasted milk
        for _ in range(2):
            PantryItem.objects.create(
                household=self.household,
                product=self.bread,
                expiry_date=now.date(),
                status=ItemStatus.WASTED,
                closed_at=now,
                added_by=self.user,
            )

        PantryItem.objects.create(
            household=self.household,
            product=self.milk,
            expiry_date=now.date(),
            status=ItemStatus.WASTED,
            closed_at=now,
            added_by=self.user,
        )

        url = reverse("food-waste-statistics", args=[self.household.id])
        response = self.client.get(f"{url}?period=30d")

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Check categories
        categories = response.data["categories"]
        bakery_entry = next((c for c in categories if c["name"] == "Bakery"), None)
        self.assertIsNotNone(bakery_entry)
        self.assertEqual(bakery_entry["wasted"], 2)

        # Check top wasted products
        top_products = response.data["top_wasted_products"]
        self.assertTrue(len(top_products) >= 2)
        self.assertEqual(top_products[0]["name"], "Bread")
        self.assertEqual(top_products[0]["count"], 2)

    def test_household_isolation_for_statistics(self):
        """User cannot access statistics of another household."""
        url = reverse("food-waste-statistics", args=[self.other_household.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)