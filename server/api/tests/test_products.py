from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import ItemStatus, PantryItem, Product, ProductOrigin, ProductType
from api.tests.factories import make_household, make_product, make_user


class ProductAPITests(APITestCase):

  def setUp(self):
    self.user = make_user("testuser")
    self.other_user = make_user("otheruser")

    # Creates households with unique invite_code auto-incremented by factories.py
    self.household = make_household(self.user, name="Primary Household")
    self.other_household = make_household(
        self.other_user, name="Secondary Household"
    )

    self.client.force_authenticate(user=self.user)

  def test_create_custom_product_default_origin_is_purchased(self):
    """Ensure omitting origin defaults to 'purchased'."""
    url = reverse("custom-product-create", args=[self.household.id])
    payload = {
        "name": "Milk 3.2%",
        "package_size": "1L",
    }
    response = self.client.post(url, payload, format="json")

    self.assertIn(
        response.status_code, [status.HTTP_201_CREATED, status.HTTP_200_OK]
    )
    product = Product.objects.get(
        name="Milk 3.2%", household=self.household, product_type=ProductType.CUSTOM
    )
    self.assertEqual(product.origin, ProductOrigin.PURCHASED)

  def test_create_custom_product_with_homemade_origin(self):
    """Verify creating a product with origin set to 'homemade'."""
    url = reverse("custom-product-create", args=[self.household.id])
    payload = {
        "name": "Strawberry Jam",
        "origin": ProductOrigin.HOMEMADE,
        "package_size": "300g",
    }
    response = self.client.post(url, payload, format="json")

    self.assertIn(
        response.status_code, [status.HTTP_201_CREATED, status.HTTP_200_OK]
    )
    product = Product.objects.get(
        name="Strawberry Jam",
        household=self.household,
        product_type=ProductType.CUSTOM,
    )
    self.assertEqual(product.origin, ProductOrigin.HOMEMADE)
    self.assertEqual(response.data.get("origin"), ProductOrigin.HOMEMADE)

  def test_create_product_with_invalid_origin_fails(self):
    """Validation: invalid origin value returns 400 Bad Request."""
    url = reverse("custom-product-create", args=[self.household.id])
    payload = {
        "name": "Unknown Product",
        "origin": "invalid_origin_choice",
    }
    response = self.client.post(url, payload, format="json")

    self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    self.assertIn("origin", response.data)

  def test_update_product_origin_from_purchased_to_homemade(self):
    """Verify changing origin via PATCH on product detail endpoint."""
    product = make_product(
        "Sourdough Bread",
        household=self.household,
        origin=ProductOrigin.PURCHASED,
    )
    url = reverse("product-detail", args=[self.household.id, product.id])
    payload = {"origin": ProductOrigin.HOMEMADE}

    response = self.client.patch(url, payload, format="json")
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.assertEqual(response.data.get("origin"), ProductOrigin.HOMEMADE)

    product.refresh_from_db()
    self.assertEqual(product.origin, ProductOrigin.HOMEMADE)

  def test_cannot_access_or_modify_other_household_products(self):
    """Household isolation: user cannot edit products belonging to another household."""
    other_product = make_product(
        "Neighbor Jam",
        household=self.other_household,
        origin=ProductOrigin.HOMEMADE,
    )
    url = reverse(
        "product-detail", args=[self.other_household.id, other_product.id]
    )

    # User is not a member of other_household -> HouseholdMixin triggers 404
    response = self.client.patch(
        url, {"origin": ProductOrigin.PURCHASED}, format="json"
    )
    self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    other_product.refresh_from_db()
    self.assertEqual(other_product.origin, ProductOrigin.HOMEMADE)

  def test_close_homemade_pantry_item_cannot_add_to_shopping_list(self):
    """Verify that closing a homemade item with add_to_shopping_list=True fails with 400."""
    homemade_product = make_product(
        "Homemade Tomato Sauce",
        household=self.household,
        origin=ProductOrigin.HOMEMADE,
    )
    pantry_item = PantryItem.objects.create(
        household=self.household,
        product=homemade_product,
        expiry_date="2026-12-01",
        status=ItemStatus.ACTIVE,
        added_by=self.user,
    )

    url = reverse(
        "pantry-item-close", args=[self.household.id, pantry_item.id]
    )
    payload = {
        "status": ItemStatus.EATEN,
        "add_to_shopping_list": True,
    }
    response = self.client.post(url, payload, format="json")

    self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    self.assertIn(
        "Homemade products cannot be added to the shopping list.",
        response.data.get("detail", ""),
    )

  def test_close_purchased_pantry_item_adds_to_shopping_list(self):
    """Verify that closing a purchased item with add_to_shopping_list=True succeeds."""
    purchased_product = make_product(
        "Store Yogurt",
        household=self.household,
        origin=ProductOrigin.PURCHASED,
    )
    pantry_item = PantryItem.objects.create(
        household=self.household,
        product=purchased_product,
        expiry_date="2026-12-01",
        status=ItemStatus.ACTIVE,
        added_by=self.user,
    )

    url = reverse(
        "pantry-item-close", args=[self.household.id, pantry_item.id]
    )
    payload = {
        "status": ItemStatus.EATEN,
        "add_to_shopping_list": True,
    }
    response = self.client.post(url, payload, format="json")

    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.assertIsNotNone(response.data.get("shopping_item"))
    self.assertEqual(
        response.data["shopping_item"]["product"], purchased_product.id
    )

  def test_unauthenticated_requests_are_rejected(self):
    """Unauthenticated requests must be rejected with 401 Unauthorized."""
    self.client.force_authenticate(user=None)
    url = reverse("custom-product-create", args=[self.household.id])
    response = self.client.get(url)
    self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)