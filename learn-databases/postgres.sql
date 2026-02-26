-- ============================================
-- SQL INTERVIEW PRACTICE - 100 QUESTIONS
-- ============================================
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

-- ============================================
-- 100 SQL INTERVIEW QUESTIONS
-- ============================================

-- ==========================================
-- SECTION 1: BASIC SELECT (Questions 1-15)
-- ==========================================

-- Q1: Select all columns from the employees table
SELECT * FROM employees;

-- Q2: Select only first_name and last_name from employees
SELECT first_name, last_name FROM employees;

-- Q3: Select all unique departments locations
SELECT DISTINCT location FROM departments;

-- Q4: Select employees with salary greater than 70000
SELECT * FROM employees WHERE salary > 70000;

-- Q5: Select employees hired after 2020-01-01
SELECT * FROM employees WHERE hire_date > '2020-01-01';

-- Q6: Select employees whose first name starts with 'J'
SELECT * FROM employees WHERE first_name LIKE 'J%';

-- Q7: Select employees whose email contains 'company'
SELECT * FROM employees WHERE email LIKE '%company%';

-- Q8: Select top 5 highest paid employees
SELECT * FROM employees ORDER BY salary DESC LIMIT 5;

-- Q9: Select employees ordered by hire_date ascending
SELECT * FROM employees ORDER BY hire_date ASC;

-- Q10: Select employees with salary between 60000 and 80000
SELECT * FROM employees WHERE salary BETWEEN 60000 AND 80000;

-- Q11: Select employees from dept_id 1 or 2
SELECT * FROM employees WHERE dept_id IN (1, 2);

-- Q12: Select employees who have a manager (manager_id is not null)
SELECT * FROM employees WHERE manager_id IS NOT NULL;

-- Q13: Select employees who don't have a manager
SELECT * FROM employees WHERE manager_id IS NULL;

-- Q14: Count total number of employees
SELECT COUNT(*) AS total_employees FROM employees;

-- Q15: Select employee full name (concatenation)
SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- ==========================================
-- SECTION 2: AGGREGATE FUNCTIONS (Questions 16-30)
-- ==========================================

-- Q16: Find the average salary of all employees
SELECT AVG(salary) AS average_salary FROM employees;

-- Q17: Find the maximum salary
SELECT MAX(salary) AS max_salary FROM employees;

-- Q18: Find the minimum salary
SELECT MIN(salary) AS min_salary FROM employees;

-- Q19: Find the total salary expense
SELECT SUM(salary) AS total_salary FROM employees;

-- Q20: Count employees in each department
SELECT dept_id, COUNT(*) AS emp_count 
FROM employees 
GROUP BY dept_id;

-- Q21: Find average salary by department
SELECT dept_id, AVG(salary) AS avg_salary 
FROM employees 
GROUP BY dept_id;

-- Q22: Find departments with more than 2 employees
SELECT dept_id, COUNT(*) AS emp_count 
FROM employees 
GROUP BY dept_id 
HAVING COUNT(*) > 2;

-- Q23: Find the total order amount by status
SELECT status, SUM(total_amount) AS total 
FROM orders 
GROUP BY status;

-- Q24: Count orders per customer
SELECT customer_id, COUNT(*) AS order_count 
FROM orders 
GROUP BY customer_id;

-- Q25: Find average product price by category
SELECT category_id, AVG(price) AS avg_price 
FROM products 
GROUP BY category_id;

-- Q26: Find the highest salary in each department
SELECT dept_id, MAX(salary) AS max_salary 
FROM employees 
GROUP BY dept_id;

-- Q27: Count customers by country
SELECT country, COUNT(*) AS customer_count 
FROM customers 
GROUP BY country;

-- Q28: Find total revenue per month
SELECT DATE_TRUNC('month', order_date) AS month, SUM(total_amount) AS revenue 
FROM orders 
GROUP BY DATE_TRUNC('month', order_date);

-- Q29: Find categories with average price > 50
SELECT category_id, AVG(price) AS avg_price 
FROM products 
GROUP BY category_id 
HAVING AVG(price) > 50;

-- Q30: Count products with stock < 100
SELECT COUNT(*) AS low_stock_count 
FROM products 
WHERE stock_quantity < 100;

-- ==========================================
-- SECTION 3: JOINS (Questions 31-50)
-- ==========================================

-- Q31: INNER JOIN - Get employee names with their department names
SELECT e.first_name, e.last_name, d.dept_name 
FROM employees e 
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Q32: LEFT JOIN - Get all employees with their department (including those without dept)
SELECT e.first_name, e.last_name, d.dept_name 
FROM employees e 
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Q33: RIGHT JOIN - Get all departments with their employees
SELECT e.first_name, e.last_name, d.dept_name 
FROM employees e 
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Q34: Get orders with customer names
SELECT o.order_id, c.first_name, c.last_name, o.total_amount 
FROM orders o 
INNER JOIN customers c ON o.customer_id = c.customer_id;

-- Q35: Get products with their category names
SELECT p.product_name, c.category_name, p.price 
FROM products p 
INNER JOIN categories c ON p.category_id = c.category_id;

-- Q36: Self JOIN - Get employees with their manager names
SELECT e.first_name AS employee, m.first_name AS manager 
FROM employees e 
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Q37: Multiple JOINs - Get order details with product and customer info
SELECT c.first_name, c.last_name, p.product_name, oi.quantity, oi.unit_price 
FROM order_items oi 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id = c.customer_id 
JOIN products p ON oi.product_id = p.product_id;

-- Q38: Get employees who earn more than their manager
SELECT e.first_name AS employee, e.salary AS emp_salary, 
       m.first_name AS manager, m.salary AS mgr_salary 
FROM employees e 
JOIN employees m ON e.manager_id = m.emp_id 
WHERE e.salary > m.salary;

-- Q39: FULL OUTER JOIN - All employees and all departments
SELECT e.first_name, d.dept_name 
FROM employees e 
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

-- Q40: Get total sales per product
SELECT p.product_name, SUM(oi.quantity * oi.unit_price) AS total_sales 
FROM products p 
JOIN order_items oi ON p.product_id = oi.product_id 
GROUP BY p.product_name;

-- Q41: Find customers who have never placed an order
SELECT c.* 
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.customer_id 
WHERE o.order_id IS NULL;

-- Q42: Get average salary per department with department name
SELECT d.dept_name, AVG(e.salary) AS avg_salary 
FROM departments d 
JOIN employees e ON d.dept_id = e.dept_id 
GROUP BY d.dept_name;

-- Q43: Find products that have never been ordered
SELECT p.* 
FROM products p 
LEFT JOIN order_items oi ON p.product_id = oi.product_id 
WHERE oi.item_id IS NULL;

-- Q44: Get employee count per department with department name
SELECT d.dept_name, COUNT(e.emp_id) AS emp_count 
FROM departments d 
LEFT JOIN employees e ON d.dept_id = e.dept_id 
GROUP BY d.dept_name;

-- Q45: Find the most expensive order for each customer
SELECT c.first_name, c.last_name, MAX(o.total_amount) AS max_order 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Q46: Get all order items with order date and customer email
SELECT oi.*, o.order_date, c.email 
FROM order_items oi 
JOIN orders o ON oi.order_id = o.order_id 
JOIN customers c ON o.customer_id = c.customer_id;

-- Q47: Find employees in the same department as 'John Smith'
SELECT e2.* 
FROM employees e1 
JOIN employees e2 ON e1.dept_id = e2.dept_id 
WHERE e1.first_name = 'John' AND e1.last_name = 'Smith' 
AND e2.emp_id != e1.emp_id;

-- Q48: Get category-wise product count and total stock
SELECT c.category_name, COUNT(p.product_id) AS product_count, SUM(p.stock_quantity) AS total_stock 
FROM categories c 
LEFT JOIN products p ON c.category_id = p.category_id 
GROUP BY c.category_name;

-- Q49: Find customers from the same city
SELECT c1.first_name AS customer1, c2.first_name AS customer2, c1.city 
FROM customers c1 
JOIN customers c2 ON c1.city = c2.city AND c1.customer_id < c2.customer_id;

-- Q50: Get employee salary history with employee name
SELECT e.first_name, e.last_name, s.salary, s.from_date, s.to_date 
FROM employees e 
JOIN salaries s ON e.emp_id = s.emp_id 
ORDER BY e.emp_id, s.from_date;

-- ==========================================
-- SECTION 4: SUBQUERIES (Questions 51-65)
-- ==========================================

-- Q51: Find employees with salary above average
SELECT * FROM employees 
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Q52: Find the employee(s) with the highest salary
SELECT * FROM employees 
WHERE salary = (SELECT MAX(salary) FROM employees);

-- Q53: Find employees who work in the Engineering department
SELECT * FROM employees 
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'Engineering');

-- Q54: Find products priced above the average price in their category
SELECT * FROM products p 
WHERE price > (SELECT AVG(price) FROM products WHERE category_id = p.category_id);

-- Q55: Find customers who have placed more than 1 order
SELECT * FROM customers 
WHERE customer_id IN (
    SELECT customer_id FROM orders 
    GROUP BY customer_id 
    HAVING COUNT(*) > 1
);

-- Q56: Find departments with above-average employee count
SELECT * FROM departments 
WHERE dept_id IN (
    SELECT dept_id FROM employees 
    GROUP BY dept_id 
    HAVING COUNT(*) > (SELECT COUNT(*)/COUNT(DISTINCT dept_id) FROM employees)
);

-- Q57: Find the second highest salary
SELECT MAX(salary) AS second_highest 
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Q58: Find employees hired in the same year as the earliest hire
SELECT * FROM employees 
WHERE EXTRACT(YEAR FROM hire_date) = (
    SELECT EXTRACT(YEAR FROM MIN(hire_date)) FROM employees
);

-- Q59: Correlated subquery - Find employees earning above their department average
SELECT * FROM employees e 
WHERE salary > (
    SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id
);

-- Q60: EXISTS - Find customers who have placed at least one order
SELECT * FROM customers c 
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- Q61: NOT EXISTS - Find customers who haven't placed any orders
SELECT * FROM customers c 
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- Q62: Find products ordered more than 2 times
SELECT * FROM products 
WHERE product_id IN (
    SELECT product_id FROM order_items 
    GROUP BY product_id 
    HAVING COUNT(*) > 2
);

-- Q63: Scalar subquery in SELECT - Show employee salary vs department average
SELECT first_name, salary, 
    (SELECT AVG(salary) FROM employees e2 WHERE e2.dept_id = e1.dept_id) AS dept_avg 
FROM employees e1;

-- Q64: Find the most recent order for each customer using subquery
SELECT * FROM orders o 
WHERE order_date = (
    SELECT MAX(order_date) FROM orders WHERE customer_id = o.customer_id
);

-- Q65: Find employees whose salary is above all employees in HR department
SELECT * FROM employees 
WHERE salary > ALL (
    SELECT salary FROM employees e 
    JOIN departments d ON e.dept_id = d.dept_id 
    WHERE d.dept_name = 'HR' AND salary IS NOT NULL
);

-- ==========================================
-- SECTION 5: WINDOW FUNCTIONS (Questions 66-80)
-- ==========================================

-- Q66: ROW_NUMBER - Assign row numbers to employees by salary
SELECT first_name, salary, 
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num 
FROM employees;

-- Q67: RANK - Rank employees by salary (with gaps)
SELECT first_name, salary, 
    RANK() OVER (ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- Q68: DENSE_RANK - Rank employees by salary (without gaps)
SELECT first_name, salary, 
    DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank 
FROM employees;

-- Q69: PARTITION BY - Rank employees within each department
SELECT first_name, dept_id, salary, 
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dept_rank 
FROM employees;

-- Q70: Running total of salaries
SELECT first_name, salary, 
    SUM(salary) OVER (ORDER BY emp_id) AS running_total 
FROM employees;

-- Q71: Calculate running total of order amounts by date
SELECT order_id, order_date, total_amount, 
    SUM(total_amount) OVER (ORDER BY order_date) AS running_total 
FROM orders;

-- Q72: LAG - Get previous employee salary
SELECT first_name, salary, 
    LAG(salary) OVER (ORDER BY emp_id) AS prev_salary 
FROM employees;

-- Q73: LEAD - Get next employee salary
SELECT first_name, salary, 
    LEAD(salary) OVER (ORDER BY emp_id) AS next_salary 
FROM employees;

-- Q74: Calculate salary difference from previous employee
SELECT first_name, salary, 
    salary - LAG(salary) OVER (ORDER BY emp_id) AS salary_diff 
FROM employees;

-- Q75: FIRST_VALUE - Get highest salary in each department
SELECT first_name, dept_id, salary, 
    FIRST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC) AS highest_in_dept 
FROM employees;

-- Q76: LAST_VALUE - Get lowest salary in each department
SELECT first_name, dept_id, salary, 
    LAST_VALUE(salary) OVER (
        PARTITION BY dept_id ORDER BY salary DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_in_dept 
FROM employees;

-- Q77: NTILE - Divide employees into 4 salary quartiles
SELECT first_name, salary, 
    NTILE(4) OVER (ORDER BY salary) AS quartile 
FROM employees;

-- Q78: Percentage of total salary
SELECT first_name, salary, 
    ROUND(salary * 100.0 / SUM(salary) OVER (), 2) AS salary_percentage 
FROM employees;

-- Q79: Moving average of last 3 orders
SELECT order_id, order_date, total_amount, 
    AVG(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg 
FROM orders;

-- Q80: Find top 2 earners in each department
SELECT * FROM (
    SELECT first_name, dept_id, salary, 
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn 
    FROM employees
) ranked 
WHERE rn <= 2;

-- ==========================================
-- SECTION 6: CTEs AND SET OPERATIONS (Questions 81-90)
-- ==========================================

-- Q81: CTE - Find employees with above-average salary
WITH avg_salary AS (
    SELECT AVG(salary) AS avg_sal FROM employees
)
SELECT e.* FROM employees e, avg_salary 
WHERE e.salary > avg_salary.avg_sal;

-- Q82: Recursive CTE - Employee hierarchy
WITH RECURSIVE emp_hierarchy AS (
    SELECT emp_id, first_name, manager_id, 1 AS level 
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.first_name, e.manager_id, h.level + 1 
    FROM employees e 
    JOIN emp_hierarchy h ON e.manager_id = h.emp_id
)
SELECT * FROM emp_hierarchy ORDER BY level, emp_id;

-- Q83: Multiple CTEs - Department statistics
WITH dept_counts AS (
    SELECT dept_id, COUNT(*) AS emp_count FROM employees GROUP BY dept_id
),
dept_salaries AS (
    SELECT dept_id, AVG(salary) AS avg_salary FROM employees GROUP BY dept_id
)
SELECT d.dept_name, dc.emp_count, ds.avg_salary 
FROM departments d 
JOIN dept_counts dc ON d.dept_id = dc.dept_id 
JOIN dept_salaries ds ON d.dept_id = ds.dept_id;

-- Q84: UNION - Combine employees and customers names
SELECT first_name, last_name, 'Employee' AS type FROM employees
UNION
SELECT first_name, last_name, 'Customer' AS type FROM customers;

-- Q85: UNION ALL - Include duplicates
SELECT city FROM customers
UNION ALL
SELECT location FROM departments;

-- Q86: INTERSECT - Find cities that are both customer cities and dept locations
SELECT city FROM customers
INTERSECT
SELECT location FROM departments;

-- Q87: EXCEPT - Find customer cities that are not department locations
SELECT city FROM customers
EXCEPT
SELECT location FROM departments;

-- Q88: CTE with window function - Rank products by sales
WITH product_sales AS (
    SELECT product_id, SUM(quantity * unit_price) AS total_sales 
    FROM order_items GROUP BY product_id
)
SELECT p.product_name, ps.total_sales,
    RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank 
FROM products p 
JOIN product_sales ps ON p.product_id = ps.product_id;

-- Q89: CTE for year-over-year comparison
WITH yearly_sales AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year, 
           SUM(total_amount) AS total_sales 
    FROM orders GROUP BY EXTRACT(YEAR FROM order_date)
)
SELECT year, total_sales, 
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales 
FROM yearly_sales;

-- Q90: CTE to find duplicate emails
WITH email_counts AS (
    SELECT email, COUNT(*) AS cnt FROM customers GROUP BY email
)
SELECT * FROM email_counts WHERE cnt > 1;

-- ==========================================
-- SECTION 7: DATA MODIFICATION & ADVANCED (Questions 91-100)
-- ==========================================

-- Q91: UPDATE with JOIN - Give 10% raise to employees in Engineering
UPDATE employees e 
SET salary = salary * 1.10 
FROM departments d 
WHERE e.dept_id = d.dept_id AND d.dept_name = 'Engineering';

-- Q92: DELETE with subquery - Delete orders with no items
DELETE FROM orders 
WHERE order_id NOT IN (SELECT DISTINCT order_id FROM order_items);

-- Q93: INSERT with SELECT - Archive completed orders
-- CREATE TABLE orders_archive AS SELECT * FROM orders WHERE 1=0;
-- INSERT INTO orders_archive SELECT * FROM orders WHERE status = 'completed';

-- Q94: UPSERT (INSERT ON CONFLICT) - Insert or update product
INSERT INTO products (product_id, product_name, category_id, price, stock_quantity) 
VALUES (1, 'Gaming Laptop', 1, 1299.99, 30)
ON CONFLICT (product_id) 
DO UPDATE SET price = EXCLUDED.price, stock_quantity = EXCLUDED.stock_quantity;

-- Q95: CASE statement - Categorize employees by salary
SELECT first_name, salary,
    CASE 
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 70000 THEN 'Medium'
        WHEN salary IS NOT NULL THEN 'Low'
        ELSE 'Unknown'
    END AS salary_category 
FROM employees;

-- Q96: COALESCE - Handle NULL values
SELECT first_name, COALESCE(salary, 0) AS salary_or_zero FROM employees;

-- Q97: NULLIF - Avoid division by zero
SELECT product_name, price, stock_quantity,
    price / NULLIF(stock_quantity, 0) AS price_per_item 
FROM products;

-- Q98: String functions - Format employee info
SELECT 
    UPPER(first_name) AS upper_name,
    LOWER(email) AS lower_email,
    LENGTH(first_name) AS name_length,
    SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1) AS email_username 
FROM employees;

-- Q99: Date functions - Calculate employee tenure
SELECT first_name, hire_date,
    AGE(CURRENT_DATE, hire_date) AS tenure,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_worked,
    DATE_PART('year', CURRENT_DATE) - DATE_PART('year', hire_date) AS years_simple 
FROM employees;

-- Q100: Complex query - Top customers by total spend with rank
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.city,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent 
    FROM customers c 
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
    GROUP BY c.customer_id, c.first_name, c.last_name, c.city
)
SELECT 
    customer_name,
    city,
    order_count,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC NULLS LAST) AS spending_rank,
    ROUND(total_spent * 100.0 / SUM(total_spent) OVER (), 2) AS percentage_of_total 
FROM customer_spending 
ORDER BY spending_rank;

-- ============================================
-- BONUS: COMMON INTERVIEW CONCEPTS
-- ============================================

-- Find Nth highest salary (parameterized)
-- For 3rd highest:
SELECT DISTINCT salary FROM employees 
ORDER BY salary DESC 
LIMIT 1 OFFSET 2;

-- Find duplicate records
SELECT first_name, last_name, COUNT(*) 
FROM employees 
GROUP BY first_name, last_name 
HAVING COUNT(*) > 1;

-- Delete duplicate records keeping one
-- DELETE FROM employees WHERE emp_id NOT IN (
--     SELECT MIN(emp_id) FROM employees GROUP BY first_name, last_name, email
-- );

-- Pivot-like query - Count orders by status per month
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending,
    COUNT(*) FILTER (WHERE status = 'shipped') AS shipped,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled 
FROM orders 
GROUP BY DATE_TRUNC('month', order_date);

-- Find gaps in sequential IDs
SELECT emp_id + 1 AS gap_start 
FROM employees e 
WHERE NOT EXISTS (SELECT 1 FROM employees WHERE emp_id = e.emp_id + 1)
AND emp_id < (SELECT MAX(emp_id) FROM employees);

-- Running difference
SELECT order_id, order_date, total_amount,
    total_amount - LAG(total_amount, 1, 0) OVER (ORDER BY order_date) AS diff_from_prev 
FROM orders;

-- Second highest salary (DENSE_RANK / subquery)
SELECT MAX(salary) AS second_highest FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Employees earning more than their manager
SELECT e.first_name, e.last_name, e.salary AS emp_sal, m.salary AS mgr_sal
FROM employees e
JOIN employees m ON e.manager_id = m.emp_id
WHERE e.salary > m.salary;

-- Department with highest total salary
SELECT d.dept_name, SUM(e.salary) AS total_sal
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_sal DESC
LIMIT 1;

-- Employees with no manager (top-level)
SELECT * FROM employees WHERE manager_id IS NULL;

-- Running total (cumulative sum)
SELECT order_id, order_date, total_amount,
    SUM(total_amount) OVER (ORDER BY order_date) AS running_total
FROM orders;

-- Top N per group (e.g. top 2 earners per department)
SELECT * FROM (
    SELECT e.*, ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC NULLS LAST) AS rn
    FROM employees e
) t WHERE rn <= 2;

-- Self-join: employees and their manager names
SELECT e.first_name AS emp, e.last_name AS emp_last, m.first_name AS mgr_first, m.last_name AS mgr_last
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Customers who never placed an order
SELECT c.* FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Products never ordered
SELECT p.* FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.item_id IS NULL;

-- Month-over-month growth (percentage change)
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS revenue,
    LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)) AS prev_revenue,
    ROUND(100.0 * (SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)))
        / NULLIF(LAG(SUM(total_amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)), 0), 2) AS pct_change
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

-- DENSE_RANK vs RANK (salary ranking)
SELECT first_name, last_name, salary,
    RANK() OVER (ORDER BY salary DESC NULLS LAST) AS rank_sal,
    DENSE_RANK() OVER (ORDER BY salary DESC NULLS LAST) AS dense_rank_sal
FROM employees;

-- Moving average (e.g. 3-order window)
SELECT order_id, order_date, total_amount,
    AVG(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM orders;

-- Find employees hired in same year as another employee (pair)
SELECT a.emp_id, a.first_name, a.last_name, a.hire_date,
       b.emp_id AS other_emp_id, b.first_name AS other_first, b.last_name AS other_last
FROM employees a
JOIN employees b ON DATE_TRUNC('year', a.hire_date) = DATE_TRUNC('year', b.hire_date) AND a.emp_id < b.emp_id;

-- Count distinct with condition (e.g. distinct customers who completed orders)
SELECT COUNT(DISTINCT customer_id) FROM orders WHERE status = 'completed';

-- First and last order per customer
SELECT customer_id,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer_id;

-- Percentage of total (e.g. each department's share of total salary)
SELECT d.dept_name, SUM(e.salary) AS dept_sal,
    ROUND(100.0 * SUM(e.salary) / SUM(SUM(e.salary)) OVER (), 2) AS pct_of_total
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Correlated subquery: employees earning more than department average
SELECT e.first_name, e.last_name, e.salary, e.dept_id
FROM employees e
WHERE e.salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id);

-- EXISTS: departments that have at least one employee with salary > 70000
SELECT d.dept_name FROM departments d
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id AND e.salary > 70000);

-- UNION vs UNION ALL (all unique cities from customers and employees' department locations - illustrative)
SELECT city AS place FROM customers WHERE city IS NOT NULL
UNION
SELECT location AS place FROM departments WHERE location IS NOT NULL;

-- COALESCE / NULL handling (show salary or 0)
SELECT first_name, last_name, COALESCE(salary, 0) AS salary_display FROM employees;

-- Case expression: salary bands
SELECT first_name, last_name, salary,
    CASE 
        WHEN salary >= 90000 THEN 'High'
        WHEN salary >= 60000 THEN 'Mid'
        WHEN salary IS NOT NULL THEN 'Low'
        ELSE 'Unknown'
    END AS salary_band
FROM employees;

-- Lead: next order amount per customer
SELECT order_id, customer_id, order_date, total_amount,
    LEAD(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_amount
FROM orders;
;