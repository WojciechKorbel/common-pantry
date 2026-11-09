from django.core.management.base import BaseCommand
from django.db import transaction

from api.models import (
    TheMealDBIngredient,
    TheMealDBIngredientTranslation,
    TheMealDBIngredientAlias,
)


class Command(BaseCommand):
    help = "Clear all TheMealDB ingredient catalog data"

    @transaction.atomic
    def handle(self, *args, **options):

        aliases_count = TheMealDBIngredientAlias.objects.count()
        translations_count = TheMealDBIngredientTranslation.objects.count()
        ingredients_count = TheMealDBIngredient.objects.count()

        TheMealDBIngredientAlias.objects.all().delete()
        TheMealDBIngredientTranslation.objects.all().delete()
        TheMealDBIngredient.objects.all().delete()

        self.stdout.write(
            self.style.SUCCESS(
                "Ingredient catalog cleared successfully!"
            )
        )

        self.stdout.write(f"Deleted ingredients: {ingredients_count}")
        self.stdout.write(f"Deleted translations: {translations_count}")
        self.stdout.write(f"Deleted aliases: {aliases_count}")