from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import Household, Membership, MembershipRole, PantryItem, ShoppingItem
from api.tests.factories import make_household, make_product, make_user


class HouseholdAPITests(APITestCase):
    def setUp(self):
        # Create test users
        self.owner = make_user("owner_user")
        self.member = make_user("member_user")
        self.outsider = make_user("outsider_user")

        # Create household using factory
        self.household = make_household(self.owner, name="Main Family House")

        # Set owner role explicitly
        owner_membership = Membership.objects.get(user=self.owner, household=self.household)
        owner_membership.role = MembershipRole.OWNER
        owner_membership.save(update_fields=["role"])

        # Add regular member
        self.member_membership = Membership.objects.create(
            user=self.member,
            household=self.household,
            role=MembershipRole.MEMBER,
        )

        # Authenticate as owner by default
        self.client.force_authenticate(user=self.owner)

    def test_create_household_assigns_owner_and_code(self):
        """Creating a new household assigns unique invite code and owner role to creator."""
        url = reverse("household_list_create")
        payload = {"name": "Summer Cabin"}

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        household_id = response.data["id"]
        created_household = Household.objects.get(id=household_id)
        self.assertTrue(bool(created_household.invite_code))

        # Check membership
        membership = Membership.objects.get(household=created_household, user=self.owner)
        self.assertEqual(membership.role, MembershipRole.OWNER)

    def test_join_household_with_valid_code(self):
        """User can join a household with a valid invite code."""
        self.client.force_authenticate(user=self.outsider)
        url = reverse("household_join")
        payload = {"invite_code": self.household.invite_code}

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data.get("success"))

        membership = Membership.objects.filter(household=self.household, user=self.outsider).first()
        self.assertIsNotNone(membership)
        self.assertEqual(membership.role, MembershipRole.MEMBER)

    def test_join_household_empty_code_returns_400(self):
        """Joining without invite_code returns 400 Bad Request."""
        url = reverse("household_join")
        response = self.client.post(url, {"invite_code": "   "}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.data.get("success"))

    def test_join_household_invalid_code_returns_404(self):
        """Joining with non-existent invite_code returns 404 Not Found."""
        url = reverse("household_join")
        response = self.client.post(url, {"invite_code": "999999"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(response.data.get("success"))

    def test_join_household_already_member_returns_conflict(self):
        """Attempting to join an already joined household returns 409 Conflict."""
        self.client.force_authenticate(user=self.member)
        url = reverse("household_join")
        payload = {"invite_code": self.household.invite_code}

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertFalse(response.data.get("success"))

    def test_get_household_details(self):
        """Retrieve details and verify members list with 'is_me' flag."""
        url = reverse("household-details", args=[self.household.id])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], self.household.name)
        self.assertEqual(len(response.data["members"]), 2)

        owner_entry = next(m for m in response.data["members"] if m["user_id"] == self.owner.id)
        member_entry = next(m for m in response.data["members"] if m["user_id"] == self.member.id)
        self.assertTrue(owner_entry["is_me"])
        self.assertFalse(member_entry["is_me"])

    def test_update_household_settings(self):
        """Owner can update household name, but cannot supply empty name."""
        url = reverse("household-settings", args=[self.household.id])

        # Valid name
        resp = self.client.patch(url, {"name": "New Family Name"}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.household.refresh_from_db()
        self.assertEqual(self.household.name, "New Family Name")

        # Invalid empty name
        resp_bad = self.client.patch(url, {"name": "   "}, format="json")
        self.assertEqual(resp_bad.status_code, status.HTTP_400_BAD_REQUEST)

    def test_member_cannot_update_settings(self):
        """Non-owner member receives 403 Forbidden when trying to update settings."""
        self.client.force_authenticate(user=self.member)
        url = reverse("household-settings", args=[self.household.id])
        resp = self.client.patch(url, {"name": "Hacked Name"}, format="json")
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_promote_member_to_owner(self):
        """Owner can promote a member to owner."""
        url = reverse("household-member-promote", args=[self.household.id, self.member.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.member_membership.refresh_from_db()
        self.assertEqual(self.member_membership.role, MembershipRole.OWNER)

        # Re-promoting already owner returns 400
        response_again = self.client.post(url)
        self.assertEqual(response_again.status_code, status.HTTP_400_BAD_REQUEST)

    def test_member_cannot_promote_another_member(self):
        """Non-owner member receives 403 Forbidden when trying to promote."""
        self.client.force_authenticate(user=self.member)
        url = reverse("household-member-promote", args=[self.household.id, self.member.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_demote_owner_to_member(self):
        """Demote another owner down to member."""
        # Make member an owner first
        self.member_membership.role = MembershipRole.OWNER
        self.member_membership.save(update_fields=["role"])

        url = reverse("household-member-demote", args=[self.household.id, self.member.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.member_membership.refresh_from_db()
        self.assertEqual(self.member_membership.role, MembershipRole.MEMBER)

        # Demoting non-owner returns 400
        resp_again = self.client.post(url)
        self.assertEqual(resp_again.status_code, status.HTTP_400_BAD_REQUEST)

    def test_owner_cannot_demote_themselves(self):
        """Owner cannot demote themselves."""
        url = reverse("household-member-demote", args=[self.household.id, self.owner.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("cannot demote yourself", response.data.get("detail", "").lower())

    def test_member_cannot_demote_anyone(self):
        """Non-owner cannot demote members."""
        self.client.force_authenticate(user=self.member)
        url = reverse("household-member-demote", args=[self.household.id, self.owner.id])
        self.assertEqual(self.client.post(url).status_code, status.HTTP_403_FORBIDDEN)

    def test_owner_can_delete_member(self):
        """Owner can remove a regular member from the household."""
        url = reverse("household-member-delete", args=[self.household.id, self.member.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(
            Membership.objects.filter(household=self.household, user=self.member).exists()
        )

    def test_owner_cannot_delete_last_owner(self):
        """Cannot delete an owner if no other owners remain in the household."""
        url = reverse("household-member-delete", args=[self.household.id, self.owner.id])
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("last owner cannot be removed", response.data.get("detail", "").lower())

    def test_member_cannot_delete_anyone(self):
        """Non-owner receives 403 Forbidden when deleting a member."""
        self.client.force_authenticate(user=self.member)
        url = reverse("household-member-delete", args=[self.household.id, self.member.id])
        self.assertEqual(self.client.delete(url).status_code, status.HTTP_403_FORBIDDEN)

    def test_last_owner_cannot_leave_while_members_exist(self):
        """Last owner cannot leave if other members are still in the household."""
        url = reverse("household-leave", args=[self.household.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("promote another member first", response.data.get("detail", "").lower())

    def test_sole_member_leaving_deletes_household_and_related_items(self):
        """When the sole member leaves, the household, pantry, and shopping items are deleted."""
        self.member_membership.delete()

        product = make_product("Test Flour", household=self.household)
        PantryItem.objects.create(
            household=self.household,
            product=product,
            expiry_date="2026-12-01",
            added_by=self.owner,
        )
        ShoppingItem.objects.create(
            household=self.household,
            name="Test Yeast",
            added_by=self.owner,
        )

        url = reverse("household-leave", args=[self.household.id])
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data.get("household_deleted"))

        self.assertFalse(Household.objects.filter(id=self.household.id).exists())
        self.assertFalse(PantryItem.objects.filter(household_id=self.household.id).exists())
        self.assertFalse(ShoppingItem.objects.filter(household_id=self.household.id).exists())