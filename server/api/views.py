import secrets
import hashlib
from datetime import timedelta

from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import send_mail
from django.db import transaction
from django.db.models import Count, Min, Prefetch, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Category, Household, ItemStatus, PantryItem, Product, ProductType, Membership, MembershipRole, \
    EmailVerification, PasswordReset
from .serializers import (
    CategorySerializer,
    CustomProductCreateSerializer,
    PantryGroupSerializer,
    PantryItemCreateSerializer,
    PantryItemSerializer,
    ProductSerializer, HouseholdSerializer, ResendCodeSerializer, VerifyEmailSerializer,
    RegisterSerializer, PasswordResetRequestSerializer, PasswordResetVerifySerializer, PasswordResetConfirmSerializer,
)
from .services import open_food_facts
from django.conf import settings


def generate_verification_code():
    length = settings.EMAIL_VERIFICATION_CODE_LENGTH
    return f"{secrets.randbelow(10 ** length):0{length}d}"


def send_verification_email(email, code):
    send_mail(
        subject="Confirm your e-mail address - Shared Pantry",
        message=(
            f"Your verification code is: {code}\n\n"
            f"The code is valid fo "
            f"{settings.EMAIL_VERIFICATION_CODE_EXPIRY_MINUTES} minutes."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[email],
        fail_silently=False,
    )


class RegisterView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            with transaction.atomic():
                user = serializer.save()

                code = generate_verification_code()
                now = timezone.now()

                verification = EmailVerification(
                    user=user,
                    expires_at=now + timedelta(
                        minutes=settings.EMAIL_VERIFICATION_CODE_EXPIRY_MINUTES
                    ),
                    last_sent_at=now,
                )
                verification.set_code(code)
                verification.save()

                send_verification_email(user.email, code)

        except Exception:
            return Response(
                {
                    "detail": (
                        "Failed to send an e-mail. "
                        "Try again later."
                    )
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return Response(
            {
                "detail": (
                    "If registration is possible, "
                    "verification code was sent to the given address."
                ),
                "email": user.email,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].strip().lower()
        code = serializer.validated_data["code"]

        with transaction.atomic():
            try:
                user = User.objects.select_for_update().get(
                    email__iexact=email
                )
                verification = EmailVerification.objects.select_for_update().get(
                    user=user
                )
            except (User.DoesNotExist, EmailVerification.DoesNotExist):
                return Response(
                    {"detail": "Invalid code or request."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if user.is_active:
                return Response(
                    {"detail": "This e-mail address has already been verified."},
                    status=status.HTTP_200_OK,
                )

            if verification.attempts >= settings.EMAIL_VERIFICATION_MAX_ATTEMPTS:
                return Response(
                    {
                        "detail": (
                            "Attempt limit exceeded. "
                            "Request a new code."
                        )
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            if verification.is_expired():
                return Response(
                    {
                        "detail": (
                            "The code has expired. Request a new code to be sent."
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if not verification.check_code(code):
                verification.attempts += 1
                verification.save(update_fields=["attempts"])

                return Response(
                    {"detail": "Invalid code."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user.is_active = True
            user.save(update_fields=["is_active"])

            verification.delete()

        return Response(
            {"detail": "E-mail address has been verified successfully."},
            status=status.HTTP_200_OK,
        )


class ResendCodeView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = ResendCodeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].strip().lower()

        try:
            user = User.objects.get(
                email__iexact=email,
                is_active=False,
            )
        except User.DoesNotExist:
            return Response(
                {
                    "detail": (
                        "If your account requires verification, "
                        "instructions will be sent."
                    )
                },
                status=status.HTTP_200_OK,
            )

        with transaction.atomic():
            verification = EmailVerification.objects.select_for_update().get(
                user=user
            )

            now = timezone.now()

            # cooldown - 60 secs (settings)
            if verification.is_in_resend_cooldown():
                return Response(
                    {
                        "detail": (
                            "Wait "
                            f"{settings.EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS} "
                            "seconds before re-sending the code."
                        )
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            # resend window counter reset
            if verification.is_resend_window_expired():
                verification.resend_count = 0
                verification.resend_window_started_at = now

            # resend limit
            if verification.has_reached_resend_limit():
                return Response(
                    {
                        "detail": (
                            "Code sending limit exceeded. "
                            "Try again later."
                        )
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            # generate new code
            code = generate_verification_code()

            verification.set_code(code)
            verification.expires_at = now + timedelta(
                minutes=settings.EMAIL_VERIFICATION_CODE_EXPIRY_MINUTES
            )
            verification.attempts = 0
            verification.last_sent_at = now
            verification.resend_count += 1
            verification.save()

        try:
            send_verification_email(user.email, code)
        except Exception:
            return Response(
                {"detail":
                     "Failed to send an e-mail. "
                     "Try again later."
                 },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return Response(
            {
                "detail": (
                    "If your account requires verification, "
                    "code has been sent."
                )
            },
            status=status.HTTP_200_OK,
        )


class HouseholdMixin:
    """Resolves <household_id> from the URL; 404 unless the user is a member."""

    def get_household(self):
        if not hasattr(self, '_household'):
            self._household = get_object_or_404(
                Household,
                pk=self.kwargs['household_id'],
                memberships__user=self.request.user,
            )
        return self._household


class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


class PantryListView(HouseholdMixin, generics.ListAPIView):
    """Active items of a household, grouped by product, soonest expiry first."""

    serializer_class = PantryGroupSerializer

    def get_queryset(self):
        household = self.get_household()
        active_items = (
            PantryItem.objects
            .filter(household=household, status=ItemStatus.ACTIVE)
            .select_related('added_by')
            .order_by('expiry_date', 'id')
        )
        return (
            Product.objects
            .filter(pantry_items__household=household, pantry_items__status=ItemStatus.ACTIVE)
            .annotate(
                earliest_expiry=Min('pantry_items__expiry_date'),
                item_count=Count('pantry_items'),
            )
            .select_related('category')
            .prefetch_related(Prefetch('pantry_items', queryset=active_items, to_attr='active_items'))
            .order_by('earliest_expiry', 'name')
        )


class PantryItemCreateView(HouseholdMixin, APIView):
    """Adds `count` packages of one product with the same expiry date."""

    def post(self, request, household_id):
        household = self.get_household()
        serializer = PantryItemCreateSerializer(data=request.data, context={'household': household})
        serializer.is_valid(raise_exception=True)
        items = serializer.save(household=household, added_by=request.user)
        return Response(PantryItemSerializer(items, many=True).data, status=status.HTTP_201_CREATED)


class CustomProductCreateView(HouseholdMixin, APIView):
    """Creates a household product without a barcode (or returns the existing one with that name)."""

    def post(self, request, household_id):
        household = self.get_household()
        serializer = CustomProductCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        brand = (serializer.validated_data.get('brand') or '').strip()
        brand_filter = Q(brand__iexact=brand) if brand else (Q(brand__isnull=True) | Q(brand=''))
        existing = Product.objects.filter(
            brand_filter,
            product_type=ProductType.CUSTOM,
            household=household,
            name__iexact=serializer.validated_data['name'],
        ).first()
        if existing:
            return Response(ProductSerializer(existing).data, status=status.HTTP_200_OK)
        product = serializer.save(product_type=ProductType.CUSTOM, household=household)
        return Response(ProductSerializer(product).data, status=status.HTTP_201_CREATED)

    def get(self, request, household_id):
        household = self.get_household()
        products = (
            Product.objects
            .filter(
                Q(product_type=ProductType.CUSTOM, household=household)
                | Q(pantry_items__household=household)
            )
            .select_related('category')
            .distinct()
            .order_by('name')
        )
        search = request.query_params.get('search', '').strip()
        if search:
            products = products.filter(Q(name__icontains=search) | Q(brand__icontains=search))
        return Response(ProductSerializer(products, many=True).data)


class ProductByBarcodeView(HouseholdMixin, APIView):
    """Finds a product by barcode: this household's own products, then the shared database,
    then Open Food Facts (the result is saved for next time)."""

    def get(self, request, household_id, barcode):
        household = self.get_household()
        if not barcode.isdigit() or not 8 <= len(barcode) <= 14:
            return Response({'detail': 'Invalid barcode.'}, status=status.HTTP_400_BAD_REQUEST)

        product = (
            Product.objects
            .filter(barcode=barcode)
            .filter(Q(product_type=ProductType.GLOBAL) | Q(product_type=ProductType.CUSTOM, household=household))
            .select_related('category')
            .order_by('product_type')  # 'custom' sorts before 'global': the household's own entry wins
            .first()
        )
        if product is None:
            try:
                data = open_food_facts.fetch_product(barcode)
            except open_food_facts.OpenFoodFactsError:
                return Response(
                    {'detail': 'Product database is unavailable. Add the product manually.'},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            if data is None:
                return Response({'detail': 'Product not found.'}, status=status.HTTP_404_NOT_FOUND)

            data['category'] = open_food_facts.match_category(data.pop('categories_tags'))
            product, _ = Product.objects.get_or_create(
                product_type=ProductType.GLOBAL, barcode=barcode, defaults=data
            )

        return Response(ProductSerializer(product).data)


class HouseholdListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = HouseholdSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Household.objects.filter(
            memberships__user=self.request.user
        ).distinct().order_by('name')

    def get_serializer_context(self):
        context = super().get_serializer_context()
        return context

    def generate_invite_code(self):
        length = 6

        while True:
            code = ''.join(
                str(secrets.randbelow(10))
                for _ in range(length)
            )

            if not Household.objects.filter(invite_code=code).exists():
                return code

    def perform_create(self, serializer):
        household = serializer.save(
            invite_code=self.generate_invite_code()
        )

        Membership.objects.create(
            user=self.request.user,
            household=household,
            role=MembershipRole.OWNER,
        )


class HouseholdJoinAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        invite_code = request.data.get('invite_code')

        if not isinstance(invite_code, str) or not invite_code.strip():
            return Response(
                {
                    'success': False,
                    'detail': 'Invite code is required.',
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        invite_code = invite_code.strip()

        household = Household.objects.filter(
            invite_code=invite_code
        ).first()

        if household is None:
            return Response(
                {
                    'success': False,
                    'detail': 'Invalid invite code.',
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        membership, created = Membership.objects.get_or_create(
            user=request.user,
            household=household,
            defaults={'role': MembershipRole.MEMBER},
        )

        household_data = {
            'id': household.id,
            'name': household.name,
            'invite_code': household.invite_code,
            'role': membership.role,
            'created_at': household.created_at,
        }

        # Already a member
        if not created:
            return Response(
                {
                    'success': False,
                    'detail': 'You are already a member of this household.',
                    'household': {
                        **household_data,
                        'created_at': (
                            household.created_at.isoformat()
                            if household.created_at
                            else None
                        ),
                    },
                },
                status=status.HTTP_409_CONFLICT,
            )

        return Response(
            {
                'success': True,
                'detail': 'Successfully joined the household.',
                'household': {
                    **household_data,
                    'created_at': (
                        household.created_at.isoformat()
                        if household.created_at
                        else None
                    ),
                },
            },
            status=status.HTTP_201_CREATED,
        )

# HOUSEHOLD MEMBERS MANAGEMENT
class HouseholdManagementMixin:

    def get_membership(self, household_id):
        return get_object_or_404(
            Membership.objects.select_related("household", "user"),
            household_id=household_id,
            user=self.request.user,
        )

    def get_owner_membership(self, household_id):
        membership = self.get_membership(household_id)

        if membership.role != MembershipRole.OWNER:
            return None

        return membership

    def permission_denied_response(self):
        return Response(
            {"detail": "You do not have permission to perform this action."},
            status=status.HTTP_403_FORBIDDEN,
        )


class HouseholdLeaveAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def post(self, request, household_id):
        with transaction.atomic():
            household = get_object_or_404(
                Household.objects.select_for_update(),
                pk=household_id,
                memberships__user=request.user,
            )

            membership = get_object_or_404(
                Membership.objects.select_for_update(),
                household=household,
                user=request.user,
            )

            # Check whether anyone else belongs to this household.
            other_members = Membership.objects.filter(
                household=household,
            ).exclude(
                pk=membership.pk,
            )

            # If this is the last member, delete the entire household.
            if not other_members.exists():
                household.delete()

                return Response(
                    {
                        "detail": (
                            "You were the last member. "
                            "The household has been permanently deleted."
                        ),
                        "household_deleted": True,
                    },
                    status=status.HTTP_200_OK,
                )

            # The last owner cannot leave while other members remain.
            if membership.role == MembershipRole.OWNER:
                other_owners = other_members.filter(
                    role=MembershipRole.OWNER,
                )

                if not other_owners.exists():
                    return Response(
                        {
                            "detail": (
                                "The last owner cannot leave the household. "
                                "Promote another member first."
                            ),
                            "household_deleted": False,
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

            membership.delete()

            return Response(
                {
                    "detail": "You have left the household.",
                    "household_deleted": False,
                },
                status=status.HTTP_200_OK,
            )


class HouseholdMemberPromoteAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def post(self, request, household_id, user_id):
        if self.get_owner_membership(household_id) is None:
            return self.permission_denied_response()

        target = get_object_or_404(
            Membership,
            household_id=household_id,
            user_id=user_id,
        )

        if target.role == MembershipRole.OWNER:
            return Response(
                {"detail": "This member is already an owner."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        target.role = MembershipRole.OWNER
        target.save(update_fields=["role"])

        return Response(
            {
                "detail": "Member promoted to owner.",
                "user_id": target.user_id,
                "role": target.role,
            },
            status=status.HTTP_200_OK,
        )


class HouseholdMemberDemoteAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def post(self, request, household_id, user_id):
        if self.get_owner_membership(household_id) is None:
            return self.permission_denied_response()

        target = get_object_or_404(
            Membership,
            household_id=household_id,
            user_id=user_id,
        )

        if target.role != MembershipRole.OWNER:
            return Response(
                {"detail": "This member is not an owner."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if target.user_id == request.user.id:
            return Response(
                {
                    "detail": (
                        "You cannot demote yourself. "
                        "Another owner must perform this action."
                    )
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        target.role = MembershipRole.MEMBER
        target.save(update_fields=["role"])

        return Response(
            {
                "detail": "Owner demoted to member.",
                "user_id": target.user_id,
                "role": target.role,
            },
            status=status.HTTP_200_OK,
        )


class HouseholdMemberDeleteAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def delete(self, request, household_id, user_id):
        if self.get_owner_membership(household_id) is None:
            return self.permission_denied_response()

        target = get_object_or_404(
            Membership,
            household_id=household_id,
            user_id=user_id,
        )

        if target.role == MembershipRole.OWNER:
            other_owners = Membership.objects.filter(
                household_id=household_id,
                role=MembershipRole.OWNER,
            ).exclude(user_id=user_id)

            if not other_owners.exists():
                return Response(
                    {
                        "detail": (
                            "The last owner cannot be removed "
                            "from the household."
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

        target.delete()

        return Response(
            {"detail": "Member removed from the household."},
            status=status.HTTP_200_OK,
        )


class HouseholdSettingsAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def patch(self, request, household_id):
        if self.get_owner_membership(household_id) is None:
            return self.permission_denied_response()

        household = get_object_or_404(
            Household,
            pk=household_id,
        )

        name = request.data.get("name")

        if not isinstance(name, str) or not name.strip():
            return Response(
                {"name": ["A non-empty name is required."]},
                status=status.HTTP_400_BAD_REQUEST,
            )

        household.name = name.strip()[:100]
        household.save(update_fields=["name"])

        return Response(
            {
                "id": household.id,
                "name": household.name,
                "detail": "Household settings updated.",
            },
            status=status.HTTP_200_OK,
        )


class HouseholdDetailsAPIView(
    HouseholdManagementMixin,
    APIView,
):
    permission_classes = [IsAuthenticated]

    def get(self, request, household_id):
        membership = self.get_membership(household_id)
        household = membership.household

        members = Membership.objects.filter(
            household=household,
        ).select_related("user").order_by("joined_at")

        return Response(
            {
                "id": household.id,
                "name": household.name,
                "invite_code": household.invite_code,
                "created_at": household.created_at,
                "role": membership.role,
                "members": [
                    {
                        "user_id": member.user_id,
                        "username": member.user.username,
                        "role": member.role,
                        "joined_at": member.joined_at,
                        "is_me": member.user_id == request.user.id,
                    }
                    for member in members
                ],
            },
            status=status.HTTP_200_OK,
        )

# PASSWORD FORGOT
def generate_password_reset_code():
    length = settings.PASSWORD_RESET_CODE_LENGTH
    return f"{secrets.randbelow(10 ** length):0{length}d}"


def send_password_reset_email(email, code):
    # print(f"Sending password reset email to {email} with code {code}") # TODO: only for local tests!
    send_mail(
        subject="Password reset - Shared Pantry",
        message=(
            f"Your password reset code is: {code}\n\n"
            f"The code is valid for "
            f"{settings.PASSWORD_RESET_CODE_EXPIRY_MINUTES} minutes.\n\n"
            "If you did not request this, ignore this email."
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[email],
        fail_silently=False,
    )


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        generic_response = Response(
            {
                "detail": (
                    "If an active account exists for this address, "
                    "a reset code will be sent."
                )
            },
            status=status.HTTP_200_OK,
        )

        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].strip()

        user = User.objects.filter(
            email__iexact=email,
            is_active=True,
        ).first()

        # don't disclose whether an account exists
        if user is None:
            return generic_response

        now = timezone.now()

        with transaction.atomic():
            reset, created = PasswordReset.objects.get_or_create(
                user=user,
                defaults={
                    "code_hash": "",
                    "expires_at": now,
                    "last_sent_at": now,
                    "resend_window_started_at": now,
                },
            )

            reset = PasswordReset.objects.select_for_update().get(
                pk=reset.pk
            )

            if not created:
                if reset.is_in_resend_cooldown():
                    return Response(
                        {
                            "detail": (
                                "Please wait before requesting "
                                "another reset code."
                            )
                        },
                        status=status.HTTP_429_TOO_MANY_REQUESTS,
                    )

                if reset.is_resend_window_expired():
                    reset.resend_count = 0
                    reset.resend_window_started_at = now

                if reset.has_reached_resend_limit():
                    return Response(
                        {
                            "detail": (
                                "Reset code sending limit exceeded. "
                                "Try again later."
                            )
                        },
                        status=status.HTTP_429_TOO_MANY_REQUESTS,
                    )

                reset.resend_count += 1

            code = generate_password_reset_code()

            reset.set_code(code)
            reset.expires_at = now + timedelta(
                minutes=settings.PASSWORD_RESET_CODE_EXPIRY_MINUTES
            )
            reset.attempts = 0
            reset.last_sent_at = now

            # new code invalidates the previous reset token
            reset.reset_token_hash = ""
            reset.reset_token_expires_at = None

            reset.save()

        try:
            send_password_reset_email(user.email, code)
        except Exception:
            PasswordReset.objects.filter(
                pk=reset.pk,
                code_hash=reset.code_hash,
            ).update(
                expires_at=timezone.now(),
                reset_token_hash="",
                reset_token_expires_at=None,
            )

            return Response(
                {"detail": "Unable to send the email. Try again later."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return generic_response


class PasswordResetVerifyView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = PasswordResetVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].strip()
        code = serializer.validated_data["code"]

        with transaction.atomic():
            try:
                user = User.objects.get(
                    email__iexact=email,
                    is_active=True,
                )

                reset = PasswordReset.objects.select_for_update().get(
                    user=user
                )
            except (
                    User.DoesNotExist,
                    PasswordReset.DoesNotExist,
            ):
                return Response(
                    {"detail": "Invalid code or request."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if reset.attempts >= settings.PASSWORD_RESET_MAX_ATTEMPTS:
                return Response(
                    {
                        "detail": (
                            "Attempt limit exceeded. "
                            "Request a new code."
                        )
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            if reset.is_expired():
                return Response(
                    {
                        "detail": "Code expired. Request a new code."
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if not reset.check_code(code):
                reset.attempts += 1
                reset.save(update_fields=["attempts"])

                return Response(
                    {"detail": "Invalid code."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            reset_token = secrets.token_urlsafe(32)

            reset.set_reset_token(reset_token)
            reset.reset_token_expires_at = timezone.now() + timedelta(
                minutes=settings.PASSWORD_RESET_TOKEN_EXPIRY_MINUTES
            )

            reset.expires_at = timezone.now()
            reset.save(
                update_fields=[
                    "code_hash",
                    "expires_at",
                    "reset_token_hash",
                    "reset_token_expires_at",
                ]
            )

        return Response(
            {
                "detail": "Code verified successfully.",
                "reset_token": reset_token,
            },
            status=status.HTTP_200_OK,
        )


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        reset_token = serializer.validated_data["reset_token"]
        new_password = serializer.validated_data["new_password"]

        token_hash = hashlib.sha256(
            reset_token.encode("utf-8")
        ).hexdigest()

        with transaction.atomic():
            try:
                reset = PasswordReset.objects.select_for_update().get(
                    reset_token_hash=token_hash,
                )
            except PasswordReset.DoesNotExist:
                return Response(
                    {"detail": "Invalid or expired reset token."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if (
                    reset.reset_token_expires_at is None
                    or timezone.now() >= reset.reset_token_expires_at
            ):
                return Response(
                    {"detail": "Invalid or expired reset token."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user = User.objects.select_for_update().get(
                pk=reset.user_id
            )

            try:
                validate_password(new_password, user=user)
            except DjangoValidationError as exc:
                return Response(
                    {"new_password": list(exc.messages)},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user.set_password(new_password)
            user.save(update_fields=["password"])

            reset.delete()

        return Response(
            {"detail": "Password has been reset successfully."},
            status=status.HTTP_200_OK,
        )


class PasswordResetResendView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = ResendCodeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].strip()

        user = User.objects.filter(
            email__iexact=email,
            is_active=True,
        ).first()

        generic_response = Response(
            {
                "detail": (
                    "If an active account exists for this address, "
                    "a reset code will be sent."
                )
            },
            status=status.HTTP_200_OK,
        )

        if user is None:
            return generic_response

        now = timezone.now()

        with transaction.atomic():
            try:
                reset = PasswordReset.objects.select_for_update().get(
                    user=user,
                )
            except PasswordReset.DoesNotExist:
                return generic_response

            if reset.is_in_resend_cooldown():
                return Response(
                    {
                        "detail": (
                            "Please wait before requesting another code."
                        ),
                        "retry_after_seconds": (
                                settings.PASSWORD_RESET_RESEND_COOLDOWN_SECONDS
                                - int((now - reset.last_sent_at).total_seconds())
                        ),
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            if reset.is_resend_window_expired():
                reset.resend_count = 0
                reset.resend_window_started_at = now

            if reset.has_reached_resend_limit():
                return Response(
                    {
                        "detail": (
                            "Code sending limit exceeded. Try again later."
                        )
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            code = generate_password_reset_code()

            reset.set_code(code)
            reset.expires_at = now + timedelta(
                minutes=settings.PASSWORD_RESET_CODE_EXPIRY_MINUTES
            )
            reset.attempts = 0
            reset.last_sent_at = now
            reset.resend_count += 1

            reset.reset_token_hash = ""
            reset.reset_token_expires_at = None

            reset.save()

        try:
            send_password_reset_email(user.email, code)
        except Exception:
            PasswordReset.objects.filter(
                pk=reset.pk,
                code_hash=reset.code_hash,
            ).update(
                expires_at=timezone.now(),
                reset_token_hash="",
                reset_token_expires_at=None,
            )

            return Response(
                {
                    "detail": (
                        "Unable to send the email. Try again later."
                    )
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return generic_response