
CREATE TABLE budget_category (
    id INTEGER NOT NULL,
    name TEXT,
    limit_amount REAL,
    spent_amount REAL,
    plan_id INTEGER,
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);
CREATE TABLE budget_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    end_date TEXT,
    name TEXT,
    start_date TEXT,
    total_amount REAL,
    status TEXT
    );


CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL,
    date TEXT,
    description TEXT,
    category_id INTEGER,
    plan_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES budget_category(id),
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);
