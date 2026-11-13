import re
import unicodedata


def normalize_name(value: str) -> str:
    if not isinstance(value, str):
        return ""

    value = value.strip().lower()
    value = value.replace("ł", "l")

    value = unicodedata.normalize("NFKD", value)

    value = "".join(
        char
        for char in value
        if not unicodedata.combining(char)
    )

    value = re.sub(r"[^a-z0-9]+", " ", value)

    return re.sub(r"\s+", " ", value).strip()