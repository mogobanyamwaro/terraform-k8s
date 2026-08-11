# SQL Engineer Interview Questions and Answers

Practice questions and answers for SQL engineer interviews using a PostgreSQL ecommerce schema.

## Setup

Connect to the local PostgreSQL instance:

| Setting | Value |
| --- | --- |
| Host | `localhost` |
| Port | `5432` |
| Database | `ecommerce` |
| User | `postgres` |
| Password | `1234` |

```bash
docker exec -it ecommerce psql -U postgres -d ecommerce
```

Or load the schema from the shell:

```bash
docker exec -i ecommerce psql -U postgres -d ecommerce < learn-databases/postgres.sql
```

## Sample schema and data

Run this first to create sample tables and seed data. The same script is also available as [`postgres.sql`](postgres.sql).

```sql
-- Run this first to create sample tables

-- Drop tables if they exist
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS salaries CASCADE;

-- Create departments table
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

-- Create employees table
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE,
    salary DECIMAL(10,2),
    manager_id INT REFERENCES employees(emp_id),
    dept_id INT REFERENCES departments(dept_id)
);

-- Create salaries table (for historical salary data)
CREATE TABLE salaries (
    salary_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id),
    salary DECIMAL(10,2),
    from_date DATE,
    to_date DATE
);

-- Create customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    city VARCHAR(50),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create categories table
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

-- Create products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INT REFERENCES categories(category_id),
    price DECIMAL(10,2),
    stock_quantity INT DEFAULT 0
);

-- Create orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending'
);

-- Create order_items table
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    unit_price DECIMAL(10,2)
);

-- ============================================
-- INSERT SAMPLE DATA
-- ============================================

INSERT INTO departments (dept_name, location) VALUES
('Engineering', 'New York'),
('Marketing', 'Los Angeles'),
('Sales', 'Chicago'),
('HR', 'New York'),
('Finance', 'Boston');

INSERT INTO employees (first_name, last_name, email, hire_date, salary, manager_id, dept_id) VALUES
('John', 'Smith', 'john.smith@company.com', '2020-01-15', 75000, NULL, 1),
('Jane', 'Doe', 'jane.doe@company.com', '2019-03-20', 85000, 1, 1),
('Bob', 'Johnson', 'bob.johnson@company.com', '2021-06-01', 65000, 1, 1),
('Alice', 'Williams', 'alice.williams@company.com', '2018-09-10', 95000, NULL, 2),
('Charlie', 'Brown', 'charlie.brown@company.com', '2022-02-14', 55000, 4, 2),
('Diana', 'Davis', 'diana.davis@company.com', '2020-11-30', 72000, 4, 3),
('Eve', 'Miller', 'eve.miller@company.com', '2019-07-22', 68000, NULL, 4),
('Frank', 'Wilson', 'frank.wilson@company.com', '2021-04-05', 78000, 7, 4),
('Grace', 'Moore', 'grace.moore@company.com', '2017-12-01', 110000, NULL, 5),
('Henry', 'Taylor', 'henry.taylor@company.com', '2023-01-10', 52000, 9, 5),
('Ivy', 'Anderson', 'ivy.anderson@company.com', '2020-08-15', 71000, 1, 1),
('Jack', 'Thomas', 'jack.thomas@company.com', '2019-05-20', NULL, 4, 3);

INSERT INTO salaries (emp_id, salary, from_date, to_date) VALUES
(1, 60000, '2020-01-15', '2021-01-14'),
(1, 70000, '2021-01-15', '2022-01-14'),
(1, 75000, '2022-01-15', NULL),
(2, 75000, '2019-03-20', '2020-03-19'),
(2, 85000, '2020-03-20', NULL),
(3, 65000, '2021-06-01', NULL);

INSERT INTO customers (first_name, last_name, email, city, country) VALUES
('Michael', 'Scott', 'michael@dundermifflin.com', 'Scranton', 'USA'),
('Dwight', 'Schrute', 'dwight@dundermifflin.com', 'Scranton', 'USA'),
('Jim', 'Halpert', 'jim@dundermifflin.com', 'Scranton', 'USA'),
('Pam', 'Beesly', 'pam@dundermifflin.com', 'Scranton', 'USA'),
('Angela', 'Martin', 'angela@dundermifflin.com', 'Scranton', 'USA'),
('Kevin', 'Malone', 'kevin@dundermifflin.com', 'Scranton', 'USA'),
('Oscar', 'Martinez', 'oscar@dundermifflin.com', 'Los Angeles', 'USA'),
('Stanley', 'Hudson', 'stanley@dundermifflin.com', 'Chicago', 'USA'),
('Phyllis', 'Vance', 'phyllis@dundermifflin.com', 'Chicago', 'USA'),
('Andy', 'Bernard', 'andy@dundermifflin.com', 'Stamford', 'USA'),
('Emma', 'Watson', 'emma@example.com', 'London', 'UK'),
('Tom', 'Hardy', 'tom@example.com', 'London', 'UK');

INSERT INTO categories (category_name) VALUES
('Electronics'),
('Clothing'),
('Books'),
('Home & Garden'),
('Sports');

INSERT INTO products (product_name, category_id, price, stock_quantity) VALUES
('Laptop', 1, 999.99, 50),
('Smartphone', 1, 699.99, 100),
('Headphones', 1, 149.99, 200),
('T-Shirt', 2, 29.99, 500),
('Jeans', 2, 59.99, 300),
('SQL Guide Book', 3, 49.99, 150),
('Data Science Handbook', 3, 39.99, 100),
('Garden Tools Set', 4, 89.99, 75),
('Basketball', 5, 24.99, 200),
('Tennis Racket', 5, 79.99, 80);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15', 1149.98, 'completed'),
(2, '2024-01-16', 699.99, 'completed'),
(3, '2024-01-17', 89.98, 'completed'),
(1, '2024-01-20', 149.99, 'completed'),
(4, '2024-02-01', 999.99, 'pending'),
(5, '2024-02-05', 59.99, 'shipped'),
(6, '2024-02-10', 239.97, 'completed'),
(7, '2024-02-15', 49.99, 'cancelled'),
(8, '2024-02-20', 1699.98, 'completed'),
(3, '2024-03-01', 129.98, 'pending'),
(9, '2024-03-05', 79.99, 'shipped'),
(10, '2024-03-10', 449.97, 'completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99),
(1, 3, 1, 149.99),
(2, 2, 1, 699.99),
(3, 4, 2, 29.99),
(3, 9, 1, 24.99),
(4, 3, 1, 149.99),
(5, 1, 1, 999.99),
(6, 5, 1, 59.99),
(7, 3, 1, 149.99),
(7, 6, 1, 49.99),
(7, 7, 1, 39.99),
(8, 6, 1, 49.99),
(9, 1, 1, 999.99),
(9, 2, 1, 699.99),
(10, 4, 1, 29.99),
(10, 6, 1, 49.99),
(10, 8, 1, 89.99),
(11, 10, 1, 79.99),
(12, 3, 3, 149.99);
```

This guide uses **PostgreSQL**, based on features such as `SERIAL`, materialized views, PL/pgSQL functions, procedures, and event triggers.

## Table of contents

- [1. Database fundamentals](#1-database-fundamentals)
- [2. ACID and transactions](#2-acid-and-transactions)
- [3. Basic query questions](#3-basic-query-questions)
- [4. Aggregate functions and grouping](#4-aggregate-functions-and-grouping)
- [5. Joins](#5-joins)
- [6. Subqueries and CTEs](#6-subqueries-and-ctes)
- [7. Window functions](#7-window-functions)
- [8. Data-quality and audit questions](#8-data-quality-and-audit-questions)
- [9. Views](#9-views)
- [10. Materialized views](#10-materialized-views)
- [11. Functions](#11-functions)
- [12. Stored procedures](#12-stored-procedures)
- [13. Triggers](#13-triggers)
- [14. Event triggers](#14-event-triggers)
- [15. Constraints](#15-constraints)
- [16. Indexes and performance](#16-indexes-and-performance)
- [17. Data manipulation](#17-data-manipulation)
- [18. Schema-design improvement questions](#18-schema-design-improvement-questions)
- [19. Security questions](#19-security-questions)
- [20. Advanced practical challenges](#20-advanced-practical-challenges)
- [21. Rapid-fire interview questions](#21-rapid-fire-interview-questions)
- [Recommended live interview exercises](#recommended-live-interview-exercises)

---

# 1. Database fundamentals

## 1. What is SQL?

SQL stands for **Structured Query Language**. It is used to:

* Define database structures with DDL.
* Read and manipulate data with DML.
* Control transactions with TCL.
* Manage permissions with DCL.

Examples:

```sql
-- DDL
CREATE TABLE departments (...);

-- DML
SELECT * FROM employees;
INSERT INTO departments (dept_name) VALUES ('IT');
UPDATE employees SET salary = 80000 WHERE emp_id = 1;
DELETE FROM employees WHERE emp_id = 1;

-- TCL
BEGIN;
COMMIT;
ROLLBACK;

-- DCL
GRANT SELECT ON employees TO reporting_user;
```

---

## 2. What is the difference between DDL and DML?

**DDL** changes the database structure:

```sql
CREATE TABLE
ALTER TABLE
DROP TABLE
TRUNCATE TABLE
```

**DML** changes or retrieves the data:

```sql
SELECT
INSERT
UPDATE
DELETE
```

---

## 3. What is a primary key?

A primary key uniquely identifies each row.

```sql
emp_id SERIAL PRIMARY KEY
```

Properties:

* Must be unique.
* Cannot be `NULL`.
* A table has one primary key, though it can contain multiple columns.

---

## 4. What is a foreign key?

A foreign key creates a relationship between tables.

```sql
dept_id INT REFERENCES departments(dept_id)
```

This prevents an employee from referencing a department that does not exist.

---

## 5. What is a self-referencing foreign key?

It is a foreign key that references the same table.

In your `employees` table:

```sql
manager_id INT REFERENCES employees(emp_id)
```

An employee's manager is also another employee.

---

## 6. What is referential integrity?

Referential integrity ensures relationships between tables remain valid.

For example, PostgreSQL should not allow:

```sql
INSERT INTO employees (
    first_name,
    last_name,
    dept_id
)
VALUES (
    'Test',
    'Employee',
    999
);
```

This fails because department `999` does not exist.

---

## 7. What is normalization?

Normalization organizes data to reduce duplication and inconsistent data.

Your schema is reasonably normalized:

* Department details are stored in `departments`.
* Employees reference departments using `dept_id`.
* Products reference categories using `category_id`.
* Orders and products have a many-to-many relationship through `order_items`.

---

## 8. Explain first, second, and third normal form

### First Normal Form — 1NF

Each column contains one atomic value, and each row is unique.

Bad design:

```text
product_ids = "1,2,3"
```

Good design:

```text
order_items
-----------
order_id
product_id
quantity
```

### Second Normal Form — 2NF

The table must be in 1NF, and every non-key column must depend on the whole primary key.

This mainly matters with composite primary keys.

### Third Normal Form — 3NF

The table must be in 2NF, and non-key columns should not depend on other non-key columns.

For example, storing this in `employees` would create duplication:

```text
emp_id | dept_id | dept_name | dept_location
```

Instead, `dept_name` and `location` belong in `departments`.

---

# 2. ACID and transactions

## 9. What does ACID mean?

### Atomicity

A transaction succeeds completely or fails completely.

### Consistency

A transaction moves the database from one valid state to another.

### Isolation

Concurrent transactions should not incorrectly interfere with each other.

### Durability

Once committed, data remains saved even after a crash.

---

## 10. Show an atomic transaction using the order tables

Suppose a customer buys two laptops. You need to:

1. Create the order.
2. Create an order item.
3. Reduce stock.

```sql
BEGIN;

INSERT INTO orders (
    customer_id,
    order_date,
    total_amount,
    status
)
VALUES (
    1,
    CURRENT_DATE,
    1999.98,
    'pending'
)
RETURNING order_id;
```

Assuming the returned ID is `13`:

```sql
INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    unit_price
)
VALUES (
    13,
    1,
    2,
    999.99
);

UPDATE products
SET stock_quantity = stock_quantity - 2
WHERE product_id = 1
  AND stock_quantity >= 2;

COMMIT;
```

If something fails:

```sql
ROLLBACK;
```

In a real application, the returned `order_id` should be captured automatically rather than manually assumed.

---

## 11. What is a transaction savepoint?

A savepoint allows part of a transaction to be rolled back.

```sql
BEGIN;

UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 1;

SAVEPOINT stock_updated;

INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    unit_price
)
VALUES (
    999,
    1,
    1,
    999.99
);

ROLLBACK TO SAVEPOINT stock_updated;

COMMIT;
```

---

## 12. What transaction isolation levels does PostgreSQL support?

PostgreSQL supports:

* `READ COMMITTED`
* `REPEATABLE READ`
* `SERIALIZABLE`

PostgreSQL accepts `READ UNCOMMITTED`, but internally treats it as `READ COMMITTED`.

Set an isolation level:

```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT *
FROM products
WHERE product_id = 1;

COMMIT;
```

---

## 13. What problems can occur with concurrent transactions?

### Dirty read

Reading uncommitted changes from another transaction.

PostgreSQL prevents dirty reads.

### Non-repeatable read

Reading the same row twice and receiving different values because another transaction updated it.

### Phantom read

Running the same condition twice and seeing additional or missing rows.

### Lost update

Two transactions update the same value, and one overwrites the other.

---

## 14. How do you lock a row before updating stock?

```sql
BEGIN;

SELECT stock_quantity
FROM products
WHERE product_id = 1
FOR UPDATE;

UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 1;

COMMIT;
```

`FOR UPDATE` prevents another transaction from modifying the selected row until the transaction finishes.

---

## 15. How would you safely prevent negative stock?

Use both a constraint and a conditional update.

```sql
ALTER TABLE products
ADD CONSTRAINT chk_stock_non_negative
CHECK (stock_quantity >= 0);
```

Then:

```sql
UPDATE products
SET stock_quantity = stock_quantity - 5
WHERE product_id = 1
  AND stock_quantity >= 5;
```

The application must verify that exactly one row was updated.

---

# 3. Basic query questions

## 16. Find all employees

```sql
SELECT *
FROM employees;
```

---

## 17. Return selected employee columns

```sql
SELECT
    emp_id,
    first_name,
    last_name,
    salary
FROM employees;
```

---

## 18. Find employees earning more than 70,000

```sql
SELECT
    emp_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > 70000;
```

---

## 19. Find employees whose salary is missing

```sql
SELECT *
FROM employees
WHERE salary IS NULL;
```

Do not use:

```sql
WHERE salary = NULL;
```

`NULL` must be checked using `IS NULL` or `IS NOT NULL`.

---

## 20. Find employees hired between 2020 and 2022

```sql
SELECT *
FROM employees
WHERE hire_date >= DATE '2020-01-01'
  AND hire_date < DATE '2023-01-01';
```

Using a half-open range is usually safer than manipulating the end date.

---

## 21. Find products priced between 50 and 200

```sql
SELECT *
FROM products
WHERE price BETWEEN 50 AND 200
ORDER BY price DESC;
```

`BETWEEN` includes both boundaries.

---

## 22. Find customers from London or Chicago

```sql
SELECT *
FROM customers
WHERE city IN ('London', 'Chicago');
```

---

## 23. Find employees whose last name starts with D

```sql
SELECT *
FROM employees
WHERE last_name LIKE 'D%';
```

For case-insensitive matching in PostgreSQL:

```sql
SELECT *
FROM employees
WHERE last_name ILIKE 'd%';
```

---

## 24. Return the five highest-paid employees

```sql
SELECT
    first_name,
    last_name,
    salary
FROM employees
WHERE salary IS NOT NULL
ORDER BY salary DESC
LIMIT 5;
```

Expected top employees include:

1. Grace Moore — 110,000
2. Alice Williams — 95,000
3. Jane Doe — 85,000
4. Frank Wilson — 78,000
5. John Smith — 75,000

---

## 25. Replace a missing salary with zero in the output

```sql
SELECT
    first_name,
    last_name,
    COALESCE(salary, 0) AS salary
FROM employees;
```

`COALESCE` returns the first non-`NULL` value.

---

## 26. Create a calculated product stock value

```sql
SELECT
    product_name,
    price,
    stock_quantity,
    price * stock_quantity AS stock_value
FROM products;
```

---

# 4. Aggregate functions and grouping

## 27. Count all employees

```sql
SELECT COUNT(*) AS employee_count
FROM employees;
```

Expected result:

```text
12
```

---

## 28. Explain `COUNT(*)` versus `COUNT(salary)`

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(salary) AS employees_with_salary
FROM employees;
```

* `COUNT(*)` counts every row.
* `COUNT(salary)` ignores rows where salary is `NULL`.

Expected results:

```text
total_rows = 12
employees_with_salary = 11
```

---

## 29. Find the minimum, maximum, and average salary

```sql
SELECT
    MIN(salary) AS minimum_salary,
    MAX(salary) AS maximum_salary,
    ROUND(AVG(salary), 2) AS average_salary
FROM employees;
```

`AVG` ignores `NULL` salaries.

---

## 30. Count employees in each department

```sql
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e
    ON e.dept_id = d.dept_id
GROUP BY
    d.dept_id,
    d.dept_name
ORDER BY employee_count DESC;
```

Your current data has two employees in most departments, except Engineering, which has four.

---

## 31. Find the average salary per department

```sql
SELECT
    d.dept_name,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM departments d
LEFT JOIN employees e
    ON e.dept_id = d.dept_id
GROUP BY
    d.dept_id,
    d.dept_name
ORDER BY average_salary DESC NULLS LAST;
```

Expected averages:

```text
Finance       81000
Marketing     75000
Engineering   74000
HR            73000
Sales         72000
```

`Jack Thomas` has a `NULL` salary, so it is excluded from the Sales average.

---

## 32. What is the difference between `WHERE` and `HAVING`?

`WHERE` filters rows before grouping.

`HAVING` filters groups after aggregation.

Find departments with more than two employees:

```sql
SELECT
    dept_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 2;
```

Expected result: Engineering.

---

## 33. Calculate completed-order revenue

```sql
SELECT SUM(total_amount) AS completed_revenue
FROM orders
WHERE status = 'completed';
```

Expected result:

```text
4479.86
```

---

# 5. Joins

## 34. Show employees with their departments

```sql
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    d.dept_name,
    d.location
FROM employees e
JOIN departments d
    ON d.dept_id = e.dept_id;
```

`JOIN` without another keyword means `INNER JOIN`.

---

## 35. Explain `INNER JOIN` and `LEFT JOIN`

### `INNER JOIN`

Returns only matching rows.

```sql
SELECT *
FROM employees e
INNER JOIN departments d
    ON d.dept_id = e.dept_id;
```

### `LEFT JOIN`

Returns all rows from the left table, including those without matches.

```sql
SELECT *
FROM departments d
LEFT JOIN employees e
    ON e.dept_id = d.dept_id;
```

Use `LEFT JOIN` when you also want departments with zero employees.

---

## 36. Display employees and their managers

This uses a self-join:

```sql
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    m.first_name || ' ' || m.last_name AS manager_name
FROM employees e
LEFT JOIN employees m
    ON m.emp_id = e.manager_id
ORDER BY e.emp_id;
```

Employees without managers will have `NULL` in `manager_name`.

---

## 37. Show orders with customer names

```sql
SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_date,
    o.total_amount,
    o.status
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
ORDER BY o.order_date;
```

---

## 38. Show complete order details

```sql
SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON oi.order_id = o.order_id
JOIN products p
    ON p.product_id = oi.product_id
ORDER BY
    o.order_id,
    oi.item_id;
```

---

## 39. Find customers who have never placed an order

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
```

Expected result:

```text
Emma Watson
Tom Hardy
```

Alternative using `NOT EXISTS`:

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
```

`NOT EXISTS` is often safer than `NOT IN` when `NULL` values are possible.

---

# 6. Subqueries and CTEs

## 40. Find employees earning above the company average

```sql
SELECT
    emp_id,
    first_name,
    last_name,
    salary
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
)
ORDER BY salary DESC;
```

---

## 41. Find employees earning above their department average

This is a correlated subquery:

```sql
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    e.salary,
    e.dept_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.dept_id = e.dept_id
);
```

The inner query runs logically for each employee's department.

---

## 42. What is a CTE?

A Common Table Expression creates a named temporary result for one query.

```sql
WITH department_salary AS (
    SELECT
        dept_id,
        AVG(salary) AS average_salary
    FROM employees
    GROUP BY dept_id
)
SELECT
    e.first_name,
    e.last_name,
    e.salary,
    ds.average_salary
FROM employees e
JOIN department_salary ds
    ON ds.dept_id = e.dept_id
WHERE e.salary > ds.average_salary;
```

---

## 43. Use a recursive CTE to show the management hierarchy

```sql
WITH RECURSIVE employee_hierarchy AS (
    SELECT
        emp_id,
        first_name,
        last_name,
        manager_id,
        1 AS hierarchy_level,
        (first_name || ' ' || last_name)::TEXT AS hierarchy_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.emp_id,
        e.first_name,
        e.last_name,
        e.manager_id,
        eh.hierarchy_level + 1,
        eh.hierarchy_path || ' -> ' ||
        e.first_name || ' ' || e.last_name
    FROM employees e
    JOIN employee_hierarchy eh
        ON e.manager_id = eh.emp_id
)
SELECT *
FROM employee_hierarchy
ORDER BY hierarchy_path;
```

Recursive CTEs are commonly used for:

* Organizational hierarchies.
* Category trees.
* Folder structures.
* Bill-of-material structures.

---

# 7. Window functions

## 44. What is the difference between `GROUP BY` and a window function?

`GROUP BY` collapses several rows into one row per group.

Window functions calculate values across related rows without collapsing the original rows.

---

## 45. Rank employees by salary

```sql
SELECT
    first_name,
    last_name,
    salary,
    RANK() OVER (
        ORDER BY salary DESC NULLS LAST
    ) AS salary_rank
FROM employees;
```

---

## 46. Explain `ROW_NUMBER`, `RANK`, and `DENSE_RANK`

```sql
SELECT
    first_name,
    last_name,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_number,
    RANK() OVER (ORDER BY salary DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank
FROM employees
WHERE salary IS NOT NULL;
```

For tied values:

* `ROW_NUMBER()` always assigns different sequential numbers.
* `RANK()` assigns the same rank but leaves gaps.
* `DENSE_RANK()` assigns the same rank without gaps.

---

## 47. Rank employees within each department

```sql
SELECT
    d.dept_name,
    e.first_name,
    e.last_name,
    e.salary,
    DENSE_RANK() OVER (
        PARTITION BY e.dept_id
        ORDER BY e.salary DESC NULLS LAST
    ) AS department_salary_rank
FROM employees e
JOIN departments d
    ON d.dept_id = e.dept_id;
```

---

## 48. Find the highest-paid employee in every department

```sql
WITH ranked_employees AS (
    SELECT
        e.*,
        DENSE_RANK() OVER (
            PARTITION BY dept_id
            ORDER BY salary DESC NULLS LAST
        ) AS salary_rank
    FROM employees e
)
SELECT
    dept_id,
    first_name,
    last_name,
    salary
FROM ranked_employees
WHERE salary_rank = 1;
```

Using `DENSE_RANK()` includes tied employees.

---

## 49. Calculate running order revenue

```sql
SELECT
    order_id,
    order_date,
    total_amount,
    SUM(total_amount) OVER (
        ORDER BY order_date, order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue
FROM orders;
```

---

## 50. Compare an employee's salary with the previous salary

```sql
SELECT
    emp_id,
    from_date,
    salary,
    LAG(salary) OVER (
        PARTITION BY emp_id
        ORDER BY from_date
    ) AS previous_salary,
    salary - LAG(salary) OVER (
        PARTITION BY emp_id
        ORDER BY from_date
    ) AS salary_increase
FROM salaries;
```

---

# 8. Data-quality and audit questions

## 51. Find orders whose stored total does not match the item total

This is a strong interview question because it tests joins, aggregation, and data validation.

```sql
SELECT
    o.order_id,
    o.total_amount AS stored_total,
    SUM(oi.quantity * oi.unit_price) AS calculated_total,
    o.total_amount -
        SUM(oi.quantity * oi.unit_price) AS difference
FROM orders o
JOIN order_items oi
    ON oi.order_id = o.order_id
GROUP BY
    o.order_id,
    o.total_amount
HAVING o.total_amount <>
       SUM(oi.quantity * oi.unit_price);
```

In your data, orders `3` and `10` have inconsistent totals.

A safer decimal comparison is:

```sql
HAVING ABS(
    o.total_amount -
    SUM(oi.quantity * oi.unit_price)
) > 0.01;
```

---

## 52. Find products that have never been ordered

```sql
SELECT
    p.product_id,
    p.product_name
FROM products p
LEFT JOIN order_items oi
    ON oi.product_id = p.product_id
WHERE oi.item_id IS NULL;
```

---

## 53. Find the most frequently ordered product

```sql
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_ordered
FROM products p
JOIN order_items oi
    ON oi.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_quantity_ordered DESC
LIMIT 1;
```

---

## 54. Find the customer who has spent the most

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE o.status <> 'cancelled'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC
LIMIT 1;
```

Based on the stored order totals, Stanley Hudson has the largest non-cancelled total.

In a production system, revenue should normally be calculated from validated order-item data rather than trusting inconsistent stored totals.

---

## 55. Find duplicate customer emails

The current unique constraint prevents duplicates, but the interview query is:

```sql
SELECT
    email,
    COUNT(*) AS occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
```

---

# 9. Views

## 56. What is a view?

A view is a stored SQL query. It generally stores the query definition, not a separate copy of the data.

```sql
CREATE OR REPLACE VIEW employee_department_view AS
SELECT
    e.emp_id,
    e.first_name,
    e.last_name,
    e.email,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
JOIN departments d
    ON d.dept_id = e.dept_id;
```

Use it like a table:

```sql
SELECT *
FROM employee_department_view
WHERE dept_name = 'Engineering';
```

---

## 57. What are the benefits of views?

Views can:

* Simplify complicated queries.
* Hide sensitive columns.
* Provide a consistent reporting interface.
* Reduce duplicated SQL.
* Provide limited abstraction over underlying tables.

For example, a reporting view can exclude private salary information.

---

## 58. Can a view be updated?

Some simple PostgreSQL views are automatically updatable.

A view may not be automatically updatable when it contains features such as:

* Aggregates.
* `GROUP BY`.
* `DISTINCT`.
* Window functions.
* Set operations.
* Complicated joins.

An `INSTEAD OF` trigger can sometimes make a complex view writable.

---

# 10. Materialized views

## 59. What is a materialized view?

A materialized view stores the query result physically.

```sql
CREATE MATERIALIZED VIEW monthly_sales_summary AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS sales_month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', order_date);
```

Query it:

```sql
SELECT *
FROM monthly_sales_summary;
```

---

## 60. What is the difference between a view and materialized view?

| View                            | Materialized view                    |
| ------------------------------- | ------------------------------------ |
| Stores the query definition     | Stores query results physically      |
| Returns current underlying data | Can become stale                     |
| Recalculates when queried       | Usually faster for expensive reports |
| Does not need refreshing        | Must be refreshed                    |

Refresh it:

```sql
REFRESH MATERIALIZED VIEW monthly_sales_summary;
```

---

## 61. How do you refresh a materialized view without blocking readers?

```sql
CREATE UNIQUE INDEX ux_monthly_sales_summary_month
ON monthly_sales_summary(sales_month);
```

Then:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY
monthly_sales_summary;
```

PostgreSQL requires an appropriate unique index for concurrent refresh.

---

# 11. Functions

## 62. What is a PostgreSQL function?

A function is reusable database logic that:

* Accepts parameters.
* Returns a value, row, or table.
* Can be used inside SQL queries.
* Runs inside the caller's transaction.

---

## 63. Create a function that returns an employee's annual salary

```sql
CREATE OR REPLACE FUNCTION get_annual_salary(
    p_emp_id INT
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_monthly_salary NUMERIC(10,2);
BEGIN
    SELECT salary
    INTO v_monthly_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee with ID % does not exist',
            p_emp_id;
    END IF;

    RETURN COALESCE(v_monthly_salary, 0) * 12;
END;
$$;
```

Call it:

```sql
SELECT get_annual_salary(1);
```

Expected result:

```text
900000.00
```

---

## 64. Create a SQL-language function

For simple queries, use `LANGUAGE SQL`.

```sql
CREATE OR REPLACE FUNCTION get_department_employee_count(
    p_dept_id INT
)
RETURNS BIGINT
LANGUAGE sql
AS $$
    SELECT COUNT(*)
    FROM employees
    WHERE dept_id = p_dept_id;
$$;
```

Call it:

```sql
SELECT get_department_employee_count(1);
```

Expected result:

```text
4
```

---

## 65. Create a function that returns a table

```sql
CREATE OR REPLACE FUNCTION get_department_employees(
    p_dept_id INT
)
RETURNS TABLE (
    employee_id INT,
    employee_name TEXT,
    employee_salary NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        e.emp_id,
        e.first_name || ' ' || e.last_name,
        e.salary
    FROM employees e
    WHERE e.dept_id = p_dept_id
    ORDER BY e.salary DESC NULLS LAST;
$$;
```

Call it:

```sql
SELECT *
FROM get_department_employees(1);
```

---

## 66. Explain function volatility

PostgreSQL functions can be:

### `IMMUTABLE`

Always returns the same result for the same inputs.

```sql
CREATE FUNCTION calculate_line_total(
    quantity INT,
    unit_price NUMERIC
)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT quantity * unit_price;
$$;
```

### `STABLE`

Does not modify data and returns consistent results within one statement.

### `VOLATILE`

May change data or return different results for the same input. This is the default.

Examples include functions using:

* `random()`
* `nextval()`
* `CURRENT_TIMESTAMP`-dependent behavior
* `INSERT`, `UPDATE`, or `DELETE`

---

# 12. Stored procedures

## 67. What is the difference between a function and procedure?

| Function                                                   | Procedure                                                                    |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Called with `SELECT`                                       | Called with `CALL`                                                           |
| Must declare a return type                                 | Does not need to return a value                                              |
| Can be used in expressions                                 | Cannot be used directly in a `SELECT` expression                             |
| Good for calculations and reusable queries                 | Good for operations and workflows                                            |
| Cannot control transactions in ordinary function execution | Procedures may support transaction control under specific calling conditions |

---

## 68. Create a procedure to increase department salaries

```sql
CREATE OR REPLACE PROCEDURE increase_department_salary(
    p_dept_id INT,
    p_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_percentage <= 0 THEN
        RAISE EXCEPTION
            'Percentage must be greater than zero';
    END IF;

    UPDATE employees
    SET salary = salary * (1 + p_percentage / 100)
    WHERE dept_id = p_dept_id
      AND salary IS NOT NULL;

    RAISE NOTICE
        'Updated % employees',
        ROW_COUNT;
END;
$$;
```

The `ROW_COUNT` usage should normally be captured with diagnostics:

```sql
CREATE OR REPLACE PROCEDURE increase_department_salary(
    p_dept_id INT,
    p_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated_rows INT;
BEGIN
    IF p_percentage <= 0 THEN
        RAISE EXCEPTION
            'Percentage must be greater than zero';
    END IF;

    UPDATE employees
    SET salary = salary * (1 + p_percentage / 100)
    WHERE dept_id = p_dept_id
      AND salary IS NOT NULL;

    GET DIAGNOSTICS v_updated_rows = ROW_COUNT;

    RAISE NOTICE
        'Updated % employees',
        v_updated_rows;
END;
$$;
```

Call it:

```sql
CALL increase_department_salary(1, 5);
```

---

# 13. Triggers

## 69. What is a trigger?

A trigger automatically executes a trigger function when an event occurs, such as:

* `INSERT`
* `UPDATE`
* `DELETE`
* `TRUNCATE`

Triggers can run:

* `BEFORE`
* `AFTER`
* `INSTEAD OF`

They can also run once per row or once per statement.

---

## 70. Create a trigger that updates order totals

First create the trigger function:

```sql
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
BEGIN
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);

    UPDATE orders
    SET total_amount = (
        SELECT COALESCE(
            SUM(quantity * unit_price),
            0
        )
        FROM order_items
        WHERE order_id = v_order_id
    )
    WHERE order_id = v_order_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;
```

Create the trigger:

```sql
CREATE TRIGGER trg_update_order_total
AFTER INSERT OR UPDATE OR DELETE
ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();
```

Important limitation: if an `UPDATE` moves an item from one order to another, both the old and new orders must be recalculated. A production implementation should explicitly handle that case.

---

## 71. Create an audit table and trigger

Audit table:

```sql
CREATE TABLE employee_salary_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    emp_id INT NOT NULL,
    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT CURRENT_USER
);
```

Trigger function:

```sql
CREATE OR REPLACE FUNCTION audit_employee_salary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.salary IS DISTINCT FROM NEW.salary THEN
        INSERT INTO employee_salary_audit (
            emp_id,
            old_salary,
            new_salary
        )
        VALUES (
            NEW.emp_id,
            OLD.salary,
            NEW.salary
        );
    END IF;

    RETURN NEW;
END;
$$;
```

Trigger:

```sql
CREATE TRIGGER trg_audit_employee_salary
AFTER UPDATE OF salary
ON employees
FOR EACH ROW
EXECUTE FUNCTION audit_employee_salary();
```

`IS DISTINCT FROM` safely compares values even when one is `NULL`.

---

## 72. When should triggers be avoided?

Avoid unnecessary triggers when:

* The logic is better handled with a constraint.
* Trigger behavior would surprise developers.
* The trigger introduces hidden performance costs.
* Multiple triggers create difficult dependencies.
* Business logic needs to be visible in the application workflow.

Use a `CHECK` constraint rather than a trigger for simple validation:

```sql
ALTER TABLE order_items
ADD CONSTRAINT chk_order_item_quantity
CHECK (quantity > 0);
```

---

# 14. Event triggers

## 73. What is an event trigger?

A normal trigger responds to changes in table data.

An **event trigger** responds to database-level DDL events such as:

* `CREATE TABLE`
* `ALTER TABLE`
* `DROP TABLE`
* `CREATE INDEX`

Event triggers are PostgreSQL-specific and normally require elevated privileges.

---

## 74. Create an event trigger to log DDL changes

Create an audit table:

```sql
CREATE TABLE ddl_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    event_type TEXT,
    command_tag TEXT,
    object_type TEXT,
    schema_name TEXT,
    object_identity TEXT,
    executed_by TEXT,
    executed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

Create the event trigger function:

```sql
CREATE OR REPLACE FUNCTION log_ddl_commands()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ddl_audit_log (
        event_type,
        command_tag,
        object_type,
        schema_name,
        object_identity,
        executed_by
    )
    SELECT
        TG_EVENT,
        command_tag,
        object_type,
        schema_name,
        object_identity,
        CURRENT_USER
    FROM pg_event_trigger_ddl_commands();
END;
$$;
```

Create the event trigger:

```sql
CREATE EVENT TRIGGER trg_log_ddl_commands
ON ddl_command_end
EXECUTE FUNCTION log_ddl_commands();
```

Test it:

```sql
CREATE TABLE event_trigger_test (
    id INT
);
```

Then:

```sql
SELECT *
FROM ddl_audit_log
ORDER BY executed_at DESC;
```

Remove it carefully:

```sql
DROP EVENT TRIGGER trg_log_ddl_commands;
```

---

## 75. Can event triggers monitor `INSERT` or `UPDATE`?

No. Event triggers are for DDL activity.

For `INSERT`, `UPDATE`, and `DELETE`, use regular table triggers.

---

# 15. Constraints

## 76. Add useful constraints to this schema

```sql
ALTER TABLE employees
ADD CONSTRAINT chk_employee_salary
CHECK (salary IS NULL OR salary >= 0);

ALTER TABLE products
ADD CONSTRAINT chk_product_price
CHECK (price >= 0);

ALTER TABLE products
ADD CONSTRAINT chk_product_stock
CHECK (stock_quantity >= 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_item_quantity
CHECK (quantity > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_order_item_unit_price
CHECK (unit_price >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_order_status
CHECK (
    status IN (
        'pending',
        'shipped',
        'completed',
        'cancelled'
    )
);
```

---

## 77. What is the difference between `UNIQUE` and `PRIMARY KEY`?

Both enforce uniqueness.

A primary key:

* Cannot contain `NULL`.
* Identifies the row.
* Has one primary-key constraint per table.

A table may have several unique constraints.

Example:

```sql
emp_id SERIAL PRIMARY KEY,
email VARCHAR(100) UNIQUE
```

---

## 78. Explain `ON DELETE` actions

### Restrict deletion

Default behavior generally prevents deleting a parent row that is referenced.

### Cascade

```sql
order_id INT
REFERENCES orders(order_id)
ON DELETE CASCADE
```

Deleting an order also deletes its order items.

### Set null

```sql
manager_id INT
REFERENCES employees(emp_id)
ON DELETE SET NULL
```

Deleting a manager sets their subordinates' `manager_id` to `NULL`.

A stronger version of your relationships might be:

```sql
ALTER TABLE order_items
DROP CONSTRAINT order_items_order_id_fkey,
ADD CONSTRAINT order_items_order_id_fkey
FOREIGN KEY (order_id)
REFERENCES orders(order_id)
ON DELETE CASCADE;
```

---

# 16. Indexes and performance

## 79. What is an index?

An index is a data structure that helps PostgreSQL locate rows faster.

It improves reads but has costs:

* Uses disk space.
* Slows inserts, updates, and deletes.
* Requires maintenance.

---

## 80. Which columns in this schema should be indexed?

Primary keys and unique constraints already create indexes.

Useful additional indexes include:

```sql
CREATE INDEX idx_employees_dept_id
ON employees(dept_id);

CREATE INDEX idx_employees_manager_id
ON employees(manager_id);

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_order_date
ON orders(order_date);

CREATE INDEX idx_orders_status_order_date
ON orders(status, order_date);

CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX idx_products_category_id
ON products(category_id);

CREATE INDEX idx_salaries_emp_id_from_date
ON salaries(emp_id, from_date DESC);
```

PostgreSQL does not automatically create indexes on the referencing side of foreign keys.

---

## 81. Explain the importance of column order in a composite index

For this index:

```sql
CREATE INDEX idx_orders_status_date
ON orders(status, order_date);
```

It is useful for:

```sql
WHERE status = 'completed'
  AND order_date >= DATE '2024-01-01'
```

It may also help:

```sql
WHERE status = 'completed'
```

But it is generally less useful for:

```sql
WHERE order_date = DATE '2024-01-15'
```

because `status` is the leading column.

---

## 82. What is a partial index?

A partial index only indexes rows matching a condition.

```sql
CREATE INDEX idx_pending_orders
ON orders(order_date)
WHERE status = 'pending';
```

It is useful when pending orders represent a small, frequently queried subset.

---

## 83. What is an expression index?

An expression index indexes a calculated expression.

```sql
CREATE INDEX idx_customers_lower_email
ON customers(LOWER(email));
```

It supports queries such as:

```sql
SELECT *
FROM customers
WHERE LOWER(email) = LOWER('Michael@DunderMifflin.com');
```

---

## 84. How do you inspect a query plan?

```sql
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 1;
```

To execute the query and get actual measurements:

```sql
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 1;
```

A more detailed format:

```sql
EXPLAIN (
    ANALYZE,
    BUFFERS,
    VERBOSE
)
SELECT *
FROM orders
WHERE customer_id = 1;
```

Be cautious because `EXPLAIN ANALYZE` actually runs the statement.

---

## 85. What is a sequential scan?

A sequential scan reads the table rows directly.

It is not automatically bad. PostgreSQL may prefer it when:

* The table is small.
* The query returns a large percentage of the table.
* The index is not selective.
* Statistics indicate an index would cost more.

---

## 86. Why might PostgreSQL ignore an index?

Possible reasons include:

* The table is very small.
* Most rows match the condition.
* The statistics are outdated.
* A function is applied differently from the indexed expression.
* Type casting prevents efficient index use.
* The query uses a leading wildcard:

```sql
WHERE product_name LIKE '%phone%'
```

* The index column order does not match the query.

---

## 87. What do `VACUUM` and `ANALYZE` do?

### `VACUUM`

Reclaims reusable storage from dead row versions and supports PostgreSQL's MVCC maintenance.

### `ANALYZE`

Updates table statistics used by the query planner.

```sql
VACUUM ANALYZE orders;
```

Normally, PostgreSQL's autovacuum handles this automatically.

---

# 17. Data manipulation

## 88. Increase Engineering salaries by 10%

```sql
UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = (
    SELECT dept_id
    FROM departments
    WHERE dept_name = 'Engineering'
);
```

For interview safety, first preview:

```sql
SELECT *
FROM employees
WHERE dept_id = (
    SELECT dept_id
    FROM departments
    WHERE dept_name = 'Engineering'
);
```

Then use a transaction:

```sql
BEGIN;

UPDATE employees
SET salary = salary * 1.10
WHERE dept_id = (
    SELECT dept_id
    FROM departments
    WHERE dept_name = 'Engineering'
);

-- Inspect results before committing.

COMMIT;
```

---

## 89. Delete customers who have never ordered

```sql
DELETE FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
)
RETURNING *;
```

`RETURNING` shows the affected rows.

---

## 90. Use PostgreSQL upsert

```sql
INSERT INTO customers (
    first_name,
    last_name,
    email,
    city,
    country
)
VALUES (
    'Michael',
    'Scott',
    'michael@dundermifflin.com',
    'New York',
    'USA'
)
ON CONFLICT (email)
DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    city = EXCLUDED.city,
    country = EXCLUDED.country;
```

`EXCLUDED` represents the row that PostgreSQL attempted to insert.

---

## 91. What is the difference between `DELETE`, `TRUNCATE`, and `DROP`?

### `DELETE`

* Removes selected rows.
* Supports `WHERE`.
* Fires row-level delete triggers.
* Keeps the table.

```sql
DELETE FROM orders
WHERE status = 'cancelled';
```

### `TRUNCATE`

* Quickly removes all rows.
* Does not support `WHERE`.
* Can reset identity sequences.
* Uses stronger locking.

```sql
TRUNCATE TABLE orders
RESTART IDENTITY CASCADE;
```

### `DROP`

Removes the entire database object.

```sql
DROP TABLE orders;
```

---

# 18. Schema-design improvement questions

## 92. What problems do you see in the current schema?

Good interview observations include:

### Order totals can become inconsistent

`orders.total_amount` duplicates values calculated from `order_items`.

Your sample data already contains inconsistencies for orders `3` and `10`.

Options:

* Calculate totals when needed.
* Maintain them using a controlled transaction.
* Maintain them using a carefully designed trigger.

### Foreign-key columns allow `NULL`

For example:

```sql
order_id INT REFERENCES orders(order_id)
```

An order item probably should always belong to an order:

```sql
order_id INT NOT NULL REFERENCES orders(order_id)
```

### Missing validation constraints

Quantities, prices, salaries, and stock can currently be negative.

### Status is unrestricted text

Use a `CHECK` constraint, lookup table, or enum where appropriate.

### `SERIAL` is older style

Modern PostgreSQL designs often prefer identity columns:

```sql
emp_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

### Historical salaries need date validation

```sql
CHECK (
    to_date IS NULL
    OR to_date >= from_date
)
```

### Historical salary periods might overlap

An exclusion constraint can prevent overlapping salary periods for the same employee.

---

## 93. How would you improve the `order_items` primary key?

The current table has:

```sql
item_id SERIAL PRIMARY KEY
```

This permits the same product to appear multiple times in one order.

If that is not desired:

```sql
ALTER TABLE order_items
ADD CONSTRAINT uq_order_product
UNIQUE (order_id, product_id);
```

Alternatively, use a composite key:

```sql
PRIMARY KEY (order_id, product_id)
```

Keeping `item_id` may still be useful when individual line items need their own identity.

---

## 94. Why store `unit_price` in `order_items` when products already have a price?

The product price may change later.

`order_items.unit_price` records the price at the time of purchase. Without it, historical invoices could change whenever the current product price changes.

---

## 95. Should `orders.total_amount` be stored or calculated?

It depends.

### Calculate it

Benefits:

* No duplicate value.
* No risk of inconsistent totals.

Cost:

* Aggregation is required when reading.

### Store it

Benefits:

* Faster reporting and retrieval.
* Useful as a finalized financial snapshot.

Cost:

* It must be maintained reliably.

For financial systems, storing the finalized total is common, but it should be generated from validated line items within a controlled transaction.

---

# 19. Security questions

## 96. How do you protect against SQL injection?

Use parameterized queries.

Unsafe:

```javascript
const sql =
  `SELECT * FROM customers WHERE email = '${email}'`;
```

Safe conceptually:

```sql
SELECT *
FROM customers
WHERE email = $1;
```

Also:

* Validate input.
* Use least-privilege database roles.
* Avoid dynamically concatenating object names.
* Do not expose database error details publicly.

---

## 97. What is least privilege?

A user should only receive permissions required for their job.

```sql
CREATE ROLE reporting_user LOGIN PASSWORD 'secure-password';

GRANT CONNECT ON DATABASE company_db
TO reporting_user;

GRANT USAGE ON SCHEMA public
TO reporting_user;

GRANT SELECT ON employees, departments, orders
TO reporting_user;
```

Do not grant unrestricted superuser access to applications.

---

## 98. How can a view hide employee salaries?

```sql
CREATE VIEW public_employee_directory AS
SELECT
    emp_id,
    first_name,
    last_name,
    email,
    dept_id
FROM employees;
```

Then:

```sql
REVOKE SELECT ON employees
FROM reporting_user;

GRANT SELECT ON public_employee_directory
TO reporting_user;
```

---

# 20. Advanced practical challenges

## 99. Return the second-highest salary

Using a subquery:

```sql
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
);
```

Using `DENSE_RANK()`:

```sql
WITH ranked_salaries AS (
    SELECT
        salary,
        DENSE_RANK() OVER (
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employees
    WHERE salary IS NOT NULL
)
SELECT DISTINCT salary
FROM ranked_salaries
WHERE salary_rank = 2;
```

Expected result:

```text
95000
```

---

## 100. Find the third-highest-paid employee in each department

```sql
WITH ranked_employees AS (
    SELECT
        e.*,
        DENSE_RANK() OVER (
            PARTITION BY dept_id
            ORDER BY salary DESC NULLS LAST
        ) AS salary_rank
    FROM employees e
)
SELECT *
FROM ranked_employees
WHERE salary_rank = 3;
```

---

## 101. Find customers with more than one order

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(o.order_id) > 1;
```

---

## 102. Show monthly revenue and revenue growth

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS sales_month,
        SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE_TRUNC('month', order_date)
),
revenue_comparison AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    sales_month,
    revenue,
    previous_month_revenue,
    revenue - previous_month_revenue AS revenue_change,
    ROUND(
        (
            revenue - previous_month_revenue
        ) / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS growth_percentage
FROM revenue_comparison
ORDER BY sales_month;
```

`NULLIF(previous_month_revenue, 0)` prevents division by zero.

---

## 103. Find each department's percentage of total payroll

```sql
WITH department_payroll AS (
    SELECT
        d.dept_name,
        SUM(e.salary) AS payroll
    FROM departments d
    JOIN employees e
        ON e.dept_id = d.dept_id
    GROUP BY d.dept_id, d.dept_name
)
SELECT
    dept_name,
    payroll,
    ROUND(
        payroll / SUM(payroll) OVER () * 100,
        2
    ) AS payroll_percentage
FROM department_payroll
ORDER BY payroll DESC;
```

---

## 104. Find customers who ordered every Electronics product

This is relational division:

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM products p
    JOIN categories cat
        ON cat.category_id = p.category_id
    WHERE cat.category_name = 'Electronics'
      AND NOT EXISTS (
          SELECT 1
          FROM orders o
          JOIN order_items oi
              ON oi.order_id = o.order_id
          WHERE o.customer_id = c.customer_id
            AND oi.product_id = p.product_id
            AND o.status <> 'cancelled'
      )
);
```

Meaning: there must not be an Electronics product that the customer has not ordered.

---

# 21. Rapid-fire interview questions

## What is MVCC?

**Multi-Version Concurrency Control** lets PostgreSQL maintain multiple row versions so readers and writers can operate concurrently with less blocking.

## What is a deadlock?

A deadlock happens when two transactions each wait for a resource held by the other. PostgreSQL detects the cycle and terminates one transaction.

## What is a schema?

A schema is a namespace for database objects.

```sql
CREATE SCHEMA sales;
```

## What is cardinality?

Cardinality may refer to:

* The number of rows in a result or table.
* The uniqueness or number of distinct values in a column.
* Relationship types such as one-to-one, one-to-many, and many-to-many.

## What is selectivity?

Selectivity describes how much a condition narrows the data. Highly selective conditions return relatively few rows and often benefit more from indexes.

## What is denormalization?

Denormalization deliberately duplicates or precomputes data to improve read performance, at the cost of additional consistency work.

## What is a surrogate key?

A generated identifier with no business meaning:

```sql
customer_id SERIAL PRIMARY KEY
```

## What is a natural key?

A meaningful business value used as an identifier, such as an email or national ID. Natural keys may change, so surrogate keys are often preferred as primary keys.

## What is a covering index?

An index that contains the columns needed by a query, potentially allowing an index-only scan.

```sql
CREATE INDEX idx_orders_customer_covering
ON orders(customer_id)
INCLUDE (order_date, total_amount, status);
```

## What is a database sequence?

A sequence generates numeric values.

```sql
SELECT nextval('employees_emp_id_seq');
```

`SERIAL` creates and connects a sequence behind the scenes.

## What is partitioning?

Partitioning divides a large logical table into smaller physical tables.

For example, orders could be partitioned by year or month:

```sql
CREATE TABLE partitioned_orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id INT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(10,2),
    status VARCHAR(20)
)
PARTITION BY RANGE (order_date);
```

## What is replication?

Replication copies database changes to another server for availability, read scaling, or disaster recovery.

## What is a prepared statement?

A prepared statement parses and plans SQL for repeated execution.

```sql
PREPARE find_customer(TEXT) AS
SELECT *
FROM customers
WHERE email = $1;

EXECUTE find_customer('michael@dundermifflin.com');
```

---

# Recommended live interview exercises

An interviewer could give you these tasks without answers:

1. Find the highest-paid employee in every department.
2. Find customers with no orders.
3. Find the three best-selling products.
4. Recalculate every order total using `order_items`.
5. Detect order-total inconsistencies.
6. Rank employees inside each department.
7. Show employee-manager relationships.
8. Build a recursive management hierarchy.
9. Calculate monthly sales growth.
10. Create a view for order details.
11. Create a materialized view for monthly revenue.
12. Create a function that returns employees by department.
13. Create a procedure that increases salaries.
14. Create a trigger that audits salary changes.
15. Create an event trigger that audits DDL changes.
16. Suggest appropriate indexes and justify each one.
17. Explain a query plan using `EXPLAIN ANALYZE`.
18. Process an order safely using a transaction and row locking.
19. Identify normalization and integrity problems in the schema.
20. Explain how you would handle millions of orders.

The strongest preparation approach is to first write each query without looking at the answer, then run `EXPLAIN ANALYZE` and explain why PostgreSQL chose its execution plan.
