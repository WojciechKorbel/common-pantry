"""Helpers that create test data with sensible defaults.

Tests pass only what matters for them, e.g. make_product('Nutella'),
and everything else gets a default value.
"""
from datetime import date
from itertools import count

from django.contrib.auth.models import User

from api.models import Category, Household, Membership, PantryItem, Product, ProductType

_numbers = count(1)


def make_user(username=None):
    return User.objects.create_user(username or f'user{next(_numbers)}', password='pass12345')


def make_household(*members, name='Home'):
    household = Household.objects.create(name=name, invite_code=f'CODE{next(_numbers)}')
    for user in members:
        Membership.objects.create(user=user, household=household)
    return household


def make_product(name, *, barcode=None, category=None, household=None):
    """A global product (from Open Food Facts) or, with household=..., a custom one."""
    return Product.objects.create(
        name=name,
        barcode=barcode,
        category=Category.objects.get(name=category) if category else None,
        product_type=ProductType.CUSTOM if household else ProductType.GLOBAL,
        household=household,
    )


def add_items(household, product, *expiry_dates, status='active', added_by=None):
    """Put one package of `product` into the pantry for every expiry date given ('YYYY-MM-DD')."""
    return [
        PantryItem.objects.create(
            household=household,
            product=product,
            expiry_date=date.fromisoformat(day),
            status=status,
            added_by=added_by,
        )
        for day in expiry_dates
    ]
