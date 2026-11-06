from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Category, MembershipRole
from api.services.open_food_facts import match_category
from api.tests.factories import make_household, make_user


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


class CategoryAPITests(APITestCase):
    def setUp(self):
        self.user = make_user("cat_api_user")
        self.url = reverse("category-list")

    def test_unauthenticated_request_rejected(self):
        """Unauthenticated requests must return 401 Unauthorized."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_receives_category_list(self):
        """Authenticated users receive the list of seeded categories."""
        self.client.force_authenticate(user=self.user)
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) > 0)
        names = [item["name"] for item in response.data]
        self.assertIn("Dairy", names)


class HouseholdSettingsAPITests(APITestCase):
    def setUp(self):
        self.owner = make_user("settings_owner")
        self.member = make_user("settings_member")

        self.household = make_household(self.owner, name="Original Name")

        # Explicitly set owner role for the creator
        from api.models import Membership
        owner_membership = Membership.objects.get(user=self.owner, household=self.household)
        owner_membership.role = MembershipRole.OWNER
        owner_membership.save(update_fields=["role"])

        # Add regular member
        Membership.objects.create(
            user=self.member,
            household=self.household,
            role=MembershipRole.MEMBER,
        )

        self.url = reverse("household-settings", args=[self.household.id])

    def test_owner_can_update_household_name(self):
        """Owner can update the household name."""
        self.client.force_authenticate(user=self.owner)
        payload = {"name": "Renamed Family House"}
        response = self.client.patch(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Renamed Family House")

        self.household.refresh_from_db()
        self.assertEqual(self.household.name, "Renamed Family House")

    def test_member_cannot_update_household_name(self):
        """Regular member receives 403 Forbidden when trying to update settings."""
        self.client.force_authenticate(user=self.member)
        payload = {"name": "Unauthorized Change"}
        response = self.client.patch(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.household.refresh_from_db()
        self.assertEqual(self.household.name, "Original Name")

    def test_blank_name_returns_bad_request(self):
        """Empty or whitespace-only name returns 400 Bad Request."""
        self.client.force_authenticate(user=self.owner)
        payload = {"name": "   "}
        response = self.client.patch(self.url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("name", response.data)
        self.household.refresh_from_db()
        self.assertEqual(self.household.name, "Original Name")