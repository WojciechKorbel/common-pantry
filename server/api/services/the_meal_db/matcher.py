from api.models import (
    TheMealDBIngredient,
    TheMealDBIngredientTranslation,
    TheMealDBIngredientAlias,
    IngredientAliasType,
)
from api.services.the_meal_db.normalization import normalize_name


def find_ingredients(product_name: str) -> list[dict]:

    normalized = normalize_name(product_name)

    if not normalized:
        return []

    words = normalized.split()
    matches = {}

    ingredients = TheMealDBIngredient.objects.all()

    # 1. Exact API name
    for ingredient in ingredients:

        api_name = normalize_name(ingredient.name)

        if api_name == normalized:
            matches[ingredient.id] = {
                "ingredient": ingredient,
                "score": 100,
            }

    # 2. Exact translations
    translations = (
        TheMealDBIngredientTranslation.objects
        .select_related("ingredient")
        .filter(normalized_name=normalized)
    )

    for translation in translations:

        matches[translation.ingredient_id] = {
            "ingredient": translation.ingredient,
            "score": 100,
        }

    # 3. Exact and prefix aliases
    aliases = (
        TheMealDBIngredientAlias.objects
        .select_related("ingredient")
        .all()
    )

    for alias in aliases:

        alias_name = alias.normalized_alias

        if alias.match_type == IngredientAliasType.EXACT:

            matched = normalized == alias_name
            score = 100

        else:
            alias_words = alias_name.split()

            matched = any(
                word.startswith(alias_word)
                for word in words
                for alias_word in alias_words
                if len(alias_word) >= 4
            )

            score = 90

        if matched:
            ingredient_id = alias.ingredient_id

            current_score = matches.get(
                ingredient_id,
                {},
            ).get("score", 0)

            matches[ingredient_id] = {
                "ingredient": alias.ingredient,
                "score": max(
                    current_score,
                    score + max(0, 10 - alias.priority // 10),
                ),
            }

    # 4. Sort results
    results = sorted(
        matches.values(),
        key=lambda item: (
            -item["score"],
            item["ingredient"].name,
        ),
    )

    return [
        {
            "id": item["ingredient"].themealdb_id,
            "name": item["ingredient"].name,
            "score": item["score"],
            "thumbnail": item["ingredient"].thumbnail_url,
        }
        for item in results
    ]