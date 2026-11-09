from unittest.mock import patch
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class GoogleLoginAPITests(APITestCase):
    def setUp(self):
        self.url = reverse("google-login")
        self.test_email = "test.google.user@example.com"

    def test_missing_token_returns_400(self):
        response = self.client.post(self.url, {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("id_token", response.data)

    @patch("api.views.google_id_token.verify_oauth2_token")
    def test_invalid_google_token_returns_400(self, mock_verify):
        mock_verify.side_effect = ValueError("Invalid token")
        response = self.client.post(self.url, {"id_token": "invalid_raw_token"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["detail"], "Invalid or expired Google token.")

    @patch("api.views.google_id_token.verify_oauth2_token")
    def test_token_without_email_returns_400(self, mock_verify):
        mock_verify.return_value = {"sub": "1234567890"}
        response = self.client.post(self.url, {"id_token": "valid_token_no_email"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["detail"], "No email address found in Google token.")

    @patch("api.views.google_id_token.verify_oauth2_token")
    def test_successful_login_creates_new_user(self, mock_verify):
        mock_verify.return_value = {
            "email": self.test_email,
            "given_name": "Jan",
            "family_name": "Kowalski",
        }
        response = self.client.post(self.url, {"id_token": "valid_token"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["email"], self.test_email)

        created_user = User.objects.get(email=self.test_email)
        self.assertTrue(created_user.is_active)
        self.assertEqual(created_user.first_name, "Jan")

    @patch("api.views.google_id_token.verify_oauth2_token")
    def test_successful_login_existing_user(self, mock_verify):
        existing_user = User.objects.create_user(
            username="existing_user",
            email=self.test_email,
            password="StrongPassword123!",
            is_active=False,
        )

        mock_verify.return_value = {
            "email": self.test_email,
            "given_name": "Jan",
        }
        response = self.client.post(self.url, {"id_token": "valid_token"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        existing_user.refresh_from_db()
        self.assertTrue(existing_user.is_active)