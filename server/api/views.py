import secrets
from django.db.models import Count, Min, Prefetch, Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Category, Household, ItemStatus, PantryItem, Product, ProductType, Membership, MembershipRole
from .serializers import (
    CategorySerializer,
    CustomProductCreateSerializer,
    PantryGroupSerializer,
    PantryItemCreateSerializer,
    PantryItemSerializer,
    ProductSerializer, HouseholdSerializer,
)
from .services import open_food_facts


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
