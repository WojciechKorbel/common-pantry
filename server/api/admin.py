from django.contrib import admin
from .models import Household, Membership, Category, Product, FridgeItem, ShoppingItem


@admin.register(Household)
class HouseholdAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'invite_code', 'created_at')
    search_fields = ('name', 'invite_code')


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'household', 'role', 'joined_at')
    list_filter = ('role', 'household')
    search_fields = ('user__username', 'household__name')


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'off_tag', 'match_priority')
    list_editable = ('match_priority',)
    search_fields = ('name', 'off_tag')
    ordering = ('match_priority',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'brand', 'package_size', 'product_type', 'household', 'category', 'barcode')
    list_filter = ('product_type', 'category')
    search_fields = ('name', 'brand', 'barcode')


@admin.register(FridgeItem)
class FridgeItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'product', 'household', 'expiry_date', 'status', 'added_by')
    list_filter = ('status', 'expiry_date', 'household', 'product__category')
    search_fields = ('product__name', 'product__brand')
    list_select_related = ('product', 'household', 'added_by')


@admin.register(ShoppingItem)
class ShoppingItemAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'household', 'quantity', 'unit', 'is_bought', 'added_by', 'bought_by')
    list_filter = ('is_bought', 'household', 'category')
    search_fields = ('name',)