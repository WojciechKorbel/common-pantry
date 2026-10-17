from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Category, PantryItem, Product, ProductType


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name']


class UserSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username']


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)

    class Meta:
        model = Product
        fields = ['id', 'name', 'brand', 'barcode', 'package_size', 'image_url', 'category', 'product_type']


class CustomProductCreateSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), required=False, allow_null=True
    )

    class Meta:
        model = Product
        fields = ['name', 'brand', 'package_size', 'category', 'barcode']


class PantryGroupItemSerializer(serializers.ModelSerializer):
    """One package inside a pantry group (a row under an expanded tile)."""

    added_by = UserSummarySerializer(read_only=True)

    class Meta:
        model = PantryItem
        fields = ['id', 'expiry_date', 'added_by', 'created_at']


class PantryGroupSerializer(serializers.ModelSerializer):
    """A product with all its active packages in one household (one tile on the list)."""

    category = CategorySerializer(read_only=True)
    item_count = serializers.IntegerField(read_only=True)
    earliest_expiry = serializers.DateField(read_only=True)
    items = PantryGroupItemSerializer(source='active_items', many=True, read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'brand', 'image_url', 'package_size', 'category',
            'item_count', 'earliest_expiry', 'items',
        ]


class PantryItemSerializer(serializers.ModelSerializer):
    added_by = UserSummarySerializer(read_only=True)

    class Meta:
        model = PantryItem
        fields = ['id', 'product', 'expiry_date', 'status', 'added_by', 'created_at']


class PantryItemCreateSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())
    expiry_date = serializers.DateField()
    count = serializers.IntegerField(min_value=1, max_value=20, default=1)

    def validate_product(self, product):
        household = self.context['household']
        if product.product_type == ProductType.CUSTOM and product.household_id != household.id:
            raise serializers.ValidationError('This product does not belong to the household.')
        return product

    def create(self, validated_data):
        count = validated_data.pop('count')
        return PantryItem.objects.bulk_create(PantryItem(**validated_data) for _ in range(count))