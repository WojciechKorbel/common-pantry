import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0003_seed_categories"),
        ("contenttypes", "0002_remove_content_type_name"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.RenameModel(old_name='FridgeItem', new_name='PantryItem'),
        migrations.AlterModelTable(name='pantryitem', table='pantry_items'),
        migrations.RenameIndex(
            model_name='pantryitem',
            old_name='fridge_item_househo_1a7252_idx',
            new_name='pantry_item_hh_status_exp_idx',
        ),
        migrations.AlterField(
            model_name='pantryitem',
            name='household',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE, related_name='pantry_items', to='api.household'
            ),
        ),
        migrations.AlterField(
            model_name='pantryitem',
            name='product',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT, related_name='pantry_items', to='api.product'
            ),
        ),
        migrations.AlterField(
            model_name='pantryitem',
            name='added_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='added_pantry_items',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]