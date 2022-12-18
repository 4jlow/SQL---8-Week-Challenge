SET search_path = pizza_runner;
SET timezone TO 'GMT';
/* How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/
WITH runners_registered AS (SELECT CONCAT('Week ',
                                          RANK() OVER (ORDER BY DATE_TRUNC('week', registration_date))) AS week_number
                            FROM runners)
SELECT week_number, COUNT(*) AS total_reg
FROM runners_registered
GROUP BY week_number
ORDER BY week_number;

/* What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order? */

WITH runners_arrival_time AS (
  SELECT
    r.runner_id,
    ROUND(
      CAST(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60 AS NUMERIC), 4) AS arrival_time_mins
  FROM runner_orders_c r
  INNER JOIN customer_orders_c c
    ON r.order_id = c.order_id
  WHERE r.duration IS NOT NULL
)
SELECT
  runner_id,
  ROUND(AVG(arrival_time_mins), 2) AS runner_avg_arrival_time_mins
FROM runners_arrival_time
GROUP BY runner_id
ORDER BY runner_id;

/* Is there any relationship between the number of pizzas and how long the order takes to prepare? */

WITH pizza_prep_rel AS(SELECT
        c.order_id, COUNT(c.order_id) as total_pizzas,
        AVG(ROUND(CAST(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60 AS NUMERIC), 4)) AS prep_mins
    FROM customer_orders_c c
    INNER JOIN runner_orders_c r
     ON r.order_id = c.order_id
    WHERE r.duration IS NOT NULL
    GROUP BY c.order_id)
SELECT total_pizzas, AVG(prep_mins)
FROM pizza_prep_rel
GROUP BY total_pizzas;

/* What was the average distance travelled for each customer? */
SELECT c.customer_id, ROUND(AVG(r.distance)::numeric,2) as avg_distance from customer_orders_c c
    INNER JOIN runner_orders_c r
        ON r.order_id = c.order_id
    WHERE r.duration IS NOT NULL
    GROUP BY c.customer_id;

/* What was the difference between the longest and shortest delivery times for all orders? 30 */
WITH distances AS
    (SELECT
        MAX(r.duration) AS max_d,
        MIN(r.duration) AS min_d
    FROM runner_orders_c r
    INNER JOIN customer_orders_c c
     ON r.order_id = c.order_id
    WHERE r.duration IS NOT NULL
              )
SELECT max_d - min_d as max_diff
    FROM distances;

/* What was the average speed for each runner for each delivery and do you notice any trend for these values? */
WITH speedy AS(
    SELECT r.order_id, r.runner_id, r.distance*60/r.duration as speed FROM runner_orders_c r
    INNER JOIN customer_orders_c c
     ON r.order_id = c.order_id
    WHERE r.duration IS NOT NULL
)
SELECT runner_id, ROUND(AVG(speed)::numeric, 2) FROM speedy
GROUP BY runner_id;

/* What is the successful delivery percentage for each runner? */
WITH cte AS(
    SELECT runner_id,
           COUNT(order_id)::numeric AS total,
           SUM(CASE WHEN distance IS NOT NULL THEN 1 ELSE 0 END)::numeric AS successes
           FROM runner_orders_c
           GROUP BY runner_id
          )
SELECT runner_id, successes/total AS percentage
FROM cte
GROUP BY runner_id;


