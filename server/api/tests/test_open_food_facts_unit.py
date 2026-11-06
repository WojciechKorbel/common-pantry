from unittest.mock import Mock, patch
from django.test import SimpleTestCase
import requests

from api.services.open_food_facts import (
    OpenFoodFactsError,
    fetch_product,
)


class OpenFoodFactsFetchProductTests(SimpleTestCase):
    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_success_with_pl_name_and_brands(self, mock_get):
        """Successfully parses response using Polish name and formatted brands."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 1,
            'product': {
                'product_name_pl': 'Mleko UHT',
                'product_name': 'Milk UHT',
                'brands': 'Mlekovita, Polskie Mleko',
                'quantity': '1 L',
                'image_front_small_url': 'https://example.com/small.jpg',
                'categories_tags': ['en:dairies', 'en:milks'],
            },
        }
        mock_get.return_value = mock_response

        result = fetch_product('5900000000001')

        self.assertIsNotNone(result)
        self.assertEqual(result['name'], 'Mleko UHT')
        self.assertEqual(result['brand'], 'Mlekovita, Polskie Mleko')
        self.assertEqual(result['package_size'], '1 L')
        self.assertEqual(result['image_url'], 'https://example.com/small.jpg')
        self.assertEqual(result['categories_tags'], ['en:dairies', 'en:milks'])

    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_fallback_to_english_name_and_large_image(self, mock_get):
        """Falls back to default product_name and main image url when localized ones are missing."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'status': 1,
            'product': {
                'product_name': 'Cheddar Cheese',
                'brands': '',
                'quantity': '200g',
                'image_front_url': 'https://example.com/large.jpg',
            },
        }
        mock_get.return_value = mock_response

        result = fetch_product('123456789')

        self.assertIsNotNone(result)
        self.assertEqual(result['name'], 'Cheddar Cheese')
        self.assertIsNone(result['brand'])
        self.assertEqual(result['image_url'], 'https://example.com/large.jpg')
        self.assertEqual(result['categories_tags'], [])

    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_returns_none_when_status_404(self, mock_get):
        """Returns None if Open Food Facts responds with HTTP 404."""
        mock_response = Mock()
        mock_response.status_code = 404
        mock_get.return_value = mock_response

        result = fetch_product('4040000000000')
        self.assertIsNone(result)

    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_raises_open_food_facts_error_on_network_exception(self, mock_get):
        """Raises OpenFoodFactsError on network or timeout exceptions."""
        mock_get.side_effect = requests.RequestException("Connection timed out")

        with self.assertRaises(OpenFoodFactsError) as ctx:
            fetch_product('5901234567890')
        self.assertIn("Connection timed out", str(ctx.exception))

    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_raises_open_food_facts_error_on_unexpected_http_status(self, mock_get):
        """Raises OpenFoodFactsError on unexpected HTTP statuses like 500 or 503."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_get.return_value = mock_response

        with self.assertRaises(OpenFoodFactsError) as ctx:
            fetch_product('5901234567890')
        self.assertIn("Unexpected status 500", str(ctx.exception))

    @patch('api.services.open_food_facts.requests.get')
    def test_fetch_product_returns_none_when_product_data_missing_or_name_empty(self, mock_get):
        """Returns None if status != 1 or product name is empty or whitespaces only."""
        mock_response = Mock()
        mock_response.status_code = 200

        # Case 1: status is 0 (product not found in OFF database)
        mock_response.json.return_value = {'status': 0, 'product': {}}
        mock_get.return_value = mock_response
        self.assertIsNone(fetch_product('000000'))

        # Case 2: status is 1 but name is whitespace
        mock_response.json.return_value = {
            'status': 1,
            'product': {'product_name': '   ', 'product_name_pl': ''},
        }
        self.assertIsNone(fetch_product('000001'))

        # Case 3: product field is None
        mock_response.json.return_value = {'status': 1, 'product': None}
        self.assertIsNone(fetch_product('000002'))