from django.db import models
from django.contrib.auth.models import User


class Household(models.Model):
    name = models.CharField(max_length=100)
    invite_code = models.CharField(max_length=32, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'households'

    def __str__(self):
        return self.name


class MembershipRole(models.TextChoices):
    OWNER = 'owner', 'Owner'
    MEMBER = 'member', 'Member'


class Membership(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memberships')
    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='memberships')
    role = models.CharField(max_length=20, choices=MembershipRole.choices, default=MembershipRole.MEMBER)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'memberships'
        unique_together = ('user', 'household')

    def __str__(self):
        return f"{self.user.username} - {self.household.name} ({self.role})"


class Category(models.Model):
    name = models.CharField(max_length=100)

    class Meta:
        db_table = 'categories'
        verbose_name_plural = 'Categories'

    def __str__(self):
        return self.name


class ProductType(models.TextChoices):
    GLOBAL = 'global', 'Global'
    CUSTOM = 'custom', 'Custom'


class Product(models.Model):
    household = models.ForeignKey(Household, on_delete=models.CASCADE, null=True, blank=True, related_name='products')
    barcode = models.CharField(max_length=64, null=True, blank=True, db_index=True)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, null=True, blank=True)
    product_type = models.CharField(max_length=20, choices=ProductType.choices, default=ProductType.CUSTOM)
    image_url = models.TextField(null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'products'

    def __str__(self):
        return f"{self.name} ({self.brand or 'No brand'})"


class ItemStatus(models.TextChoices):
    ACTIVE = 'active', 'Active'
    EATEN = 'eaten', 'Eaten'
    WASTED = 'wasted', 'Wasted'


class FridgeItem(models.Model):
    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='fridge_items')
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, blank=True, related_name='fridge_items')
    custom_name = models.CharField(max_length=255, null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='fridge_items')
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1.00)
    unit = models.CharField(max_length=30, default='pcs')
    expiry_date = models.DateField()
    status = models.CharField(max_length=20, choices=ItemStatus.choices, default=ItemStatus.ACTIVE)
    added_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='added_fridge_items')
    created_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'fridge_items'

    @property
    def display_name(self):
        if self.custom_name:
            return self.custom_name
        if self.product:
            return self.product.name
        return "Unknown item"

    def __str__(self):
        return f"{self.display_name} - {self.quantity} {self.unit} (exp: {self.expiry_date})"


class ShoppingItem(models.Model):
    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='shopping_items')
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, blank=True, related_name='shopping_items')
    name = models.CharField(max_length=255)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1.00)
    unit = models.CharField(max_length=30, default='pcs')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='shopping_items')
    is_bought = models.BooleanField(default=False)
    added_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='added_shopping_items')
    bought_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='bought_shopping_items')
    created_at = models.DateTimeField(auto_now_add=True)
    bought_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'shopping_items'

    def __str__(self):
        return f"{self.name} ({self.quantity} {self.unit})"