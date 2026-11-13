from decimal import Decimal
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, PantryItem, ProductOrigin, ShoppingItem
from api.tests.factories import make_household, make_product, make_user


class ShoppingListAPITests(APITestCase):
    def setUp(self):
        # Create users
        self.user = make_user("shopper")
        self.other_user = make_user("other_shopper")

        # Create households
        self.household = make_household(self.user, name="Shopping Household")
        self.other_household = make_household(self.other_user, name="Other Household")

        # Safely fetch or create the category to avoid unique constraint violations
        self.category, _ = Category.objects.get_or_create(name="Dairy")
        self.product = make_product(
            "Butter 82%",
            household=self.household,
            category="Dairy",
            origin=ProductOrigin.PURCHASED,
        )

        # Authenticate main user
        self.client.force_authenticate(user=self.user)

    def test_create_shopping_item_with_product(self):
        """Creating a shopping item linked to an existing product."""
        url = reverse("shopping-list", args=[self.household.id])
        payload = {
            "product": self.product.id,
            "quantity": "2.00",
            "unit": "pcs",
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["name"], self.product.name)
        self.assertEqual(response.data["category"], self.category.id)

        item = ShoppingItem.objects.get(id=response.data["id"])
        self.assertEqual(item.added_by, self.user)
        self.assertFalse(item.is_bought)

    def test_create_shopping_item_without_product(self):
        """Creating an ad-hoc shopping item without a pre-existing product."""
        url = reverse("shopping-list", args=[self.household.id])
        payload = {
            "name": "Sparkling Water",
            "quantity": "6.00",
            "unit": "bottles",
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["name"], "Sparkling Water")
        self.assertIsNone(response.data["product"])

    def test_filter_shopping_items_by_is_bought(self):
        """Filtering shopping items by ?is_bought query parameter."""
        ShoppingItem.objects.create(
            household=self.household,
            name="Unbought Apples",
            is_bought=False,
            added_by=self.user,
        )
        ShoppingItem.objects.create(
            household=self.household,
            name="Bought Bananas",
            is_bought=True,
            added_by=self.user,
        )

        url = reverse("shopping-list", args=[self.household.id])

        # Filter active (not bought)
        resp_unbought = self.client.get(f"{url}?is_bought=false")
        self.assertEqual(resp_unbought.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_unbought.data), 1)
        self.assertEqual(resp_unbought.data[0]["name"], "Unbought Apples")

        # Filter bought
        resp_bought = self.client.get(f"{url}?is_bought=true")
        self.assertEqual(resp_bought.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_bought.data), 1)
        self.assertEqual(resp_bought.data[0]["name"], "Bought Bananas")

    def test_mark_shopping_item_as_bought_sets_buyer_and_timestamp(self):
        """Updating is_bought via PATCH sets bought_by and bought_at timestamp."""
        item = ShoppingItem.objects.create(
            household=self.household,
            name="Olive Oil",
            is_bought=False,
            added_by=self.user,
        )

        url = reverse("shopping-detail", args=[self.household.id, item.id])
        response = self.client.patch(url, {"is_bought": True}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        item.refresh_from_db()
        self.assertTrue(item.is_bought)
        self.assertEqual(item.bought_by, self.user)
        self.assertIsNotNone(item.bought_at)

    def test_unmark_shopping_item_as_bought_clears_buyer_and_timestamp(self):
        """Toggling is_bought back to false clears bought_by and bought_at."""
        item = ShoppingItem.objects.create(
            household=self.household,
            name="Coffee",
            is_bought=True,
            bought_by=self.user,
            bought_at=timezone.now(),
            added_by=self.user,
        )

        url = reverse("shopping-detail", args=[self.household.id, item.id])
        response = self.client.patch(url, {"is_bought": False}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        item.refresh_from_db()
        self.assertFalse(item.is_bought)
        self.assertIsNone(item.bought_by)
        self.assertIsNone(item.bought_at)

    def test_delete_shopping_item(self):
        """Deleting an item via DELETE on shopping-detail removes it."""
        item = ShoppingItem.objects.create(
            household=self.household,
            name="Garlic",
            added_by=self.user,
        )
        url = reverse("shopping-detail", args=[self.household.id, item.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ShoppingItem.objects.filter(id=item.id).exists())

    def test_clear_bought_shopping_items(self):
        """DELETE to clear-bought endpoint removes only bought items of the household."""
        item_active = ShoppingItem.objects.create(
            household=self.household,
            name="Still Need This",
            is_bought=False,
            added_by=self.user,
        )
        item_bought = ShoppingItem.objects.create(
            household=self.household,
            name="Already Bought This",
            is_bought=True,
            added_by=self.user,
        )

        url = reverse("shopping-clear-bought", args=[self.household.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get("deleted"), 1)

        self.assertTrue(ShoppingItem.objects.filter(id=item_active.id).exists())
        self.assertFalse(ShoppingItem.objects.filter(id=item_bought.id).exists())

    def test_move_bought_items_to_pantry(self):
        """Moving bought shopping items creates pantry packages and deletes the shopping item."""
        bought_item = ShoppingItem.objects.create(
            household=self.household,
            product=self.product,
            name=self.product.name,
            quantity=Decimal("2.00"),
            unit="pcs",
            is_bought=True,
            added_by=self.user,
        )

        url = reverse("shopping-move-to-pantry", args=[self.household.id])
        payload = {
            "items": [
                {
                    "id": bought_item.id,
                    "expiry_dates": ["2026-12-01", "2026-12-15"],
                    "brand": "Mlekovita",
                }
            ]
        }
        response = self.client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data.get("moved"), 1)

        # Ensure pantry items were created
        pantry_items = PantryItem.objects.filter(
            household=self.household, product=self.product
        )
        self.assertEqual(pantry_items.count(), 2)

        # Ensure shopping item was deleted after move
        self.assertFalse(ShoppingItem.objects.filter(id=bought_item.id).exists())

    def test_move_to_pantry_missing_items_payload_returns_400(self):
        """Sending invalid or missing items array to move-to-pantry returns 400 Bad Request."""
        url = reverse("shopping-move-to-pantry", args=[self.household.id])
        response = self.client.post(url, {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        response_empty = self.client.post(url, {"items": []}, format="json")
        self.assertEqual(response_empty.status_code, status.HTTP_400_BAD_REQUEST)

    def test_move_to_pantry_unbought_item_fails(self):
        """Attempting to move an unbought item to pantry fails."""
        unbought_item = ShoppingItem.objects.create(
            household=self.household,
            product=self.product,
            name=self.product.name,
            quantity=Decimal("1.00"),
            unit="pcs",
            is_bought=False,
            added_by=self.user,
        )
        url = reverse("shopping-move-to-pantry", args=[self.household.id])
        payload = {
            "items": [
                {
                    "id": unbought_item.id,
                    "expiry_dates": ["2026-12-01"],
                }
            ]
        }
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_access_or_modify_other_household_shopping_items(self):
        """Household isolation: user cannot view or mutate shopping items of another household."""
        other_item = ShoppingItem.objects.create(
            household=self.other_household,
            name="Secret Neighbor Item",
            is_bought=False,
            added_by=self.other_user,
        )

        # Attempt to access item detail in other household
        url = reverse("shopping-detail", args=[self.other_household.id, other_item.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # Attempt to patch item
        patch_response = self.client.patch(url, {"name": "Hacked Name"}, format="json")
        self.assertEqual(patch_response.status_code, status.HTTP_404_NOT_FOUND)

        other_item.refresh_from_db()
        self.assertEqual(other_item.name, "Secret Neighbor Item")