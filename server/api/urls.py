from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from . import views

from .views import RegisterView, VerifyEmailView, ResendCodeView, PasswordResetRequestView, PasswordResetVerifyView, \
    PasswordResetConfirmView, PasswordResetResendView
from .views import (
    HouseholdLeaveAPIView,
    HouseholdMemberPromoteAPIView,
    HouseholdMemberDemoteAPIView,
    HouseholdMemberDeleteAPIView,
    HouseholdSettingsAPIView,
    HouseholdDetailsAPIView,
)

urlpatterns = [
    # Auth
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # Auth - Register
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/verify-email/", VerifyEmailView.as_view(), name="verify-email"),
    path("auth/resend-code/", ResendCodeView.as_view(), name="resend-code"),
    # Auth - Password forgot
    path(
        "auth/password-reset/",
        PasswordResetRequestView.as_view(),
        name="password-reset",
    ),
    path(
        "auth/password-reset/verify/",
        PasswordResetVerifyView.as_view(),
        name="password-reset-verify",
    ),
    path(
        "auth/password-reset/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),
    path(
        "auth/password-reset/resend/",
        PasswordResetResendView.as_view(),
        name="password-reset-resend",
    ),
    # Pantry
    path('categories/', views.CategoryListView.as_view(), name='category-list'),
    path('households/<int:household_id>/pantry/', views.PantryListView.as_view(), name='pantry'),
    path('households/<int:household_id>/items/', views.PantryItemCreateView.as_view(), name='pantry-item-create'),
    path('households/<int:household_id>/products/', views.CustomProductCreateView.as_view(),
         name='custom-product-create'),
    path(
        'households/<int:household_id>/products/barcode/<str:barcode>/',
        views.ProductByBarcodeView.as_view(),
        name='product-by-barcode',
    ),
    # Households
    path('households/', views.HouseholdListCreateAPIView.as_view(), name='household_list_create'),
    path(
        'households/join/',
        views.HouseholdJoinAPIView.as_view(),
        name='household_join',
    ),
    # Household management
    path(
        "households/<int:household_id>/leave/",
        HouseholdLeaveAPIView.as_view(),
        name="household-leave",
    ),
    path(
        "households/<int:household_id>/members/<int:user_id>/promote/",
        HouseholdMemberPromoteAPIView.as_view(),
        name="household-member-promote",
    ),
    path(
        "households/<int:household_id>/members/<int:user_id>/demote/",
        HouseholdMemberDemoteAPIView.as_view(),
        name="household-member-demote",
    ),
    path(
        "households/<int:household_id>/members/<int:user_id>/",
        HouseholdMemberDeleteAPIView.as_view(),
        name="household-member-delete",
    ),
    path(
        "households/<int:household_id>/settings/",
        HouseholdSettingsAPIView.as_view(),
        name="household-settings",
    ),
    path(
        "households/<int:household_id>/details/",
        HouseholdDetailsAPIView.as_view(),
        name="household-details",
    ),
]
