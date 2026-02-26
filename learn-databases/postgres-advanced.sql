-- ============================================
-- ADVANCED SQL FOR SENIOR BACKEND ENGINEERS
-- ============================================
-- Prerequisite: Run postgres.sql first (schema + sample data).
-- This file adds topics beyond the 100-questions file.

-- ============================================
-- 1. LATERAL JOINS
-- ============================================
-- LATERAL allows the right side to reference columns from the left side (like a correlated subquery per row).

-- Top 2 orders per customer (LATERAL is cleaner than correlated subquery)
SELECT c.customer_id, c.first_name, o.order_id, o.order_date, o.total_amount
FROM customers c
CROSS JOIN LATERAL (
    SELECT order_id, order_date, total_amount
    FROM orders
    WHERE customer_id = c.customer_id
    ORDER BY order_date DESC
    LIMIT 2
) o;

-- Per department: show the highest-paid employee and their salary
SELECT d.dept_name, e.first_name, e.last_name, e.salary
FROM departments d
CROSS JOIN LATERAL (
    SELECT first_name, last_name, salary
    FROM employees
    WHERE dept_id = d.dept_id
    ORDER BY salary DESC NULLS LAST
    LIMIT 1
) e;

-- LEFT JOIN LATERAL (include departments with no employees)
SELECT d.dept_name, e.first_name, e.salary
FROM departments d
LEFT JOIN LATERAL (
    SELECT first_name, salary FROM employees WHERE dept_id = d.dept_id ORDER BY salary DESC LIMIT 1
) e ON true;


-- ============================================
-- 2. DISTINCT ON (PostgreSQL-specific)
-- ============================================
-- Return distinct rows by a key; which row is chosen is controlled by ORDER BY.

-- One row per department: the highest-paid employee
SELECT DISTINCT ON (dept_id) emp_id, first_name, last_name, dept_id, salary
FROM employees
ORDER BY dept_id, salary DESC NULLS LAST;

-- Most recent order per customer
SELECT DISTINCT ON (customer_id) order_id, customer_id, order_date, total_amount
FROM orders
ORDER BY customer_id, order_date DESC;

-- First order (by id) per status
SELECT DISTINCT ON (status) order_id, customer_id, order_date, status
FROM orders
ORDER BY status, order_id;


-- ============================================
-- 3. GROUPING SETS, CUBE, ROLLUP
-- ============================================
-- Multiple levels of aggregation in one query.

-- GROUPING SETS: totals by (dept), by (location), and overall
SELECT d.dept_name, d.location, COUNT(e.emp_id) AS cnt, SUM(e.salary) AS total_sal
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY GROUPING SETS (
    (d.dept_name, d.location),
    (d.dept_name),
    (d.location),
    ()
);

-- ROLLUP: hierarchy (dept+location), then (dept), then grand total
SELECT d.dept_name, d.location, COUNT(e.emp_id) AS cnt
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY ROLLUP (d.dept_name, d.location);

-- CUBE: all combinations of dimensions
SELECT status, DATE_TRUNC('month', order_date) AS month, COUNT(*), SUM(total_amount)
FROM orders
GROUP BY CUBE (status, DATE_TRUNC('month', order_date));

-- GROUPING() identifies which dimension is aggregated (0 = real value, 1 = rolled up)
SELECT 
    d.dept_name, 
    d.location,
    GROUPING(d.dept_name) AS dept_rolled_up,
    GROUPING(d.location) AS loc_rolled_up,
    COUNT(e.emp_id) AS cnt
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY ROLLUP (d.dept_name, d.location);


-- ============================================
-- 4. WINDOW FRAMES: ROWS vs RANGE vs GROUPS
-- ============================================

-- ROWS: physical rows (e.g. previous 2 rows)
SELECT order_id, order_date, total_amount,
    AVG(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS avg_rows
FROM orders;

-- RANGE: logical range (e.g. same month)
SELECT order_id, order_date, total_amount,
    SUM(total_amount) OVER (ORDER BY order_date RANGE BETWEEN '1 month' PRECEDING AND CURRENT ROW) AS sum_same_month
FROM orders;

-- GROUPS (PG 11+): peer groups
SELECT order_id, status, total_amount,
    COUNT(*) OVER (ORDER BY status GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW) AS count_groups
FROM orders;

-- EXCLUDE in frame: current row vs previous only
SELECT order_id, total_amount,
    SUM(total_amount) OVER (ORDER BY order_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running,
    SUM(total_amount) OVER (ORDER BY order_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS running_exclude_current
FROM orders;


-- ============================================
-- 5. EXPLAIN AND EXPLAIN ANALYZE
-- ============================================
-- Critical for tuning: see plan, costs, and actual execution.

EXPLAIN (FORMAT TEXT) SELECT * FROM employees WHERE dept_id = 1;
EXPLAIN (COSTS, SETTINGS) SELECT e.*, d.dept_name FROM employees e JOIN departments d ON e.dept_id = d.dept_id;
-- EXPLAIN (ANALYZE, BUFFERS) SELECT ...;  -- run real query, show buffers (requires execution)


-- ============================================
-- 6. INDEXES: Types and when to use
-- ============================================
-- Run after postgres.sql; these create indexes on existing tables.

-- B-tree (default): equality and range, ORDER BY
CREATE INDEX IF NOT EXISTS idx_employees_dept_salary ON employees (dept_id, salary DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_date ON orders (customer_id, order_date);

-- Partial index: only index rows that match condition (e.g. active orders)
CREATE INDEX IF NOT EXISTS idx_orders_pending ON orders (customer_id, order_date) WHERE status = 'pending';

-- Expression index: index on computed value
CREATE INDEX IF NOT EXISTS idx_employees_hire_year ON employees ((EXTRACT(YEAR FROM hire_date)));

-- Covering index (INCLUDE): index-only scan
CREATE INDEX IF NOT EXISTS idx_orders_customer_cover ON orders (customer_id) INCLUDE (order_date, total_amount, status);

-- GIN: for arrays, jsonb, full-text (see sections below)
-- BRIN: for very large, naturally ordered tables (e.g. time series)


-- ============================================
-- 7. TRANSACTIONS AND ISOLATION
-- ============================================

-- Explicit transaction
BEGIN;
-- UPDATE employees SET salary = salary * 1.05 WHERE dept_id = 1;
-- SELECT * FROM employees WHERE dept_id = 1;
-- COMMIT;   -- or ROLLBACK;

-- Isolation level (default is READ COMMITTED)
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Savepoints for partial rollback
-- BEGIN;
-- UPDATE employees SET salary = 0 WHERE emp_id = 1;
-- SAVEPOINT before_more;
-- UPDATE employees SET salary = 0 WHERE emp_id = 2;
-- ROLLBACK TO SAVEPOINT before_more;  -- undo only second update
-- COMMIT;


-- ============================================
-- 8. ROW-LEVEL LOCKING (SELECT FOR UPDATE / FOR SHARE)
-- ============================================
-- Use in transactions to avoid lost updates or to lock rows for read consistency.

-- Lock rows for update (block other UPDATE/DELETE until you commit)
-- BEGIN;
-- SELECT * FROM orders WHERE order_id = 1 FOR UPDATE;
-- UPDATE orders SET status = 'shipped' WHERE order_id = 1;
-- COMMIT;

-- FOR UPDATE SKIP LOCKED: dequeue pattern (skip already-locked rows)
-- SELECT * FROM orders WHERE status = 'pending' ORDER BY order_date FOR UPDATE SKIP LOCKED LIMIT 5;

-- FOR SHARE: allow others to read but not change (shared lock)
-- SELECT * FROM employees WHERE dept_id = 1 FOR SHARE;


-- ============================================
-- 9. JSON/JSONB
-- ============================================
-- Add a JSONB column for flexible metadata (optional; create and use).

ALTER TABLE orders ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

UPDATE orders SET metadata = '{"source": "web", "campaign": "summer2024"}'::jsonb WHERE order_id = 1;
UPDATE orders SET metadata = '{"source": "mobile", "version": 2}'::jsonb WHERE order_id = 2;

-- Operators: -> (json), ->> (text), #>, #>>
SELECT order_id, metadata->'source' AS source_json, metadata->>'source' AS source_text FROM orders WHERE metadata != '{}';

-- Path: metadata->'nested'->'key'
-- Containment: @>, ? (key exists), ?| (any key), ?& (all keys)
SELECT * FROM orders WHERE metadata @> '{"source": "web"}';
SELECT * FROM orders WHERE metadata ? 'campaign';

-- jsonb_path_query (PG 12+)
-- SELECT jsonb_path_query_first(metadata, '$.campaign') FROM orders WHERE order_id = 1;

-- GIN index for JSONB (for @>, ?, ?|, ?&)
CREATE INDEX IF NOT EXISTS idx_orders_metadata_gin ON orders USING GIN (metadata);


-- ============================================
-- 10. ARRAYS
-- ============================================
-- Add array column and use ANY, ALL, unnest.

ALTER TABLE products ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
UPDATE products SET tags = ARRAY['bestseller', 'sale'] WHERE product_id = 1;
UPDATE products SET tags = ARRAY['new'] WHERE product_id = 2;

-- Containment: @>, && (overlap), <@ (contained by)
SELECT * FROM products WHERE tags @> ARRAY['sale'];
SELECT * FROM products WHERE tags && ARRAY['new', 'sale'];

-- ANY / ALL
SELECT * FROM products WHERE 'sale' = ANY(tags);
SELECT * FROM products WHERE NOT ('discontinued' = ANY(COALESCE(tags, ARRAY[]::text[])));

-- unnest: expand array to rows
SELECT product_id, product_name, unnest(tags) AS tag FROM products WHERE array_length(tags, 1) > 0;

-- array_agg: build array from rows
SELECT customer_id, array_agg(order_id ORDER BY order_date) AS order_ids FROM orders GROUP BY customer_id;


-- ============================================
-- 11. FULL-TEXT SEARCH
-- ============================================

-- tsvector: normalized searchable document; tsquery: query
SELECT to_tsvector('english', product_name) AS doc FROM products WHERE product_id = 1;
SELECT to_tsquery('english', 'laptop | phone');

-- Match: @@
SELECT product_id, product_name FROM products
WHERE to_tsvector('english', product_name) @@ to_tsquery('english', 'laptop | book');

-- Add stored tsvector column and GIN index (production pattern)
ALTER TABLE products ADD COLUMN IF NOT EXISTS search_vec tsvector
    GENERATED ALWAYS AS (to_tsvector('english', product_name)) STORED;
CREATE INDEX IF NOT EXISTS idx_products_search ON products USING GIN (search_vec);

SELECT product_id, product_name FROM products WHERE search_vec @@ to_tsquery('english', 'guide');

-- Rank results
SELECT product_id, product_name, ts_rank(search_vec, to_tsquery('english', 'book')) AS rank
FROM products
WHERE search_vec @@ to_tsquery('english', 'book')
ORDER BY rank DESC;


-- ============================================
-- 12. RECURSIVE CTE: SEARCH and CYCLE
-- ============================================
-- Path from root to leaf and cycle detection.

WITH RECURSIVE hierarchy AS (
    SELECT emp_id, first_name, manager_id, 1 AS level, ARRAY[emp_id] AS path
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.first_name, e.manager_id, h.level + 1, h.path || e.emp_id
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.emp_id
)
SELECT * FROM hierarchy ORDER BY path;

-- SEARCH DEPTH FIRST / BREADTH FIRST (PG 14+)
-- WITH RECURSIVE h AS (...)
-- SEARCH DEPTH FIRST BY emp_id SET ord
-- CYCLE emp_id SET is_cycle USING path
-- SELECT * FROM h;


-- ============================================
-- 13. KEYSET (CURSOR) PAGINATION
-- ============================================
-- Stable, efficient pagination without OFFSET (which gets slower on large tables).

-- "Next page" after order_id=5, order_date='2024-01-20'
SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE (order_date, order_id) < ('2024-01-20'::date, 5)
ORDER BY order_date DESC, order_id DESC
LIMIT 5;


-- ============================================
-- 14. UPSERT and WRITABLE CTEs
-- ============================================

-- INSERT ... ON CONFLICT DO UPDATE (upsert) with conflict target
INSERT INTO products (product_name, category_id, price, stock_quantity)
VALUES ('Wireless Mouse', 1, 39.99, 100)
ON CONFLICT (product_id) DO NOTHING;
-- If you had a UNIQUE on (product_name, category_id):
-- ON CONFLICT (product_name, category_id) DO UPDATE SET price = EXCLUDED.price, stock_quantity = products.stock_quantity + EXCLUDED.stock_quantity;

-- Writable CTE: CTE that does INSERT/UPDATE/DELETE then return
WITH inserted AS (
    INSERT INTO categories (category_name) VALUES ('Electronics Accessories') RETURNING category_id, category_name
)
SELECT * FROM inserted;


-- ============================================
-- 15. TABLE PARTITIONING (conceptual + example)
-- ============================================
-- For very large tables: split by range, list, or hash. Query planner prunes partitions.

-- Example: create partitioned table (optional; uncomment to run)
/*
CREATE TABLE orders_partitioned (
    order_id SERIAL,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_q1 PARTITION OF orders_partitioned FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE orders_2024_q2 PARTITION OF orders_partitioned FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
-- INSERT into parent goes to correct partition; SELECT with date filter prunes others.
*/


-- ============================================
-- 16. ROW-LEVEL SECURITY (RLS)
-- ============================================
-- Restrict which rows users can see/modify by policy.

-- Enable RLS on a table (policies define who sees what)
-- ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Example policy: users see only their own orders (using current_setting('app.user_id') as convention)
-- CREATE POLICY orders_own ON orders FOR ALL USING (customer_id = (current_setting('app.user_id', true))::int);

-- Force table owner to be subject to RLS too
-- ALTER TABLE orders FORCE ROW LEVEL SECURITY;


-- ============================================
-- 17. FUNCTIONS (PL/pgSQL)
-- ============================================

-- Scalar function
CREATE OR REPLACE FUNCTION employee_full_name(e employees)
RETURNS TEXT AS $$
    SELECT e.first_name || ' ' || e.last_name;
$$ LANGUAGE SQL STABLE;

SELECT employee_full_name(e.*) FROM employees e LIMIT 3;

-- Function with parameters and control flow
CREATE OR REPLACE FUNCTION dept_employee_count(p_dept_id INT)
RETURNS INT AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM employees WHERE dept_id = p_dept_id;
    RETURN cnt;
END;
$$ LANGUAGE plpgsql STABLE;

SELECT dept_employee_count(1);

-- SECURITY INVOKER vs DEFINER (definer runs with owner's rights)
-- CREATE OR REPLACE FUNCTION ... SECURITY DEFINER AS $$ ... $$;


-- ============================================
-- 18. TRIGGERS
-- ============================================
-- Auto-maintain derived state or audit.

-- Example: audit log for salary changes (table + trigger)
CREATE TABLE IF NOT EXISTS salary_audit (
    audit_id SERIAL PRIMARY KEY,
    emp_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.salary IS DISTINCT FROM NEW.salary THEN
        INSERT INTO salary_audit (emp_id, old_salary, new_salary)
        VALUES (NEW.emp_id, OLD.salary, NEW.salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_employees_salary_audit ON employees;
CREATE TRIGGER tr_employees_salary_audit
    AFTER UPDATE OF salary ON employees
    FOR EACH ROW EXECUTE FUNCTION log_salary_change();

-- Trigger fires on UPDATE of salary; inspect salary_audit after: UPDATE employees SET salary = 76000 WHERE emp_id = 1;


-- ============================================
-- 19. ADVISORY LOCKS
-- ============================================
-- Application-level locking by a numeric key (e.g. prevent duplicate job per tenant).

-- Session-level lock (blocks until acquired or timeout)
-- SELECT pg_advisory_lock(12345);
-- ... do work ...
-- SELECT pg_advisory_unlock(12345);

-- Try lock (non-blocking): returns true if acquired
-- SELECT pg_try_advisory_lock(12345);


-- ============================================
-- 20. ANTI-JOIN and SEMI-JOIN patterns
-- ============================================
-- NOT IN vs NOT EXISTS (NULLs), EXISTS for "has at least one".

-- Customers with no orders: NOT EXISTS (preferred; handles NULLs)
SELECT * FROM customers c WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- Same with NOT IN (fails if subquery returns NULL)
-- SELECT * FROM customers WHERE customer_id NOT IN (SELECT customer_id FROM orders);  -- avoid if orders.customer_id can be NULL

-- Semi-join: "customers who have at least one completed order" (EXISTS or IN)
SELECT * FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.status = 'completed');


-- ============================================
-- 21. FILTER and WITHIN GROUP
-- ============================================

-- FILTER in aggregates (already in main file; here with ORDER BY in aggregate)
SELECT 
    status,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE total_amount > 100) AS over_100
FROM orders
GROUP BY status;

-- Ordered aggregate: array_agg with ORDER BY
SELECT customer_id, array_agg(order_id ORDER BY order_date DESC) AS recent_order_ids FROM orders GROUP BY customer_id;

-- WITHIN GROUP for percentile and similar
SELECT 
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) AS p90_salary
FROM employees WHERE salary IS NOT NULL;


-- ============================================
-- 22. NULLS FIRST / NULLS LAST
-- ============================================
-- Control sort order of NULLs (important for window functions and top-N).

SELECT first_name, salary FROM employees ORDER BY salary DESC NULLS LAST LIMIT 5;


-- ============================================
-- 23. MERGE (PG 15+)
-- ============================================
-- Upsert from a source (INSERT or UPDATE based on match).

-- MERGE INTO orders AS t
-- USING (SELECT 1 AS customer_id, CURRENT_DATE AS order_date, 99.99 AS total_amount) AS s
-- ON t.customer_id = s.customer_id AND t.order_date = s.order_date
-- WHEN MATCHED THEN UPDATE SET total_amount = s.total_amount
-- WHEN NOT MATCHED THEN INSERT (customer_id, order_date, total_amount) VALUES (s.customer_id, s.order_date, s.total_amount;


-- ============================================
-- QUICK REFERENCE
-- ============================================
-- LATERAL        : correlated subquery in FROM
-- DISTINCT ON    : one row per key (PostgreSQL)
-- GROUPING SETS  : multiple GROUP BY in one query
-- ROWS/RANGE     : window frame semantics
-- EXPLAIN ANALYZE: plan + actual run
-- Partial/expr index: smaller, targeted indexes
-- FOR UPDATE/SHARE: row locking
-- JSONB @> ?     : containment, key exists
-- Arrays ANY, @> : array ops
-- tsvector @@ tsquery: full-text search
-- Keyset pagination: (col1, id) < (?, ?) ORDER BY col1 DESC, id DESC LIMIT n
-- RLS, triggers, advisory locks: concurrency and security
