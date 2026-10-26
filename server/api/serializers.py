from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Category, PantryItem, Product, ProductType, Household, Membership
from django.contrib.auth.password_validation import validate_password


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    username = serializers.CharField(
        min_length=3,
        max_length=150,
        trim_whitespace=True,
    )
    password = serializers.CharField(
        write_only=True,
        trim_whitespace=False,
        min_length=8,
    )

    def validate_email(self, value):
        value = value.strip().lower()

        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "This email address could not be registered."
            )

        return value

    def validate_username(self, value):
        value = value.strip()

        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError(
                "This username is already taken."
            )

        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        email = validated_data["email"]
        password = validated_data["password"]
        username = validated_data["username"]

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            is_active=False,
        )

        return user


class VerifyEmailSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.RegexField(
        regex=r"^[0-9]{6}$",
        error_messages={
            "invalid": "The code must consist of 6 digits."
        },
    )


class ResendCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(
        write_only=True,
        trim_whitespace=False,
    )


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


class HouseholdSerializer(serializers.ModelSerializer):
    role = serializers.SerializerMethodField()

    class Meta:
        model = Household
        fields = ['id', 'name', 'invite_code', 'created_at', 'role']
        read_only_fields = ['id', 'invite_code', 'created_at', 'role']

    def get_role(self, obj):
        user = self.context['request'].user

        membership = Membership.objects.filter(
            household=obj,
            user=user,
        ).first()

        return membership.role if membership else None


# PASSWORD FORGOT

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.RegexField(
        regex=r"^[0-9]{6}$",
        error_messages={
            "invalid": "The code must consist of 6 digits."
        },
    )


class PasswordResetConfirmSerializer(serializers.Serializer):
    reset_token = serializers.CharField(
        write_only=True,
        trim_whitespace=False,
        min_length=32,
        max_length=256,
    )
    new_password = serializers.CharField(
        write_only=True,
        trim_whitespace=False,
        min_length=8,
    )

    def validate_new_password(self, value):
        validate_password(value)
        return value
