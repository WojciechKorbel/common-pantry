from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import PantryItem
from api.tests.factories import add_items, make_household, make_product, make_user


class PantryListTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.alice = make_user('alice')
        cls.home = make_household(cls.alice)
        cls.other_home = make_household(make_user('bob'))

        cls.cheese = make_product('Serek wiejski', category='Dairy')
        cls.nutella = make_product('Nutella')

        add_items(cls.home, cls.cheese, '2026-10-20', '2026-10-06', '2026-10-15', added_by=cls.alice)
        add_items(cls.home, cls.nutella, '2027-05-26')
        add_items(cls.home, cls.nutella, '2026-01-01', status='eaten')
        add_items(cls.other_home, cls.cheese, '2026-01-01')

    def setUp(self):
        self.client.force_authenticate(self.alice)

    def get_pantry(self, household):
        return self.client.get(reverse('pantry', args=[household.id]))

    def test_groups_items_by_product_soonest_first(self):
        response = self.get_pantry(self.home)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual([group['name'] for group in response.data], ['Serek wiejski', 'Nutella'])
        cheese = response.data[0]
        self.assertEqual(cheese['item_count'], 3)
        self.assertEqual(cheese['earliest_expiry'], '2026-10-06')
        self.assertEqual(
            [item['expiry_date'] for item in cheese['items']], ['2026-10-06', '2026-10-15', '2026-10-20']
        )
        self.assertEqual(cheese['items'][0]['added_by']['username'], 'alice')
        self.assertEqual(cheese['category']['name'], 'Dairy')

    def test_eaten_items_are_not_counted(self):
        nutella = self.get_pantry(self.home).data[1]
        self.assertEqual(nutella['item_count'], 1)

    def test_other_household_is_not_found(self):
        self.assertEqual(self.get_pantry(self.other_home).status_code, status.HTTP_404_NOT_FOUND)

    def test_requires_login(self):
        self.client.force_authenticate(None)
        self.assertEqual(self.get_pantry(self.home).status_code, status.HTTP_401_UNAUTHORIZED)


class AddPantryItemsTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.alice = make_user('alice')
        cls.home = make_household(cls.alice)
        cls.nutella = make_product('Nutella')
        cls.bobs_soup = make_product('Grandma soup', household=make_household(make_user('bob')))

    def setUp(self):
        self.client.force_authenticate(self.alice)

    def add(self, product, **data):
        return self.client.post(
            reverse('pantry-item-create', args=[self.home.id]),
            {'product': product.id, 'expiry_date': '2027-01-10', **data},
            format='json',
        )

    def test_add_several_packages_at_once(self):
        response = self.add(self.nutella, count=2)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data), 2)
        self.assertEqual(response.data[0]['added_by']['username'], 'alice')
        self.assertEqual(PantryItem.objects.filter(household=self.home, product=self.nutella).count(), 2)

    def test_cannot_use_custom_product_of_another_household(self):
        self.assertEqual(self.add(self.bobs_soup).status_code, status.HTTP_400_BAD_REQUEST)


class CustomProductTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.alice = make_user('alice')
        cls.home = make_household(cls.alice)

    def setUp(self):
        self.client.force_authenticate(self.alice)

    def test_product_with_same_name_is_reused(self):
        url = reverse('custom-product-create', args=[self.home.id])
        first = self.client.post(url, {'name': 'Pierogi'}, format='json')
        second = self.client.post(url, {'name': 'pierogi'}, format='json')

        self.assertEqual(first.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(first.data['id'], second.data['id'])
