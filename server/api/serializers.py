from rest_framework import serializers
from .models import FridgeItem, Category, Product


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name']


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name', 'brand', 'barcode', 'image_url']


class FridgeItemSerializer(serializers.ModelSerializer):
    display_name = serializers.ReadOnlyField()
    category_name = serializers.CharField(source='category.name', read_only=True)
    product_details = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = FridgeItem
        fields = [
            'id',
            'household',
            'product',
            'product_details',
            'custom_name',
            'display_name',
            'category',
            'category_name',
            'quantity',
            'unit',
            'expiry_date',
            'status',
            'added_by',
            'created_at',
            'closed_at',
        ]
        read_only_fields = ['id', 'created_at', 'closed_at']