# 🎓 Ba_102 Backend: The "Gross Detail" Explainer

Welcome to the deep dive! This document explains exactly what we changed, why we changed it, and how it works. Think of this as your "Backend Bible" for the January launch.

---

## 🏗 1. Feature-First Architecture
**What we did:** We moved from "Package-by-Layer" to "Package-by-Feature."

*   **Old Way (Dated):** You had `controllers`, `services`, and `repositories` folders. To change one thing about "Categories," you had to jump between 4 different folders.
*   **New Way (Modern):** Everything related to a feature is in one folder (e.g., `features/categories`).
*   **The Lesson:** This makes the app **modular**. If you want to add a "Mini CFO" AI feature later, you just create a `features/intelligence` folder. It doesn't clutter the rest of the app.

---

## 🛡 2. The "Fortress" Security Layer
We implemented three major defenses to protect your financial data.

### A. SQL Injection (SQLI) Prevention
*   **The Threat:** A hacker enters `' OR 1=1 --` into a text field to trick the database into showing everyone's data.
*   **The Fix:** We use **Spring Data JPA**. Instead of writing raw strings like `SELECT * FROM users WHERE name = '` + name + `'`, JPA uses **Prepared Statements**.
*   **How it works:** It sends the query template to the DB first, then sends the data separately. The DB treats the data as *just text*, never as a command.

### B. CORS (Cross-Origin Resource Sharing)
*   **The Threat:** A malicious website tries to make a request to your backend while you are logged in, stealing your data.
*   **The Fix:** We configured a `CorsConfigurationSource`.
*   **The Lesson:** It tells the browser: "Only trust requests coming from these specific places." Right now it's open for development, but we will lock it down to your mobile app's ID soon.

### C. XSS (Cross-Site Scripting)
*   **The Threat:** Someone injects a `<script>` tag into a transaction description that steals your session token when you view it.
*   **The Fix:** 
    1.  **Security Headers:** We added headers that tell the browser "Don't trust any scripts unless they come from my own server."
    2.  **CSP (Content Security Policy):** This is like a bouncer at a club. It only allows scripts from the "Guest List" (your own app) to run.

---

## 🔄 3. The Synchronization Engine
This is how we handle the "Bankrolling" from your phone to the server.

### The `clientId` (UUID)
*   **The Problem:** If your phone is offline and you buy coffee, your phone gives it ID `1`. If your server already has a transaction with ID `1`, they collide.
*   **The Fix:** Your phone generates a **UUID** (a long random string like `550e8400-e29b...`). 
*   **The Lesson:** The chance of two UUIDs being the same is practically zero. The server uses this `clientId` to check if it already has the record.

### The `/sync` Endpoints
*   **Logic:** Instead of just "Create," these endpoints do an **Upsert** (Update + Insert).
*   **Process:** 
    1.  Phone sends data.
    2.  Server looks for `clientId`.
    3.  Found? Update the existing record.
    4.  Not found? Create a new one.

---

## 📊 4. Database Refactor (PostgreSQL)
We moved from a "Tree" structure to a "Flat" structure.

*   **Old:** Category -> belongs to -> Plan. (Rigid)
*   **New:** Category and Plan are independent. **Transaction** is the glue that holds them together.
*   **Why:** This allows you to see how much you spent on "Food" across *all* time, not just within one month's plan.

---

## 🚀 5. The January "Free" Launch Strategy
Since Oracle Cloud needs a card balance, we are using the **Zero-Card Stack**:
1.  **Neon.tech**: Free PostgreSQL.
2.  **Render.com**: Free Spring Boot hosting.
3.  **SSL/TLS**: Render provides this automatically. It encrypts your data so if someone "sniffs" your Wi-Fi, they just see gibberish, not your M-Pesa balances.

---

## 🔑 6. JWT Authentication: The "Digital Passport"
**What we did:** We moved from "Open Doors" to a secure, token-based system.

### How it works:
1.  **Login**: You send your username/password to `/api/auth/login`.
2.  **The Token**: The server verifies you and gives you a **JWT (JSON Web Token)**.
3.  **The Passport**: For every future request (like syncing transactions), your phone sends this token in the header: `Authorization: Bearer <token>`.
4.  **The Filter**: We added a `JwtAuthenticationFilter` that intercepts every request, checks the token's signature, and only lets it through if it's valid.

### Why JWT?
*   **Stateless**: The server doesn't need to remember who is logged in (no "sessions"). The token itself contains all the proof.
*   **Secure**: The token is signed with a `SecretKey`. If a hacker changes even one letter in the token, the signature becomes invalid.

---

**Next Lesson:** Connecting the Flutter Frontend to this new Secure Backend.
