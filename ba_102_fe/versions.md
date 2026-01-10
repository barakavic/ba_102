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

## version 1.2.0+4
- **Frontend**: Flutter - Version 1.2.0+4
- **Changes**:
  - **Feature**: Integrated M-Pesa SMS Transaction Parsing.
    - Added native Android `SmsReceiver` to intercept M-Pesa and Safaricom messages.
    - Implemented `MpesaParserService` to extract transaction details (Reference, Amount, Type, Recipient/Sender, Balance).
    - Added support for Safaricom airtime and data bundle purchase messages.
  - **Database**: Upgraded SQLite database to version 3.
    - Added `type`, `vendor`, `mpesa_reference`, `balance`, and `raw_sms_message` columns to the `transactions` table.
    - Implemented robust `onUpgrade` logic to handle schema migrations.
  - **Fix**: Improved SMS parsing regex to handle non-hyphenated "MPESA" messages and case-insensitive sender matching.
  - **UX**: Added snackbar notifications for newly captured SMS transactions.

## version 1.3.0+5
- **Frontend**: Flutter - Version 1.3.0+5
- **Changes**:
  - **Feature**: Enhanced Plan Details Dashboard.
    - Added **Daily Insights**: Real-time calculation of "Avg. Daily Spend" and "Safe Daily Spend" (Total Remaining / Days Left).
    - Added **Frequent Spending**: Horizontal habit tracker identifying recurring vendors and total accumulated cost.
    - Added **Category Analytics**: Toggle between List view and a custom-painted **Donut Chart** with color-coded legends.
    - Added **Expandable Top Transactions**: Shows the top 2 "budget killers" with a **Budget Impact Badge** (% of total budget).
  - **Feature**: Centralized Icon Management.
    - Created `IconService` to remove hardcoded icon mappings.
    - Added new icons including **Hospital**, **Travel**, **Gifts**, and **Subscriptions**.
    - Expanded the color palette for categories.
  - **UX**: Implemented **Pull-to-Refresh** on Plans, Plan Details, and Categories pages.
    - Integrated automatic **Re-categorization** into the refresh action to fix "Uncategorized" transactions using the latest rules.
  - **Logic**: 
    - Normalized plan dates to cover the full day (00:00:00 to 23:59:59).
    - Restricted editing of Plan Limits and Start Dates for active plans to ensure data integrity.
    - Filtered spending calculations to only include outbound payments and withdrawals (ignoring income).
  - **Fix**: Ensured "Uncategorized" category is permanently visible in the UI as a primary container.

## version 1.4.0+6
- **Frontend**: Flutter - Version 1.4.0+6
- **Major Features**:
  - **Smart Bulk Categorization**:
    - When moving a transaction, the app detects other transactions from the same vendor.
    - Prompts user to "Move All" or "Just This One".
    - Automatically saves vendor-to-category mappings for future automation.
  - **Hierarchical Categories**:
    - Implemented Parent/Child category structure (1-level deep).
    - Categories Page now shows only top-level categories with rolled-up totals.
    - Tapping a parent opens a bottom sheet with sub-categories.
    - Added "Move" functionality to re-parent categories.
  - **Plan Analytics Refactor**:
    - Created dedicated `PlanAnalyticsPage` for deep-dive charts and stats.
    - Streamlined `PlanDetailsPage` to focus on "Health at a Glance" (Budget, Daily Insights, Pacing).
  - **Test Data Engine**:
    - Added `TestDataSeeder` utility.
    - Debug button now seeds 40+ diverse transactions (Food, Utilities, Transport) for testing.
  - **Roadmap**:
    - Established internal strategic roadmap for future development.

## version 1.5.0+7
- **Frontend**: Flutter - Version 1.5.0+7
- **Major Features**:
  - **"Clarity & Insight" Dashboard**:
    - Refactored the main screen to prioritize high-level financial status.
    - Added **Total Spending Header**: Dynamic monthly spending summary with privacy support.
    - Added **Monthly Budget Summary**: Visual "Reality Check" comparing spent vs. income.
    - Added **Top Categories Row**: Highlights top 5 spending areas for the month.
    - Integrated **Spending Pulse Chart** into the GlassHeroCard.
  - **Overhauled Transactions Page**:
    - Extracted `TransactionDetailsView` for modularity.
    - Implemented **Date Grouping** (Today, Yesterday, etc.) for better readability.
    - Added **Pill-Style Category Filters** (Food, Shopping, Travel, Bills).
    - Implemented **Smart Month/Year Navigation**: Dropdown with "This Month", "Last Month", and historical months.
    - Added **Multi-Criteria Sorting**: Order by Date (Newest/Oldest) or Amount (Highest/Lowest).
  - **UX & Design**:
    - Implemented **Privacy Mode** across all dashboard widgets (hides sensitive amounts).
    - Refined glassmorphism aesthetics and typography.
    - Cleaned up `TransactionsPage` code by removing 300+ lines of redundant logic.

## version 1.6.0+8
- **Frontend**: Flutter - Version 1.6.0+8
- **Major Features**:
  - **Global Navigation Shell**:
    - Centralized the `AppBar` logic into `MainNavigation` for a persistent UI experience.
    - Implemented a **Global Navigation Drawer** ("Command Center") accessible from all main screens.
    - Added a **Global Privacy Mode Toggle** within the drawer for instant balance masking.
  - **Dynamic Dashboard**:
    - Implemented **Pull-to-Refresh** on the Home Screen to force-update M-Pesa balances and charts.
    - Integrated real-time provider invalidation: Dashboard now updates automatically when new SMS transactions are detected.
- **UX & Design**:
    - **Consolidated UI**: Removed redundant internal AppBars from Dashboard, Transactions, and Settings pages.
    - **SMS Status Migration**: Moved the SMS listening status and transaction count badge to the global AppBar for better visibility.
    - **Visual Fixes**: Resolved `GlassHeroCard` layout overflows and enhanced `SpendingPulseChart` line visibility.
- **Fixes**:
    - Fixed a critical issue where `MainNavigation` could not be instantiated as a `const` due to the `GlobalKey` requirement.
    - Restored missing historical sync methods in `SmsNotifier` and `SmsListenerService`.

## version 1.7.0+9
- **Frontend**: Flutter - Version 1.7.0+9
- **Major Features**:
  - **Online Sync Engine**:
    - Implemented `SyncService` for pushing local SQLite transactions to the PostgreSQL backend.
    - Added `clientId` (UUID) to all transactions for deduplication and sync-safety.
    - Integrated real-time sync: New SMS transactions are automatically pushed to the cloud on arrival.
    - Added manual "Sync to Cloud" trigger within the M-Pesa history sync flow.
- **Data & Infrastructure**:
    - **Database v10**: Upgraded SQLite schema to include `client_id` and `is_synced` status.
    - **Migration Logic**: Added automatic UUID generation for existing legacy transactions.
    - **API Compatibility**: Added `toJson()` mapping to ensure Flutter models match Spring Boot's expected camelCase structure.
- **Dependencies**:
    - Added `uuid` package for unique transaction identification.
## version 1.8.0+10
- **Frontend**: Flutter - Version 1.8.0+10
- **Major Features**:
  - **Robust M-Pesa Parsing**:
    - Added support for **"paid to"** and **"payment to"** transaction types (Pochi La Biashara / Direct Payments).
    - Improved name extraction regex to handle varying message formats and prevent "Unknown" descriptions.
  - **Category UI Overhaul**:
    - Replaced single "Total Spent" with dual **"RECEIVED"** (Inflow) and **"SPENT"** (Outflow) stats.
    - Applied dual-stat tracking to both the main Category Grid and Category Details pages.
  - **Transaction UI Polish**:
    - Implemented **Expandable Transaction Items** across the app.
    - Added a **Raw M-Pesa Message** view (monospace receipt style) to decode complex transactions (e.g., Equity Paybill).
    - Added color-coding (+Green/-Red) and "KES" labels to all transaction amounts for better clarity.
  - **Settings**:
    - Added a functional **Cloud Sync** toggle in the App Settings page.
- **Android Native**:
  - Fixed Kotlin null-safety issues in `MainActivity.kt`.
  - Enhanced historical SMS filtering with more keywords (`M-PESA`, `Ksh`) and added debug logging.
- **Infrastructure**:
  - **Dockerized Backend**: Full containerization of Spring Boot app and PostgreSQL database.
  - **Centralized API Config**: Created `ApiConfig.dart` for easy switching between local and remote backends.
  - **Sync Service**: Refined `SyncService` to respect user sync preferences and use the host machine's IP.