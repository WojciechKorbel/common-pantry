from datetime import timedelta
from decimal import Decimal
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, ItemStatus, PantryItem, Product, ProductOrigin, ProductType, ShoppingItem
from api.serializers import calculate_expiry_status, ShoppingMoveToPantrySerializer
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

    def test_calculate_expiry_status_helper_edge_cases(self):
        """calculate_expiry_status handles None properly."""
        self.assertIsNone(calculate_expiry_status(None))

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

    def test_pantry_list_filter_category_and_soon_status(self):
        """Test filtering pantry list by category id and 'soon' expiry status."""
        today = timezone.localdate()
        PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=today + timedelta(days=1),  # Status soon
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )

        url = reverse("pantry", args=[self.household.id])

        # Filter category
        resp_cat = self.client.get(f"{url}?category={self.category.id}")
        self.assertEqual(resp_cat.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_cat.data), 1)

        # Filter soon
        resp_soon = self.client.get(f"{url}?expiry_status=soon")
        self.assertEqual(resp_soon.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_soon.data), 1)

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

    def test_close_pantry_item_already_closed_fails(self):
        """Attempting to close an already eaten/wasted item returns 400."""
        item = PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=timezone.localdate() + timedelta(days=5),
            status=ItemStatus.EATEN,
            added_by=self.user,
        )
        url = reverse("pantry-item-close", args=[self.household.id, item.id])
        resp = self.client.post(url, {"status": ItemStatus.WASTED}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already closed", resp.data.get("detail", "").lower())

    def test_close_pantry_item_increments_existing_shopping_item_quantity(self):
        """When an unbought item already exists on shopping list, quantity is incremented."""
        ShoppingItem.objects.create(
            household=self.household,
            product=self.product,
            name=self.product.name,
            quantity=Decimal("1.00"),
            is_bought=False,
            added_by=self.user,
        )
        item = PantryItem.objects.create(
            household=self.household,
            product=self.product,
            expiry_date=timezone.localdate() + timedelta(days=5),
            status=ItemStatus.ACTIVE,
            added_by=self.user,
        )
        url = reverse("pantry-item-close", args=[self.household.id, item.id])
        resp = self.client.post(url, {"status": ItemStatus.EATEN, "add_to_shopping_list": True}, format="json")

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        shop_item = ShoppingItem.objects.get(household=self.household, product=self.product, is_bought=False)
        self.assertEqual(shop_item.quantity, Decimal("2.00"))

    def test_move_to_pantry_adhoc_item_creates_product(self):
        """Moving an unlinked shopping item creates a new custom product with brand."""
        adhoc_item = ShoppingItem.objects.create(
            household=self.household,
            name="Organic Oatmeal",
            quantity=Decimal("1.00"),
            unit="pack",
            is_bought=True,
            added_by=self.user,
        )
        url = reverse("shopping-move-to-pantry", args=[self.household.id])
        payload = {
            "items": [
                {
                    "id": adhoc_item.id,
                    "expiry_dates": ["2026-11-20"],
                    "brand": "BioFarm",
                }
            ]
        }
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        created_product = Product.objects.filter(
            household=self.household, name="Organic Oatmeal", brand="BioFarm"
        ).first()
        self.assertIsNotNone(created_product)
        self.assertEqual(created_product.product_type, ProductType.CUSTOM)

    def test_shopping_move_duplicate_ids_validation(self):
        """Serializer validates duplicate item ids."""
        serializer = ShoppingMoveToPantrySerializer(
            data={"items": [{"id": 1, "expiry_dates": ["2026-12-01"]}, {"id": 1, "expiry_dates": ["2026-12-02"]}]}
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn("items", serializer.errors)

    def test_household_mixin_rejects_non_member_access(self):
        """User cannot access pantry of a household they do not belong to."""
        url_pantry = reverse("pantry", args=[self.other_household.id])
        self.assertEqual(self.client.get(url_pantry).status_code, status.HTTP_404_NOT_FOUND)