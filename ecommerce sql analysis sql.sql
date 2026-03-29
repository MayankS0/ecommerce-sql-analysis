create databASe E_commerce_Analytics;
use E_commerce_Analytics;
CREATE TABLE customers (
    customer_id INT,
    signup_date DATE,
    city VARCHAR(50)
);

CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    order_value INT
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    price INT
);


CREATE TABLE products (
    product_id INT,
    category VARCHAR(50)
);
INSERT INTO customers VALUES
(1, '2023-01-10', 'Delhi'),
(2, '2023-01-15', 'Mumbai'),
(3, '2023-02-01', 'Bangalore'),
(4, '2023-02-10', 'Delhi'),
(5, '2023-03-05', 'Pune'),
(6, '2023-03-20', 'Mumbai'),
(7, '2023-04-01', 'Delhi'),
(8, '2023-04-12', 'Bangalore');
INSERT INTO products VALUES
(101, 'Electronics'),
(102, 'Clothing'),
(103, 'Home'),
(104, 'Electronics'),
(105, 'Clothing');
INSERT INTO orders VALUES
(1001, 1, '2023-01-12', 500),
(1002, 2, '2023-01-20', 700),
(1003, 1, '2023-02-15', 300),
(1004, 3, '2023-02-20', 1000),
(1005, 4, '2023-03-01', 400),
(1006, 5, '2023-03-10', 800),
(1007, 2, '2023-03-15', 200),
(1008, 6, '2023-04-05', 900),
(1009, 7, '2023-04-10', 600),
(1010, 8, '2023-04-15', 750),
(1011, 1, '2023-04-20', 650),
(1012, 3, '2023-04-25', 500);
INSERT INTO order_items VALUES
(1001, 101, 1, 500),
(1002, 102, 2, 350),
(1003, 103, 1, 300),
(1004, 101, 2, 500),
(1005, 104, 1, 400),
(1006, 105, 2, 400),
(1007, 102, 1, 200),
(1008, 101, 1, 900),
(1009, 103, 2, 300),
(1010, 105, 3, 250),
(1011, 104, 1, 650),
(1012, 101, 1, 500);

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;

-- TASk 1
-- Q1) Find total Revenue.
SELECT SUM(order_value) AS total_revenue FROM orders;

-- Q2) Find total no of order.
SELECT COUNT(order_id) AS total_orders FROM orders;

-- Q3) Fing total customers.
SELECT COUNT(DISTINCT(customer_id)) AS total_customers FROM orders;

-- Q4) Find avg order value.
SELECT ROUND(AVG(order_value),2) AS avg_order_value FROM orders;

-- one single query for all the above 4 problems.
SELECT 
    SUM(order_value) AS total_revenue,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM orders;

-- TASk 2
-- Q1) Find new vs returning customers
WITH NEW_T AS ( 
SELECT c.customer_id,o.order_date, c.signup_date, 
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ROW_NUM 
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id)
SELECT customer_id,
CASE WHEN COUNT(ROW_NUM) >1 THEN 'RETURNINNG CUSTOMER' ELSE 'NEW CUSTOMER'
 END AS CATEGORY 
 FROM NEW_T GROUP BY customer_id
 ;

-- Q2) Top 3 customers by revenue
SELECT customer_id, SUM(order_value) AS total_revenue 
FROM orders 
GROUP BY customer_id 
ORDER BY total_revenue DESC LIMIT 3;

-- Q3) Find CLV(Customer Lifetime Value - Total revenue a customer generates 
-- over their entire relationship WITH the business)

SELECT customer_id, SUM(order_value) AS CLV FROM orders 
GROUP BY customer_id;

-- TASk 3
-- Q1) Revenue By Category
SELECT  p.category,SUM(oi.quantity*oi.price) AS total_revenue
FROM order_items oi JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.category;
 
-- Q2) Top selling product
SELECT  p.product_id ,SUM(oi.quantity*oi.price) AS total_revenue
FROM order_items oi JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id;

-- Q3) Most frequently purchASed category
SELECT  p.category,SUM(oi.quantity) AS total_products_purchsed
FROM order_items oi JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY SUM(oi.quantity) DESC LIMIT 1 ;

-- TASk 4
-- Q1) Find Monthly revenue.
SELECT DATE_FORMAT(order_date,'%Y-%m') AS month, SUM(order_value) 
FROM orders 
GROUP BY DATE_FORMAT(order_date,'%Y-%m')
ORDER BY month DESC ;

-- Q2) Running revenue (cumulative over time)
SELECT order_date, order_value, SUM(order_value) OVER(ORDER BY order_date ASC) AS running_total
 FROM orders;
 
 -- TASk 5
 -- Q1) Group customer by signup month
 SELECT customer_id,signup_date, DATE_FORMAT(signup_date,"%Y-%m") AS signup_month
 FROM customers;

 -- Q2) Track how many return each month
 
 WITH returner AS (SELECT c.customer_id,
 DATE_FORMAT(c.signup_date,"%Y-%m") AS signup_month,
 DATE_FORMAT(o.order_date,'%Y-%m') AS order_month ,
 TIMESTAMPDIFF(MONTH, signup_date, order_date) AS month_diff
 FROM orders o JOIN customers c
 ON o.customer_id = c.customer_id)
SELECT signup_month, month_diff, 
COUNT(DISTINCT(customer_id)) AS users FROM returner GROUP BY signup_month, month_diff ORDER BY signup_month, month_diff;
 
 
 -- TASk 6
 -- Q1) % of customers who made repeat purchASes
WITH NEW_T AS ( 
SELECT c.customer_id,o.order_date, c.signup_date, 
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ROW_NUM 
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id),
CAT AS( SELECT customer_id,
CASE WHEN COUNT(ROW_NUM) >1 THEN 'RETURNING CUSTOMER' ELSE 'NEW CUSTOMER'
 END AS CATEGORY 
 FROM NEW_T GROUP BY customer_id)
 SELECT (SELECT COUNT(*) FROM CAT WHERE CATEGORY = 'RETURNING CUSTOMER')*100/COUNT(*) AS return_perc 
 FROM CAT
 ;

-- Task 7
-- Q1) RFM segmentation RFM = Recency, Frequency, Monetary
WITH rfm_base AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM orders
    GROUP BY customer_id
),
rfm_calc AS (
    SELECT 
        customer_id,
        DATEDIFF('2023-05-01', last_order_date) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
new_tab AS (SELECT *,
       NTILE(3) OVER (ORDER BY recency DESC) AS r_score,
       NTILE(3) OVER (ORDER BY frequency) AS f_score,
       NTILE(3) OVER (ORDER BY monetary) AS m_score
FROM rfm_calc)
SELECT *, CASE 
    WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champions'
    WHEN r_score >= 2 AND f_score >= 2 THEN 'Loyal Customers'
    WHEN r_score = 3 AND f_score = 1 THEN 'New Customers'
    ELSE 'At Risk'
END AS segment FROM new_tab ;

 