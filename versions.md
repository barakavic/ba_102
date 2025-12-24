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
  - **UX**: Implemented **Pull-to-Refresh** on Plans, Plan Details, and Categories pages.
    - Integrated automatic **Re-categorization** into the refresh action to fix "Uncategorized" transactions using the latest rules.
  - **Logic**: 
    - Normalized plan dates to cover the full day (00:00:00 to 23:59:59).
    - Restricted editing of Plan Limits and Start Dates for active plans to ensure data integrity.
    - Filtered spending calculations to only include outbound payments and withdrawals (ignoring income).
  - **Fix**: Ensured "Uncategorized" category is permanently visible in the UI as a primary container.