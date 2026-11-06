from datetime import timedelta
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, ItemStatus, PantryItem, ProductOrigin, ProductType
from api.tests.factories import make_household, make_product, make_user


class PantryExtendedAPITests(APITestCase):
    def setUp(self):
        # Create test users
        self.user = make_user("pantry_master")
        self.other_user = make_user("other_pantry_user")

        # Create households
        self.household = make_household(self.user, name="Main Pantry Home")
        self.other_household = make_household(self.other_user, name="Foreign Home")

        # Categories
        self.category, _ = Category.objects.get_or_create(name="Beverages")

        # Products
        self.product = make_product(
            "Orange Juice",
            household=self.household,
            category="Beverages",
            origin=ProductOrigin.PURCHASED,
        )
        self.other_household_product = make_product(
            "Foreign Cider",
            household=self.other_household,
            origin=ProductOrigin.PURCHASED,
        )

        self.client.force_authenticate(user=self.user)

    def test_bulk_create_pantry_items_with_count(self):
        """Verify creating multiple pantry item packages in a single request."""
        url = reverse("pantry-item-create", args=[self.household.id])
        expiry = timezone.localdate() + timedelta(days=10)
        payload = {
            "product": self.product.id,
            "expiry_date": expiry.isoformat(),
            "count": 4,
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data), 4)

        created_items = PantryItem.objects.filter(
            household=self.household, product=self.product, status=ItemStatus.ACTIVE
        )
        self.assertEqual(created_items.count(), 4)

    def test_create_pantry_item_updates_product_origin_when_provided(self):
        """Supplying 'origin' in PantryItemCreateSerializer updates the underlying product origin."""
        url = reverse("pantry-item-create", args=[self.household.id])
        expiry = timezone.localdate() + timedelta(days=5)
        payload = {
            "product": self.product.id,
            "expiry_date": expiry.isoformat(),
            "count": 1,
            "origin": ProductOrigin.HOMEMADE,
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.product.refresh_from_db()
        self.assertEqual(self.product.origin, ProductOrigin.HOMEMADE)

    def test_cannot_add_item_with_foreign_custom_product(self):
        """Adding a custom product belonging to another household must fail validation."""
        url = reverse("pantry-item-create", args=[self.household.id])
        expiry = timezone.localdate() + timedelta(days=5)
        payload = {
            "product": self.other_household_product.id,
            "expiry_date": expiry.isoformat(),
            "count": 1,
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("product", response.data)

    def test_pantry_list_grouping_and_expiry_status(self):
        """PantryListView groups packages by product and calculates earliest_expiry and status."""
        today = timezone.localdate()

        # Add 2 items: 1 expiring soon (+1 day), 1 fresh (+7 days)
        PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=today + timedelta(days=1),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=today + timedelta(days=7),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("pantry", args=[self.household.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        group = response.data[0]
        self.assertEqual(group["id"], self.product.id)
        self.assertEqual(group["item_count"], 2)
        self.assertEqual(group["earliest_expiry"], (today + timedelta(days=1)).isoformat())
        self.assertEqual(group["expiry_status"], "soon")

    def test_pantry_list_filter_by_search(self):
        """Filter pantry list by search query parameter."""
        today = timezone.localdate()
        PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=today + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("pantry", args=[self.household.id])

        # Matching search
        resp_match = self.client.get(f"{url}?search=Orange")
        self.assertEqual(resp_match.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_match.data), 1)

        # Non-matching search
        resp_none = self.client.get(f"{url}?search=NonExistentProduct")
        self.assertEqual(resp_none.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_none.data), 0)

    def test_delete_individual_pantry_item(self):
        """Delete an individual package from the pantry."""
        item = PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=timezone.localdate() + timedelta(days=3),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("pantry-item-detail", args=[self.household.id, item.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(PantryItem.objects.filter(id=item.id).exists())