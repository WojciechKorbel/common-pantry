# Backend & API Guide – Common Pantry

The backend application is fully deployed and operational in the cloud. **There is no need to run Python, Docker, or PostgreSQL locally.**

**Contents**
1. [Environment & Infrastructure](#environment--infrastructure)
2. [CI/CD & Deployment Workflow](#cicd--deployment-workflow)
3. [Mobile App (Flutter) Integration](#mobile-app-flutter-integration)
4. [Web Admin Panel on PC](#web-admin-panel-on-pc)
5. [Database & Schema Migrations](#database--schema-migrations)
6. [Running Tests](#running-tests)

---

## Environment & Infrastructure

* **API Server (Render):** `https://common-pantry-api.onrender.com` (Frankfurt, EU Central region)
* **Database (Neon PostgreSQL):** Remote cloud PostgreSQL instance connected via `DATABASE_URL` environment variable
* **Web Admin Panel (PC):** `https://common-pantry-api.onrender.com/admin/`

> ⏱ **Render Free Tier Notice:**  
> The free instance spins down during periods of inactivity. The first request after an idle period may take **30–50 seconds** while the container starts up. Subsequent calls respond immediately.

---

## CI/CD & Deployment Workflow

Deployment to the cloud is **fully automated via Render**:

1. **Target Branch:** Render tracks the **`develop`** branch of our GitHub repository.
2. **Auto-Deploy on Push / Merge:** Every time new code is merged or pushed directly to `develop`, Render automatically triggers a new deployment cycle:
   - Pulls the latest commits from `develop`.
   - Runs the build command: installs dependencies, runs database migrations against Neon, and bundles static files.
   - Restarts the production web server with zero manual intervention.
3. **Branch Rule:** Always open Pull Requests targeting `develop`. Once approved and merged, your changes go live within 2–3 minutes.

---

## Mobile App (Flutter) Integration

The mobile application communicates with the server exclusively via JSON HTTP requests.

### 1. Available Endpoints

All endpoints except login require the header `Authorization: Bearer <access>`.
`{household_id}` must be a household the user belongs to – otherwise the API answers `404`.

| Method | Endpoint | Authorization | Description / Goal |
| :--- | :--- | :--- | :--- |
| **GET** | `/` | None | **Health Check:** Returns API operational status (`{"status": "ok", "app": "Common Pantry API"}`). |
| **POST** | `/api/auth/token/` | None | **Login:** Accepts `username` and `password`, returns JWT `access` and `refresh` tokens. |
| **POST** | `/api/auth/token/refresh/` | None | **Refresh Token:** Accepts `{ "refresh": "..." }`, returns a fresh `access` token. |
| **GET** | `/api/categories/` | `Bearer <access>` | **Categories:** All product categories (for filters and the add-product form). |
| **GET** | `/api/households/{household_id}/pantry/` | `Bearer <access>` | **Pantry:** Active items grouped by product, soonest expiry first. |
| **GET** | `/api/households/{household_id}/products/barcode/{barcode}/` | `Bearer <access>` | **Barcode Lookup:** Finds a product by barcode (household's own products → our database → Open Food Facts). |
| **POST** | `/api/households/{household_id}/products/` | `Bearer <access>` | **Custom Product:** Creates a product added by hand (or returns the existing one with the same name). |
| **POST** | `/api/households/{household_id}/items/` | `Bearer <access>` | **Add Items:** Adds `count` packages of a product with one expiry date. |

> Households are not exposed in the API yet. Until then the app uses household `1`.

**Token lifetime:** `access` expires after **5 minutes**, `refresh` after **1 day**. When a request
returns `401`, get a new `access` via `/api/auth/token/refresh/` and retry; if that fails too, send the
user to the login screen.

---

### 2. Product vs. Pantry Item

- A **product** is *what* something is: "Serek wiejski Piątnica 200 g", with a picture and a category.
  - `global` products come from Open Food Facts and are shared by all households;
  - `custom` products are added by hand and visible only in their household.
- A **pantry item** is *one physical package* in a household, with its own expiry date.

The pantry list shows one tile per product (`item_count` packages, `earliest_expiry` on top) that expands
into its items. Adding something to the pantry is therefore always two steps: **get a product id**
(by barcode or by creating a custom product), then **add items** of that product.

---

### 3. Request & Response Examples

#### A. User Login (`POST /api/auth/token/`)
Send JSON payload with user credentials:
```json
{
  "username": "admin",
  "password": "<CREDENTIALS_FOUND_IN_DOCUMENTS>"
}
```

Response (`200 OK`):
```json
{
  "refresh": "eyJhbGciOi...",
  "access": "eyJhbGciOi..."
}
```

#### B. Pantry List (`GET /api/households/1/pantry/`)
Include the authorization header:
```http
Authorization: Bearer <your_access_token>
```

Response (`200 OK`):
```json
[
  {
    "id": 1,
    "name": "Serek wiejski",
    "brand": "Piątnica",
    "image_url": "https://images.openfoodfacts.org/images/products/590/082/000/0141/front_pl.3.200.jpg",
    "package_size": "200 g",
    "category": {"id": 4, "name": "Dairy"},
    "item_count": 2,
    "earliest_expiry": "2026-10-06",
    "items": [
      {"id": 1, "expiry_date": "2026-10-06", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:36.374415+02:00"},
      {"id": 2, "expiry_date": "2026-10-15", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:36.374756+02:00"}
    ]
  }
]
```
*Only active items are returned. Search and category filtering are done in the app on this list.*

#### C. Barcode Lookup (`GET /api/households/1/products/barcode/3017620422003/`)

Response (`200 OK`):
```json
{
  "id": 2,
  "name": "Nutella",
  "brand": "Nutella, Ferrero",
  "barcode": "3017620422003",
  "package_size": "400 g",
  "image_url": "https://images.openfoodfacts.org/images/products/301/762/042/2003/front_en.633.200.jpg",
  "category": {"id": 9, "name": "Sweet spreads & honey"},
  "product_type": "global"
}
```
* `404` – barcode unknown, `503` – Open Food Facts is down. In both cases offer to add the product by
  hand (example D) with the scanned barcode pre-filled.
* `400` – not a valid barcode (8–14 digits).

#### D. Custom Product (`POST /api/households/1/products/`)
```json
{
  "name": "Zupa pomidorowa",
  "category": 3
}
```
Optional fields: `brand`, `package_size`, `barcode`.

Response (`201 Created`, or `200 OK` when a custom product with this name already exists in the household):
```json
{
  "id": 3,
  "name": "Zupa pomidorowa",
  "brand": null,
  "barcode": null,
  "package_size": "",
  "image_url": null,
  "category": {"id": 3, "name": "Ready meals & soups"},
  "product_type": "custom"
}
```

#### E. Add Items (`POST /api/households/1/items/`)
Use the product `id` from example C or D:
```json
{
  "product": 1,
  "expiry_date": "2026-10-20",
  "count": 2
}
```
`count` is 1–20 (default 1); all packages get the same expiry date.

Response (`201 Created`):
```json
[
  {"id": 3, "product": 1, "expiry_date": "2026-10-20", "status": "active", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:37.383433+02:00"},
  {"id": 4, "product": 1, "expiry_date": "2026-10-20", "status": "active", "added_by": {"id": 1, "username": "user1"}, "created_at": "2026-10-16T19:42:37.383462+02:00"}
]
```

---

### 4. Errors

| Status | When | Example body |
| :--- | :--- | :--- |
| `400` | Invalid data | `{"expiry_date": ["This field is required."], "count": ["Ensure this value is greater than or equal to 1."]}` |
| `401` | Missing or expired token | `{"detail": "Authentication credentials were not provided."}` |
| `404` | Not found, or a household the user doesn't belong to | `{"detail": "No Household matches the given query."}` |
| `503` | Open Food Facts unavailable (barcode lookup only) | `{"detail": "Product database is unavailable. Add the product manually."}` |

Dates are `YYYY-MM-DD`; timestamps are ISO 8601 with time zone.

---

## Web Admin Panel on PC

All database tables can be inspected, created, and modified via a web interface:

1. Open in your browser: **`https://common-pantry-api.onrender.com/admin/`**
2. Sign in with superuser credentials:
   * **Username:** `admin`
   * **Password:** *not specified*

---

## Database & Schema Migrations

* The Neon PostgreSQL database contains all tables defined in the ERD diagram (`users`, `households`, `memberships`, `categories`, `products`, `fridge_items`, `shopping_items`).
* **No local migrations are needed:** Flutter developers do not need to execute database commands or run SQL scripts.
* Database migrations run automatically during each Render build pipeline via `python manage.py migrate`.

---

## Running Tests

Tests run on a temporary database that is created and deleted automatically.
Run all commands from the `server/` folder with the venv activated.

### Regular tests (no internet needed)

```powershell
python manage.py test api
```
In these tests Open Food Facts is replaced by a fake (mock), so they are fast and always give the same result.

### Live tests (real Open Food Facts API)

These tests call the real Open Food Facts API, so they need internet and can fail if someone edits the product data there. That is why they are skipped by default. Run them on purpose:

```powershell
$env:RUN_LIVE_TESTS = "1"
python manage.py test api.tests.test_open_food_facts_live
Remove-Item Env:RUN_LIVE_TESTS
```