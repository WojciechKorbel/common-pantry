from datetime import timedelta
from unittest.mock import patch

from django.conf import settings
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from api.models import EmailVerification, PasswordReset

User = get_user_model()


class EmailVerificationAPITests(APITestCase):
    def setUp(self):
        self.register_url = reverse("register")
        self.verify_url = reverse("verify-email")
        self.resend_url = reverse("resend-code")
        self.token_obtain_url = reverse("token_obtain_pair")
        self.token_refresh_url = reverse("token_refresh")
        self.email = "testuser@example.com"
        self.password = "StrongPassword123!"
        self.username = "testuser"

    @patch("api.views.send_verification_email")
    def test_registration_creates_inactive_user_and_verification_record(self, mock_send_email):
        """Registering a new account must create an inactive user and an EmailVerification entry."""
        payload = {
            "username": self.username,
            "email": self.email,
            "password": self.password,
        }
        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email=self.email)
        self.assertFalse(user.is_active)

        verification = EmailVerification.objects.filter(user=user).first()
        self.assertIsNotNone(verification)
        self.assertTrue(mock_send_email.called)

    def test_registration_with_existing_email_or_username_fails(self):
        """Registration with already used credentials returns 400 Bad Request."""
        User.objects.create_user(
            username=self.username,
            email=self.email,
            password=self.password,
        )
        response = self.client.post(
            self.register_url,
            {"username": self.username, "email": self.email, "password": self.password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_verify_email_success_activates_user_and_removes_verification(self):
        """Submitting a valid code activates the user and removes the verification entry."""
        user = User.objects.create_user(
            username=self.username,
            email=self.email,
            password=self.password,
            is_active=False,
        )
        now = timezone.now()
        verification = EmailVerification.objects.create(
            user=user,
            expires_at=now + timedelta(minutes=15),
            last_sent_at=now,
        )
        verification.set_code("123456")
        verification.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "123456"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        self.assertTrue(user.is_active)
        self.assertFalse(EmailVerification.objects.filter(user=user).exists())

    def test_verify_email_with_invalid_code_increments_attempts(self):
        """Invalid code increments attempt counter and returns 400 Bad Request."""
        user = User.objects.create_user(
            username=self.username,
            email=self.email,
            password=self.password,
            is_active=False,
        )
        now = timezone.now()
        verification = EmailVerification.objects.create(
            user=user,
            expires_at=now + timedelta(minutes=15),
            last_sent_at=now,
        )
        verification.set_code("123456")
        verification.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "654321"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        verification.refresh_from_db()
        self.assertEqual(verification.attempts, 1)

        user.refresh_from_db()
        self.assertFalse(user.is_active)

    def test_verify_email_with_expired_code_fails(self):
        """Expired code returns 400 Bad Request."""
        user = User.objects.create_user(
            username=self.username,
            email=self.email,
            password=self.password,
            is_active=False,
        )
        verification = EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() - timedelta(minutes=1),
            last_sent_at=timezone.now() - timedelta(minutes=16),
        )
        verification.set_code("123456")
        verification.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "123456"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("expired", response.data.get("detail", "").lower())

    @patch("api.views.send_verification_email")
    def test_resend_code_cooldown_enforced(self, mock_send_email):
        """Resending verification code before cooldown expiration returns 429 Too Many Requests."""
        user = User.objects.create_user(
            username=self.username,
            email=self.email,
            password=self.password,
            is_active=False,
        )
        EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=timezone.now(),
        )

        response = self.client.post(
            self.resend_url,
            {"email": self.email},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertFalse(mock_send_email.called)

    def test_verify_email_already_active_user(self):
        """Submitting verification for an already active user returns 200 OK."""
        user = User.objects.create_user(
            username="already_active",
            email="active@example.com",
            password="Password123!",
            is_active=True,
        )
        EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=timezone.now(),
        )
        response = self.client.post(
            self.verify_url,
            {"email": "active@example.com", "code": "123456"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("already been verified", response.data.get("detail", ""))

    def test_verify_email_attempt_limit_exceeded(self):
        """Exceeding max attempts on email verification returns 429 Too Many Requests."""
        user = User.objects.create_user(
            username="max_attempts_user",
            email="attempts@example.com",
            password="Password123!",
            is_active=False,
        )
        EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=timezone.now(),
            attempts=settings.EMAIL_VERIFICATION_MAX_ATTEMPTS,
        )
        response = self.client.post(
            self.verify_url,
            {"email": "attempts@example.com", "code": "123456"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn("limit exceeded", response.data.get("detail", "").lower())

    @patch("api.views.send_verification_email")
    def test_resend_code_success_after_cooldown(self, mock_send_email):
        """Resending verification code after cooldown succeeds and updates expiry."""
        user = User.objects.create_user(
            username="resend_success_user",
            email="resend@example.com",
            password="Password123!",
            is_active=False,
        )
        old_time = timezone.now() - timedelta(minutes=5)
        verification = EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=old_time,
            resend_window_started_at=old_time,
            resend_count=0,
        )
        response = self.client.post(
            self.resend_url,
            {"email": "resend@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        verification.refresh_from_db()
        self.assertEqual(verification.resend_count, 1)
        self.assertTrue(mock_send_email.called)

    def test_resend_code_max_limit_reached(self):
        """Reaching max resend attempts returns 429 Too Many Requests."""
        user = User.objects.create_user(
            username="max_resend_user",
            email="maxresend@example.com",
            password="Password123!",
            is_active=False,
        )
        old_time = timezone.now() - timedelta(minutes=5)
        EmailVerification.objects.create(
            user=user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=old_time,
            resend_window_started_at=old_time,
            resend_count=settings.EMAIL_VERIFICATION_RESEND_MAX_ATTEMPTS,
        )
        response = self.client.post(
            self.resend_url,
            {"email": "maxresend@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn("limit exceeded", response.data.get("detail", "").lower())

    def test_jwt_token_obtain_and_refresh_flow(self):
        """Active user can obtain JWT token pair and refresh access token."""
        User.objects.create_user(
            username="jwt_user",
            email="jwt@example.com",
            password=self.password,
            is_active=True,
        )
        # Obtain tokens
        resp_login = self.client.post(
            self.token_obtain_url,
            {"username": "jwt_user", "password": self.password},
            format="json",
        )
        self.assertEqual(resp_login.status_code, status.HTTP_200_OK)
        self.assertIn("access", resp_login.data)
        refresh_token = resp_login.data.get("refresh")
        self.assertIsNotNone(refresh_token)

        # Refresh token
        resp_refresh = self.client.post(
            self.token_refresh_url,
            {"refresh": refresh_token},
            format="json",
        )
        self.assertEqual(resp_refresh.status_code, status.HTTP_200_OK)
        self.assertIn("access", resp_refresh.data)


class PasswordResetAPITests(APITestCase):
    def setUp(self):
        self.request_url = reverse("password-reset")
        self.verify_url = reverse("password-reset-verify")
        self.confirm_url = reverse("password-reset-confirm")
        self.resend_url = reverse("password-reset-resend")
        self.email = "resetuser@example.com"
        self.password = "InitialPassword123!"
        self.user = User.objects.create_user(
            username="resetuser",
            email=self.email,
            password=self.password,
            is_active=True,
        )

    @patch("api.views.send_password_reset_email")
    def test_password_reset_request_creates_record(self, mock_send_email):
        """Requesting password reset creates a PasswordReset record and triggers email."""
        response = self.client.post(
            self.request_url,
            {"email": self.email},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        reset = PasswordReset.objects.filter(user=self.user).first()
        self.assertIsNotNone(reset)
        self.assertTrue(mock_send_email.called)

    def test_password_reset_verify_code_issues_reset_token(self):
        """Verifying the reset code returns a temporary reset_token."""
        now = timezone.now()
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=now + timedelta(minutes=15),
            last_sent_at=now,
        )
        reset.set_code("654321")
        reset.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "654321"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        reset_token = response.data.get("reset_token")
        self.assertIsNotNone(reset_token)

        reset.refresh_from_db()
        self.assertTrue(reset.check_reset_token(reset_token))

    def test_password_reset_verify_code_wrong_code(self):
        """Submitting wrong code for password reset fails and increments attempts."""
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=timezone.now(),
        )
        reset.set_code("111111")
        reset.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "222222"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        reset.refresh_from_db()
        self.assertEqual(reset.attempts, 1)

    def test_password_reset_verify_expired_code(self):
        """Submitting expired code fails."""
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=timezone.now() - timedelta(minutes=1),
            last_sent_at=timezone.now() - timedelta(minutes=16),
        )
        reset.set_code("111111")
        reset.save()

        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "111111"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("expired", response.data.get("detail", "").lower())

    def test_password_reset_confirm_updates_password_and_cleans_record(self):
        """Confirming reset token sets a new password and deletes the PasswordReset record."""
        now = timezone.now()
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=now,
            last_sent_at=now,
            reset_token_expires_at=now + timedelta(minutes=15),
        )
        token = "test-reset-token-with-sufficient-length-32-chars"
        reset.set_reset_token(token)
        reset.save()

        new_password = "BrandNewSecurePassword123!"
        response = self.client.post(
            self.confirm_url,
            {"reset_token": token, "new_password": new_password},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(PasswordReset.objects.filter(user=self.user).exists())

        # Verify login credentials with updated password
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password(new_password))

    def test_password_reset_confirm_with_expired_token_fails(self):
        """Confirming with an expired reset token returns 400 Bad Request."""
        now = timezone.now()
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=now,
            last_sent_at=now,
            reset_token_expires_at=now - timedelta(minutes=5),
        )
        token = "expired-token-string-32-chars-long-here"
        reset.set_reset_token(token)
        reset.save()

        response = self.client.post(
            self.confirm_url,
            {"reset_token": token, "new_password": "NewPassword123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("expired", response.data.get("detail", "").lower())

    def test_password_reset_confirm_with_invalid_token_fails(self):
        """Confirming with an invalid token returns 400 Bad Request."""
        response = self.client.post(
            self.confirm_url,
            {
                "reset_token": "non-existent-token-string-with-enough-length",
                "new_password": "AnotherPassword123!",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_password_reset_request_non_existent_email_does_not_reveal_user(self):
        """Requesting password reset for an unknown email returns 200 OK without leaking existence."""
        response = self.client.post(
            self.request_url,
            {"email": "nonexistent@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("If an active account exists", response.data.get("detail", ""))

    def test_password_reset_verify_max_attempts_exceeded(self):
        """Exceeding max attempts on reset code verification returns 429."""
        PasswordReset.objects.create(
            user=self.user,
            expires_at=timezone.now() + timedelta(minutes=15),
            attempts=settings.PASSWORD_RESET_MAX_ATTEMPTS,
        )
        response = self.client.post(
            self.verify_url,
            {"email": self.email, "code": "123456"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn("limit exceeded", response.data.get("detail", "").lower())

    @patch("api.views.send_password_reset_email")
    def test_password_reset_resend_success_and_cooldown(self, mock_send_email):
        """Testing resend code cooldown and successful resend for password reset."""
        reset = PasswordReset.objects.create(
            user=self.user,
            expires_at=timezone.now() + timedelta(minutes=15),
            last_sent_at=timezone.now(),
            resend_window_started_at=timezone.now(),
        )
        # Attempt during cooldown
        resp_cooldown = self.client.post(self.resend_url, {"email": self.email}, format="json")
        self.assertEqual(resp_cooldown.status_code, status.HTTP_429_TOO_MANY_REQUESTS)

        # Bypass cooldown
        reset.last_sent_at = timezone.now() - timedelta(minutes=10)
        reset.save(update_fields=["last_sent_at"])

        resp_success = self.client.post(self.resend_url, {"email": self.email}, format="json")
        self.assertEqual(resp_success.status_code, status.HTTP_200_OK)
        self.assertTrue(mock_send_email.called)

    def test_password_reset_resend_without_prior_request(self):
        """Attempting to resend a code when no reset request exists returns 200 to prevent user enumeration."""
        response = self.client.post(
            self.resend_url,
            {"email": "nobody@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)