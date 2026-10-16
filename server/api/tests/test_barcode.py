from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.services.open_food_facts import OpenFoodFactsError
from api.tests.factories import make_household, make_user

NUTELLA = {
    'name': 'Nutella',
    'brand': 'Ferrero',
    'package_size': '1 kg',
    'image_url': 'https://example.com/n.jpg',
    'categories_tags': ['en:breakfasts', 'en:spreads', 'en:sweet-spreads', 'en:hazelnut-spreads'],
}


@patch('api.views.open_food_facts.fetch_product')
class ProductByBarcodeTests(APITestCase):
    """Open Food Facts is replaced by a mock in every test (the `fetch` argument)."""

    @classmethod
    def setUpTestData(cls):
        cls.alice = make_user('alice')
        cls.home = make_household(cls.alice)

    def setUp(self):
        self.client.force_authenticate(self.alice)

    def lookup(self, barcode):
        return self.client.get(reverse('product-by-barcode', args=[self.home.id, barcode]))

    def test_unknown_barcode_is_fetched_once_and_saved(self, fetch):
        fetch.return_value = dict(NUTELLA)

        first = self.lookup('3017620422003')
        second = self.lookup('3017620422003')

        self.assertEqual(first.status_code, status.HTTP_200_OK)
        self.assertEqual(first.data['name'], 'Nutella')
        self.assertEqual(first.data['category']['name'], 'Sweet spreads & honey')
        self.assertEqual(second.data['id'], first.data['id'])
        fetch.assert_called_once()

    def test_custom_product_with_barcode_is_found_without_open_food_facts(self, fetch):
        self.client.post(
            reverse('custom-product-create', args=[self.home.id]),
            {'name': 'Local honey', 'barcode': '5901234123457'},
            format='json',
        )

        response = self.lookup('5901234123457')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Local honey')
        fetch.assert_not_called()

    def test_barcode_unknown_to_open_food_facts(self, fetch):
        fetch.return_value = None
        self.assertEqual(self.lookup('5901234123457').status_code, status.HTTP_404_NOT_FOUND)

    def test_open_food_facts_unavailable(self, fetch):
        fetch.side_effect = OpenFoodFactsError('timeout')
        self.assertEqual(self.lookup('5901234123457').status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_invalid_barcode(self, fetch):
        self.assertEqual(self.lookup('abc').status_code, status.HTTP_400_BAD_REQUEST)
        fetch.assert_not_called()
