import json

from pathlib import Path

from django.db import transaction

from api.models import TheMealDBIngredient, TheMealDBIngredientTranslation, TheMealDBIngredientAlias
from api.services.the_meal_db.normalization import normalize_name
from api.services.the_meal_db.themealdb import sync_themealdb_ingredients

DATA_DIR = (
    Path(__file__).resolve().parent / "data"
)


def load_json(filename):

    path = DATA_DIR / filename

    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def initialize_ingredients():

    if TheMealDBIngredient.objects.exists():
        return

    print("[CATALOG] Initializing TheMealDB ingredients...")

    count = sync_themealdb_ingredients()

    print(f"[CATALOG] Imported {count} ingredients")


def initialize_translations():

    if TheMealDBIngredientTranslation.objects.exists():
        return

    print("[CATALOG] Importing translations...")

    data = load_json("translations.json")

    ingredients = {
        normalize_name(item.name): item
        for item in TheMealDBIngredient.objects.all()
    }

    objects = []

    for ingredient_name, translations in data.items():

        ingredient = ingredients.get(
            normalize_name(ingredient_name)
        )

        if not ingredient:
            print(
                f"[CATALOG] Unknown ingredient translation: "
                f"{ingredient_name}"
            )
            continue

        for language, translated_name in translations.items():

            objects.append(
                TheMealDBIngredientTranslation(
                    ingredient=ingredient,
                    language_code=language,
                    name=translated_name,
                    normalized_name=normalize_name(
                        translated_name
                    ),
                )
            )

    with transaction.atomic():

        TheMealDBIngredientTranslation.objects.bulk_create(
            objects,
            ignore_conflicts=True,
        )

    print(f"[CATALOG] Imported {len(objects)} translations")


def initialize_aliases():

    if TheMealDBIngredientAlias.objects.exists():
        return

    print("[CATALOG] Importing aliases...")

    data = load_json("aliases.json")

    ingredients = {
        normalize_name(item.name): item
        for item in TheMealDBIngredient.objects.all()
    }

    objects = []

    for item in data:

        ingredient = ingredients.get(
            normalize_name(item["ingredient"])
        )

        if not ingredient:
            print(
                f"[CATALOG] Unknown ingredient alias: "
                f"{item['ingredient']}"
            )
            continue

        for alias_data in item.get("aliases", []):

            alias_name = alias_data["name"]

            objects.append(
                TheMealDBIngredientAlias(
                    ingredient=ingredient,
                    language_code=item["language"],
                    alias=alias_name,
                    normalized_alias=normalize_name(
                        alias_name
                    ),
                    match_type=alias_data["type"],
                )
            )

    with transaction.atomic():

        TheMealDBIngredientAlias.objects.bulk_create(
            objects,
            ignore_conflicts=True,
        )

    print(f"[CATALOG] Imported {len(objects)} aliases")


def ensure_catalog_initialized():

    initialize_ingredients()

    if not TheMealDBIngredient.objects.exists():
        raise RuntimeError(
            "TheMealDB ingredient catalog is empty"
        )

    initialize_translations()
    initialize_aliases()

    print("[CATALOG] Initialization completed")