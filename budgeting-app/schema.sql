
CREATE TABLE budget_category (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    limit_amount REAL,
    spent_amount REAL,
    status TEXT,
    plan_id INTEGER,
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);

DROP TABLE IF EXISTS budget_plans;
CREATE TABLE budget_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    start_date TEXT,
    end_date TEXT,
    total_amount REAL,
    status TEXT
    );


CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT,
    amount REAL,
    date TEXT,
    category_id INTEGER,
    plan_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES budget_category(id),
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);

