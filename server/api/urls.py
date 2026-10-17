from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from . import views

urlpatterns = [
    # Auth
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # Pantry
    path('categories/', views.CategoryListView.as_view(), name='category-list'),
    path('households/<int:household_id>/pantry/', views.PantryListView.as_view(), name='pantry'),
    path('households/<int:household_id>/items/', views.PantryItemCreateView.as_view(), name='pantry-item-create'),
    path('households/<int:household_id>/products/', views.CustomProductCreateView.as_view(), name='custom-product-create'),
    path(
        'households/<int:household_id>/products/barcode/<str:barcode>/',
        views.ProductByBarcodeView.as_view(),
        name='product-by-barcode',
    ),
]