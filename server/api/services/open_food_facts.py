import requests
from django.conf import settings

from ..models import Category

PRODUCT_URL = 'https://world.openfoodfacts.org/api/v2/product/{barcode}.json'

FIELDS = ','.join([
    'product_name',
    'product_name_pl',
    'brands',
    'quantity',
    'image_front_small_url',
    'image_front_url',
    'categories_tags',
])


class OpenFoodFactsError(Exception):
    """OpenFoodFacts could not be reached or answered with an error."""


def fetch_product(barcode):
    """Return product data for a barcode, or None when Open Food Facts doesn't know it."""
    try:
        response = requests.get(
            PRODUCT_URL.format(barcode=barcode),
            params={'fields': FIELDS},
            headers={'User-Agent': settings.OPEN_FOOD_FACTS_USER_AGENT},
            timeout=5,
        )
    except requests.RequestException as exc:
        raise OpenFoodFactsError(str(exc)) from exc

    if response.status_code == 404:
        return None
    if response.status_code != 200:
        raise OpenFoodFactsError(f'Unexpected status {response.status_code}')

    data = response.json()
    product = data.get('product') or {}
    name = (product.get('product_name_pl') or product.get('product_name') or '').strip()
    if data.get('status') != 1 or not name:
        return None

    brands = [b.strip() for b in (product.get('brands') or '').split(',') if b.strip()]
    return {
        'name': name,
        'brand': ', '.join(brands)[:255] or None,
        'package_size': (product.get('quantity') or '').strip()[:50],
        'image_url': product.get('image_front_small_url') or product.get('image_front_url'),
        'categories_tags': product.get('categories_tags') or [],
    }


def match_category(tags):
    """Matches OpenFoodFacts categories with defined ones"""
    if not tags:
        return None
    return Category.objects.filter(off_tag__in=tags).order_by('match_priority').first()