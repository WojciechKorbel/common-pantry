"""Tests that talk to the real Open Food Facts API.

They are skipped by default, because they need internet access and depend on data
that other people can edit. Run them on purpose (PowerShell):

    $env:RUN_LIVE_TESTS = "1"
    python manage.py test api.tests.test_open_food_facts_live
    Remove-Item Env:RUN_LIVE_TESTS
"""
import os
import unittest

from django.test import TestCase, tag
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Product
from api.services.open_food_facts import fetch_product, match_category
from api.tests.factories import make_household, make_user

NUTELLA_BARCODE = '3017620422003'  # Nutella, the product Open Food Facts uses in its own docs
UNKNOWN_BARCODE = '2999999999995'  # numbers starting with 2 are reserved for in-store use

live = unittest.skipUnless(os.environ.get('RUN_LIVE_TESTS'), 'set RUN_LIVE_TESTS=1 to run')


@tag('live')
@live
class OpenFoodFactsServiceLiveTests(TestCase):
    def test_fetches_and_parses_a_known_product(self):
        data = fetch_product(NUTELLA_BARCODE)

        self.assertIsNotNone(data)
        self.assertIn('nutella', data['name'].lower())
        self.assertIn('ferrero', (data['brand'] or '').lower())
        self.assertTrue(data['package_size'])
        self.assertTrue(data['image_url'].startswith('https://'))
        self.assertIn('en:sweet-spreads', data['categories_tags'])
        self.assertEqual(match_category(data['categories_tags']).name, 'Sweet spreads & honey')

    def test_unknown_barcode_returns_none(self):
        self.assertIsNone(fetch_product(UNKNOWN_BARCODE))


@tag('live')
@live
class BarcodeEndpointLiveTests(APITestCase):
    """The whole path: app request -> our API -> Open Food Facts -> our database."""

    @classmethod
    def setUpTestData(cls):
        cls.alice = make_user('alice')
        cls.home = make_household(cls.alice)

    def setUp(self):
        self.client.force_authenticate(self.alice)

    def test_scanned_product_is_saved_with_category(self):
        url = reverse('product-by-barcode', args=[self.home.id, NUTELLA_BARCODE])

        first = self.client.get(url)
        second = self.client.get(url)

        self.assertEqual(first.status_code, status.HTTP_200_OK)
        self.assertEqual(first.data['barcode'], NUTELLA_BARCODE)
        self.assertEqual(first.data['product_type'], 'global')
        self.assertEqual(first.data['category']['name'], 'Sweet spreads & honey')
        self.assertEqual(second.data['id'], first.data['id'])
        self.assertEqual(Product.objects.filter(barcode=NUTELLA_BARCODE).count(), 1)