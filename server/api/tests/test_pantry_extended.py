from datetime import timedelta
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, ItemStatus, PantryItem, ProductOrigin, ShoppingItem
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
        self.homemade_product = make_product(
            "Homemade Jam",
            household=self.household,
            category="Beverages",
            origin=ProductOrigin.HOMEMADE,
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

    def test_pantry_list_filter_expired_and_fresh(self):
        """Test filtering pantry items by expired and fresh statuses."""
        today = timezone.localdate()

        # Expired item (-2 days)
        PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=today - timedelta(days=2),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        # Fresh item (+10 days)
        fresh_product = make_product("Fresh Milk", household=self.household)
        PantryItem.objects.create(
            household=self.household,
            product=fresh_product,
            expiry_date=today + timedelta(days=10),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("pantry", args=[self.household.id])

        # Query expired
        resp_expired = self.client.get(f"{url}?expiry_status=expired")
        self.assertEqual(resp_expired.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_expired.data), 1)
        self.assertEqual(resp_expired.data[0]["id"], self.product.id)

        # Query fresh
        resp_fresh = self.client.get(f"{url}?expiry_status=fresh")
        self.assertEqual(resp_fresh.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_fresh.data), 1)
        self.assertEqual(resp_fresh.data[0]["id"], fresh_product.id)

    def test_patch_pantry_item_details_updates_expiry_date(self):
        """PantryItemDetailView allows updating expiry_date via PATCH."""
        item = PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=timezone.localdate() + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        url = reverse("pantry-item-detail", args=[self.household.id, item.id])
        new_expiry = (timezone.localdate() + timedelta(days=20)).isoformat()
        response = self.client.patch(url, {"expiry_date": new_expiry}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        item.refresh_from_db()
        self.assertEqual(item.expiry_date.isoformat(), new_expiry)

    def test_delete_individual_pantry_item(self):
        """Delete an individual package from the pantry via pantry-item-detail."""
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

    def test_update_product_detail(self):
        """ProductDetailView allows updating custom product metadata."""
        url = reverse("product-detail", args=[self.household.id, self.product.id])
        payload = {"name": "Freshly Squeezed Orange Juice"}
        response = self.client.patch(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.product.refresh_from_db()
        self.assertEqual(self.product.name, "Freshly Squeezed Orange Juice")

    def test_close_pantry_item_as_eaten_and_add_to_shopping_list(self):
        """Closing a purchased item as eaten can automatically add it to shopping list."""
        item = PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=timezone.localdate() + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        url = reverse("pantry-item-close", args=[self.household.id, item.id])
        payload = {
            "status": ItemStatus.EATEN,
            "add_to_shopping_list": True,
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        item.refresh_from_db()
        self.assertEqual(item.status, ItemStatus.EATEN)
        self.assertIsNotNone(item.closed_at)

        # Check shopping item creation
        self.assertTrue(
            ShoppingItem.objects.filter(
                household=self.household, product=self.product
            ).exists()
        )

    def test_close_homemade_pantry_item_cannot_be_added_to_shopping_list(self):
        """Homemade products cannot be added to shopping list when closing."""
        item = PantryItem.objects.create(
            household=self.household,
            product=self.homemade_product,
            expiry_date=timezone.localdate() + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        url = reverse("pantry-item-close", args=[self.household.id, item.id])
        payload = {
            "status": ItemStatus.EATEN,
            "add_to_shopping_list": True,
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("homemade products cannot be added", response.data.get("detail", "").lower())