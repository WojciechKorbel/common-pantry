from django.test import TestCase

from api.services.open_food_facts import match_category


class CategoryMatchingTests(TestCase):
    """Categories come from the seed migration; tags are real Open Food Facts tags."""

    def test_butter_goes_to_dairy_not_fats(self):
        tags = ['en:dairies', 'en:fats', 'en:spreads', 'en:animal-fats', 'en:butters']
        self.assertEqual(match_category(tags).name, 'Dairy')

    def test_frozen_pizza_goes_to_frozen_food(self):
        tags = ['en:meals', 'en:frozen-foods', 'en:pizzas-pies-and-quiches', 'en:pizzas', 'en:frozen-pizzas']
        self.assertEqual(match_category(tags).name, 'Frozen food')

    def test_unknown_tags_give_no_category(self):
        self.assertIsNone(match_category(['en:flours']))
        self.assertIsNone(match_category([]))
