# Common Pantry

Shared Fridge is a cross-platform mobile application connected to a REST API server, designed for housemates and families living together. It enables tracking fridge contents, monitoring expiration dates, minimizing food waste, and managing a shared shopping list in real time.

---

## 🛠️ Tech Stack

- **Backend:** Python 3.11+, Django, Django REST Framework (DRF)
- **Database:** PostgreSQL (Docker Compose)
- **Mobile App:** Flutter (Android / iOS)
- **Authentication:** JWT (JSON Web Tokens)
- **External APIs:** Open Food Facts API (barcode lookup cache)

---

## 🏛️ Database Schema (ERD)

The data model is centered around the `Household` entity. All fridge inventory items and shopping list entries belong strictly to a specific household, ensuring proper data isolation.

![Database ERD](docs/database_diagram.png)

### Key Architectural Decisions

1. **Data Isolation:** `FridgeItem` and `ShoppingItem` are strictly bound to `Household`. Members only access resources belonging to their active household.
2. **Catalog and Custom Dishes (`Product` & `FridgeItem`):**
   - The `Product` table holds both global store-bought items (cached from Open Food Facts, where `household_id` is `NULL`) and household-specific custom dishes (where `household_id` is set, categorized via `product_type`).
   - For quick manual additions without catalog indexing, `FridgeItem` also supports a direct fallback via `custom_name` and `category_id` (leaving `product_id` as `NULL`).
3. **Food Waste Tracking:**
   - Items are never deleted upon consumption or disposal. Instead, their `status` transitions to `eaten` or `wasted`, and `closed_at` is recorded to generate consumption and waste analytics.
4. **Performance & Constraints:**
   - A composite index on `(household_id, status, expiry_date)` enables fast querying and sorting of active items ordered by upcoming expiration dates.
   - A unique constraint on `(user_id, household_id)` inside `Membership` ensures a user cannot join the same household multiple times.

---

