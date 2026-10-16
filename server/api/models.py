from django.db import models
from django.contrib.auth.models import User
from django.db.models import Q


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
    """A pantry category linked to one Open Food Facts category tag."""

    name = models.CharField(max_length=100, unique=True)
    off_tag = models.CharField(max_length=100, unique=True, null=True, blank=True) # Open Food Facts tag
    match_priority = models.PositiveSmallIntegerField(default=100) # When a product fits several categories, the lowest number wins

    class Meta:
        db_table = 'categories'
        verbose_name_plural = 'Categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class ProductType(models.TextChoices):
    GLOBAL = 'global', 'Global'  # from Open Food Facts, shared by all households
    CUSTOM = 'custom', 'Custom'  # added by hand, visible only in its household


class Product(models.Model):
    household = models.ForeignKey(
        Household, on_delete=models.CASCADE, null=True, blank=True, related_name='products'
    )  # set only for custom products
    barcode = models.CharField(max_length=64, null=True, blank=True, db_index=True)
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=255, null=True, blank=True)
    package_size = models.CharField(max_length=50, blank=True, default='')
    product_type = models.CharField(max_length=20, choices=ProductType.choices, default=ProductType.CUSTOM)
    image_url = models.TextField(null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'products'
        constraints = [
            models.UniqueConstraint(
                fields=['barcode'],
                condition=Q(product_type='global'),
                name='unique_global_product_barcode',
            ),
        ]

    def __str__(self):
        return f"{self.name} ({self.brand or 'No brand'})"


class ItemStatus(models.TextChoices):
    ACTIVE = 'active', 'Active'
    EATEN = 'eaten', 'Eaten'
    WASTED = 'wasted', 'Wasted'


class FridgeItem(models.Model):
    """One physical package of a product, with its own expiry date."""

    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='fridge_items')
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name='fridge_items')
    expiry_date = models.DateField()
    status = models.CharField(max_length=20, choices=ItemStatus.choices, default=ItemStatus.ACTIVE)
    added_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='added_fridge_items')
    created_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'fridge_items'
        indexes = [models.Index(fields=['household', 'status', 'expiry_date'])]

    def __str__(self):
        return f"{self.product.name} (exp: {self.expiry_date})"

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