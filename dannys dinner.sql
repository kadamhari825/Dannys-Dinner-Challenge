-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, 
       SUM(price) AS amount_spent
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;


-- 2.How many days has each customer visited the restaurant?
SELECT customer_id, 
       count(distinct(order_date)) AS visit_count
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 3.What was the first item from the menu purchased by each customer?
SELECT ID, 
      product_name FROM (
              SELECT sales.customer_id AS ID, 
                     product_name, 
                     ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) rnk 
			  FROM SALES
			  JOIN menu ON sales.product_id = menu.product_id) temp
WHERE rnk  = 1;


-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name AS  item_name, 
       COUNT(*) AS orders
FROM sales JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY orders DESC limit 1;

-- 5.Which item was the most popular for each customer?
SELECT customer_id,
       product_name , 
       orders        FROM (
                        SELECT customer_id, 
								product_name, 
                                count(product_name) orders,
                                DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY count(product_name) DESC) rnk
                        FROM sales JOIN menu ON sales.product_id = menu.product_id
                        GROUP BY customer_id,product_name) temp 
WHERE rnk = 1 ;

-- 6.Which item was purchased first by the customer after they became a member?
WITH cte AS (
      SELECT sales.customer_id, 
             order_date, 
             join_date, 
             abs(datediff(order_date,join_date)) AS diff,
              product_name 
      from sales 
      JOIN menu ON sales.product_id = menu.product_id 
	  JOIN members ON members.customer_id = sales.customer_id) 
 
 SELECT customer_id, 
       product_name FROM (
                       select * ,
                       dense_rank() over(partition by customer_id order by diff) rnk 
                       from cte) temp 
 WHERE rnk = 1;
 
 -- 7.Which item was purchased just before the customer became a member?
WITH cte AS (
            SELECT sales.customer_id , 
                  order_date, 
                  join_date, 
                  ABS(datediff(order_date,join_date)) AS diff,
				  product_name,
			      RANK() OVER(partition by customer_id order by abs(datediff(order_date,join_date))) AS rnk
			FROM sales JOIN menu ON sales.product_id = menu.product_id 
			JOIN members ON sales.customer_id = members.customer_id
			WHERE datediff(order_date,join_date) < 0)

SELECT customer_id, product_name FROM cte WHERE rnk = 1;

-- 8 What is the total items and amount spent for each member before they became a member?
WITH cte AS(
            SELECT sales.customer_id , 
                  order_date, 
                  join_date, 
                  (datediff(order_date,join_date)),
				  product_name,
			      RANK() OVER(partition by customer_id order by abs(datediff(order_date,join_date))) rnk,
                  price
			FROM sales JOIN menu ON sales.product_id = menu.product_id JOIN members ON sales.customer_id = members.customer_id
            WHERE datediff(order_date,join_date) < 0)

SELECT customer_id , 
       sum(price) AS amount_spent, 
       count(product_name) AS item_count 
FROM cte 
GROUP BY customer_id;

-- 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, 
        SUM((CASE WHEN product_name = 'sushi' THEN price * 20 ELSE price * 10 END)) AS total_points
 FROM sales
 JOIN menu ON sales.product_id = menu.product_id
 GROUP BY customer_id;
 
/*
 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?                                                 */

WITH cte AS (
          SELECT sales.customer_id, 
                 price, 
                 order_date, 
                 join_date,
				 date_add(join_date, INTERVAL 6 DAY ) premium_week 
            FROM sales JOIN menu ON sales.product_id = menu.product_id 
			JOIN members ON members.customer_id = sales.customer_id)
         
SELECT customer_id, 
       SUM(CASE WHEN order_date BETWEEN join_date AND premium_week THEN price * 20 ELSE price * 10 END ) AS total_points 
FROM cte
WHERE order_date < '2021-01-31'
GROUP BY customer_id
ORDER BY customer_id;

-- 11

WITH cte AS (
          SELECT sales.customer_id,
                 product_name, 
                 order_date, 
                 join_date, 
                 price,
                 (CASE when join_date is null THEN 'N'
                       WHEN order_date < join_date THEN 'N' ELSE 'Y' END) as members
          FROM sales 
          LEFT JOIN members ON sales.customer_id = members.customer_id 
			   JOIN menu ON sales.product_id = menu.product_id)

SELECT *, 
     CASE WHEN members = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, members ORDER BY order_date ) ELSE null END AS rnk
from cte;
 
 
 

 

            
            
 


