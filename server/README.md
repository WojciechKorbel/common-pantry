# Backend & API Guide – Common Pantry

The backend application is fully deployed and operational in the cloud. **There is no need to run Python, Docker, or PostgreSQL locally.**

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

### 1. Available Endpoints (for Sprint 1)

| Method | Endpoint | Authorization | Description / Goal                                                                                 |
| :--- | :--- | :--- |:---------------------------------------------------------------------------------------------------|
| **GET** | `/` | None | **Health Check:** Returns API operational status (`{"status": "ok", "app": "Common Pantry API"}`). |
| **POST** | `/api/auth/token/` | None | **Login:** Accepts `username` and `password`, returns JWT `access` and `refresh` tokens.           |
| **POST** | `/api/auth/token/refresh/` | None | **Refresh Token:** Accepts `{ "refresh": "..." }`, returns a fresh `access` token.                 |
| **GET** | `/api/fridge/items/` | `Bearer <access>` | **Fridge Items:** Returns active items sorted by `expiry_date` ascending.                          |
| **POST** | `/api/fridge/items/` | `Bearer <access>` | **Add Fridge Item:** Adds a new item assigned to the authenticated user.                           |

---

### 2. Request & Response Examples

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
*Store the `access` token on the device (e.g., using `flutter_secure_storage`).*

#### B. Fetching Fridge Items (`GET /api/fridge/items/`)
Include the authorization header for protected endpoints:
```http
Authorization: Bearer <your_access_token>
```

Optional query parameter to filter by household:
```http
GET [https://common-pantry-api.onrender.com/api/fridge/items/?household_id=1](https://common-pantry-api.onrender.com/api/fridge/items/?household_id=1)
```

Response (`200 OK`):
```json
[
  {
    "id": 1,
    "household": 1,
    "custom_name": "Milk 3.2%",
    "quantity": "1.00",
    "unit": "l",
    "expiry_date": "2026-10-15",
    "status": "active"
  }
]
```

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