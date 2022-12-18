SET search_path = pizza_runner;

/* How many pizzas were ordered? 28 */
SELECT COUNT(*)
FROM customer_orders_c;

/* How many unique customer orders were made? 10 */
SELECT COUNT(DISTINCT order_id) AS TotalOrders
FROM customer_orders_C;

/* How many successful orders were delivered by each runner? 4,3,1 */
SELECT COUNT(DISTINCT c.order_id) AS successful_orders, r.runner_id
FROM customer_orders_c c
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND cancellation IS NULL
GROUP BY runner_id;

/* How many of each type of pizza was delivered? 18 Meat, 6 Veg */
SELECT COUNT(c.pizza_id), n.pizza_name
FROM customer_orders_c C
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND cancellation IS NULL
         INNER JOIN pizza_names n
                    ON c.pizza_id = n.pizza_id
GROUP BY n.pizza_name;

/* How many Vegetarian and Meatlovers were ordered by each customer? */
SELECT COUNT(c.pizza_id), n.pizza_name, c.customer_id
FROM customer_orders_c C
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND cancellation IS NULL
         INNER JOIN pizza_names n
                    ON c.pizza_id = n.pizza_id
GROUP BY n.pizza_name, c.customer_id;

/* What was the maximum number of pizzas delivered in a single order? 6 pizzas by order_id 4*/
SELECT COUNT(c.pizza_id) AS total_delivered, c.order_id
FROM customer_orders_c C
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND cancellation IS NULL
GROUP BY c.order_id
ORDER BY total_delivered DESC
LIMIT 1;

/* For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */
SELECT c.customer_id,
       SUM(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 ELSE 0 END) AS toppings_changed,
       SUM(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 ELSE 0 END)        AS no_changes
FROM customer_orders_c c
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND r.distance IS NOT NULL
GROUP BY c.customer_id;

/* How many pizzas were delivered that had both exclusions and extras? */
SELECT SUM(CASE WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN 1 ELSE 0 END) AS both_changed
FROM customer_orders_c c
         INNER JOIN runner_orders_c r
                    ON c.order_id = r.order_id AND r.distance IS NOT NULL;

/* What was the total volume of pizzas ordered for each hour of the day? */
SELECT EXTRACT(HOUR FROM order_time) AS hourly_data, COUNT(order_id) AS total_ordered
FROM customer_orders_c
GROUP BY hourly_data
ORDER BY hourly_data;

/* What was the volume of orders for each day of the week? */
SELECT TO_CHAR(order_time, 'DAY') AS day, COUNT(order_id) AS total_ordered
FROM customer_orders_c
GROUP BY day
ORDER BY day;
