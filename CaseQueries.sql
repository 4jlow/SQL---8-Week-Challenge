SET search_path = dannys_diner;

CREATE TEMPORARY TABLE temp_table AS
SELECT SALES.PRODUCT_ID, SALES.customer_id, SALES.order_date,
       MEMBERS.join_date, MENU.product_name, MENU.PRICE FROM SALES
INNER JOIN MENU ON SALES.product_id = MENU.product_id
INNER JOIN MEMBERS ON SALES.customer_id = MEMBERS.customer_id;

/* Amount each customer spent at restaurant: 74,76 */
SELECT SUM(PRICE), customer_id FROM temp_table
GROUP BY customer_id;

/* How many days has each customer visited the restaurant: 6 */
SELECT COUNT(order_date), customer_id FROM temp_table
GROUP BY customer_id;

/* What was the first item from the menu purchased by each customer? A: sushi and curry, B:curry */
SELECT product_name, customer_id FROM temp_table
WHERE order_date = (SELECT MIN(order_date) FROM temp_table);

/* What is the most purchased item on the menu and how many times was it purchased by all customers? 3:sushi */
SELECT COUNT(product_name), product_name FROM temp_table
WHERE product_name = (SELECT MAX(product_name) FROM temp_table)
GROUP BY product_name;

/* Which item was the most popular for each customer? A: Ramen B: Sushi*/
SELECT product_name, COUNT(product_name), customer_id FROM temp_table
GROUP BY customer_id, product_name
ORDER BY COUNT(product_name) DESC
LIMIT 2;

/* Which item was purchased first by the customer after they became a member? A: curry, B: sushi */
SELECT product_name, customer_id, order_date FROM (
    SELECT *, FIRST_VALUE(product_name) OVER (PARTITION BY customer_id ORDER BY
        order_date ASC) AS first_item
    FROM temp_table WHERE join_date <= temp_table.order_date) t
    WHERE product_name = t.first_item;

/* Which item was purchased just before the customer became a member?  Both had ramen*/
SELECT product_name, customer_id, order_date FROM (
    SELECT *, FIRST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY
        order_date DESC) AS last_date
    FROM temp_table WHERE join_date < temp_table.order_date) t
    WHERE order_date = t.last_date;

/* What is the total items and amount spent for each member before they became a member? A: 40,3 B:25,2 */
SELECT SUM(price), COUNT(product_name), customer_id FROM temp_table
WHERE order_date < join_date
GROUP BY customer_id;

/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? a:86, b:94 */
SELECT customer_id, SUM(price * (CASE WHEN product_name = 'sushi' THEN 2 ELSE 1 END)) FROM temp_table
GROUP BY customer_id;

/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi - how many points do customer A and B have at the end of January? A: 1370, B: 940 */
SELECT customer_id, SUM(price *  (CASE WHEN order_date
    BETWEEN join_date
    AND (join_date + interval '1 week')
    OR product_name = 'sushi' THEN 2 ELSE 1 END) * 10) as total_points
FROM temp_table
WHERE customer_id IN ('A', 'B') and order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY  customer_id;


SELECT * FROM temp_table