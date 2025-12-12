## version 0.1.0

## version 1.1.4
- **Frontend**: Flutter (Riverpod, SQLite, HTTP) - Version 1.1.4
- **Backend**: Java Spring Boot (PostgreSQL/SQLite) - Version 0.0.1-SNAPSHOT
- **Features**:
  - Dashboard with total budget view.
  - Budget Plans and Categories management.
  - Transaction tracking.
  - Local database (SQLite) for frontend.
  - Backend API structure with Spring Boot.

## version 1.1.5+3
- **Frontend**: Flutter - Version 1.1.5+3
- **Changes**:
  - **Fix**: Corrected JSON mapping for `Category` model to use snake_case keys (`limit_amount`, `spent_amount`, `plan_id`) matching the backend/database schema.
  - **Feature**: Added navigation to `PlansFormPage` via the Floating Action Button on the Plans page.
  - **Change**: Switched `plansProvider` to fetch data from the local SQLite database (`PlanLs`) instead of the online API, enabling offline-first functionality.