SELECT first_name, last_name, 'Employee' AS type FROM employees
UNION
SELECT first_name, last_name, 'Customer' AS type FROM customers;