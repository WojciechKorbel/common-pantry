import requests
import random

from collections import defaultdict

BASE_URL = "https://www.themealdb.com/api/json/v1/1"
MAX_RECIPES = 20


def fetch_recipes_for_ingredient(ingredient_name: str) -> list[dict]:
    """
    Fetch recipe summaries for one TheMealDB ingredient.
    """

    try:
        response = requests.get(
            f"{BASE_URL}/filter.php",
            params={"i": ingredient_name},
            timeout=15,
        )

        response.raise_for_status()

        data = response.json()

        meals = data.get("meals") or []

        return [
            {
                "id": meal["idMeal"],
                "name": meal["strMeal"],
                "thumbnail": meal["strMealThumb"],
            }
            for meal in meals
            if meal.get("idMeal")
               and meal.get("strMeal")
        ]

    except requests.RequestException as error:
        print(
            f"[THEMEALDB] Error fetching recipes "
            f"for {ingredient_name}: {error}"
        )
        return []


def fetch_recipes_for_top_ingredients(
        matched_ingredients: list[dict],
        limit: int = 3,
) -> list[dict]:
    """
    Fetch recipes for the top matching ingredients.

    Recipes matching multiple ingredients receive a higher score.
    Duplicate recipes are merged.
    """

    top_ingredients = matched_ingredients[:limit]

    recipes = defaultdict(
        lambda: {
            "id": None,
            "name": None,
            "thumbnail": None,
            "match_score": 0,
            "matched_ingredients": [],
        }
    )

    for ingredient in top_ingredients:

        ingredient_name = ingredient["name"]
        ingredient_score = ingredient["score"]

        meals = fetch_recipes_for_ingredient(
            ingredient_name
        )

        for meal in meals:
            recipe = recipes[meal["id"]]

            recipe["id"] = meal["id"]
            recipe["name"] = meal["name"]
            recipe["thumbnail"] = meal["thumbnail"]

            recipe["match_score"] += ingredient_score

            recipe["matched_ingredients"].append(
                ingredient_name
            )

    results = list(recipes.values())

    results.sort(
        key=lambda recipe: (
            -len(recipe["matched_ingredients"]),
            -recipe["match_score"],
            recipe["name"],
        )
    )

    if len(results) > MAX_RECIPES:
        results = random.sample(results, MAX_RECIPES)

    return results
