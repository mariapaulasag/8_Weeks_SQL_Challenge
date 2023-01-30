DROP SCHEMA IF EXISTS dannys_diner;
CREATE SCHEMA dannys_diner;
USE dannys_diner;
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
DROP TABLE IF EXISTS members;
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

/* --------------------
   Case Study #1 - Danny's Diner
   --------------------*/
USE dannys_diner;
-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_amount
FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
GROUP BY customer_id;

/* The total amount the customer A spent at the restaurant is $76, customer B is $74 and customer C is $36 */

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, count(DISTINCT order_date) as number_of_visits
FROM sales 
GROUP BY customer_id;

/* The customer A visited the restaurant 4 days, client B, 6 days and the buyer C, 2 days */

-- 3. What was the first item from the menu purchased by each customer?
SELECT s.customer_id, s.order_date, m.product_name
FROM sales s
	JOIN menu m 
		USING(product_id)
			WHERE s.order_date IN (SELECT MIN(order_date)
				FROM sales
    GROUP BY customer_id);
    
/* The first item purchased by the customer A was Sushi and Curry, from client B was Curry and for C was Ramen */

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, count(s.product_id) as number_of_items
FROM menu m
	JOIN sales s
		ON m.product_id=s.product_id
GROUP BY s.product_id,product_name
ORDER BY number_of_items DESC
LIMIT 1;
/* The most frequently ordered item is ramen, it has been ordered 8 times.*/ 

-- 5. Which item was the most popular for each customer?
SELECT s.customer_id, s.product_id, m.product_name
FROM (
    SELECT customer_id, product_id,
        RANK () OVER (PARTITION BY customer_id ORDER BY count(product_id) DESC ) AS rank_p
    FROM sales s
    GROUP BY customer_id,product_id
    ORDER BY  COUNT(s.customer_id) DESC) AS s
		LEFT JOIN  menu m 
			ON s.product_id = m.product_id
				WHERE  rank_p = 1;

/* Client A and C prefer Ramen and B doesnt have a prefered item*/

-- 6. Which item was purchased first by the customer after they became a member?
SELECT s.* , mem.join_date, TIMESTAMPDIFF(DAY,join_date,order_date) as diff_date, m.product_name
FROM sales s
	JOIN members mem
		ON s.customer_id = mem.customer_id
			INNER JOIN menu m
				ON s.product_id = m.product_id
				HAVING diff_date >= 0
ORDER BY diff_date,customer_id
LIMIT 2;
/*The first item that customer A bought after becoming a member was Curry and for B Sushi, customer C has not become a member */

-- 7. Which item was purchased just before the customer became a member?
SELECT s.* , mem.join_date, TIMESTAMPDIFF(DAY,join_date,order_date) as diff_date, m.product_name
FROM sales s
	JOIN members mem
		ON s.customer_id = mem.customer_id
			INNER JOIN menu m
				ON s.product_id = m.product_id
					HAVING diff_date <= 0
ORDER BY diff_date,customer_id
LIMIT 5;
/* Before customer B became a member he bought Curry, customer A bought Sushi .*/ 

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, count(DISTINCT s.product_id) AS Items, SUM(m.price) as Sales
FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
			JOIN members mem
				ON s.customer_id = mem.customer_id
					WHERE s.order_date < mem.join_date
GROUP BY customer_id;

/* Member A spent $25 and bought two items, while member B spent $40 on two products. */

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, 
SUM(m.price *(CASE 
	WHEN m.product_id = 1 THEN 20 
	ELSE  10
END)) AS Points_earned
FROM sales s
	JOIN menu m 
		ON s.product_id = m.product_id
GROUP BY customer_id;
/*Customer A would have 860 points, customer B would have 940 points and finally customer C would have 360 points.*/

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM(Price * 
(CASE WHEN s.order_date >= mem.join_date AND  order_date <= mem.join_date + 7 THEN 20 ELSE 10 END)) AS total_points
FROM sales s
	JOIN members mem
		ON s.customer_id = mem.customer_id
			INNER JOIN menu m
				ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* Client A had 1.270 points and client B 840 points */ 