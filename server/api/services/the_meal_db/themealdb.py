import requests

from django.utils import timezone

from api.models import TheMealDBIngredient
from api.services.the_meal_db.normalization import normalize_name

API_URL = (
    "https://www.themealdb.com/api/json/v1/1/list.php?i=list"
)


def fetch_themealdb_ingredients():
    response = requests.get(API_URL, timeout=20)
    response.raise_for_status()

    return response.json().get("meals") or []


def sync_themealdb_ingredients():

    api_ingredients = fetch_themealdb_ingredients()

    if not api_ingredients:
        raise ValueError("TheMealDB returned an empty ingredient list")

    synced = 0

    for item in api_ingredients:

        name = item.get("strIngredient", "").strip()

        if not name:
            continue

        external_id = (
            str(item.get("idIngredient") or "").strip()
            or normalize_name(name)
        )

        TheMealDBIngredient.objects.update_or_create(
            themealdb_id=external_id,
            defaults={
                "name": name,
                "normalized_name": normalize_name(name),
                "description": item.get("strDescription"),
                "thumbnail_url": item.get("strThumb"),
                "ingredient_type": item.get("strType"),
                "updated_at": timezone.now(),
            },
        )

        synced += 1

    return synced