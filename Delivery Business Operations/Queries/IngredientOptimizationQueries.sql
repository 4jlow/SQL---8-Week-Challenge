SET search_path = pizza_runner;
SET TIMEZONE TO 'GMT';

/* First we want to normalize the data */
DROP TABLE IF EXISTS pizza_recipes_c;
CREATE TABLE pizza_recipes_c
(
    pizza_id   INTEGER,
    topping_id INTEGER
);
INSERT INTO pizza_recipes_c (pizza_id, topping_id)
SELECT 1, UNNEST(STRING_TO_ARRAY('1, 2, 3, 4, 5, 6, 8, 10', ',')::INTEGER[])
UNION ALL
SELECT 2, UNNEST(STRING_TO_ARRAY('4, 6, 7, 9, 11, 12', ',')::INTEGER[]);

SELECT *
FROM pizza_recipes_c;

/* What are the standard ingredients for each pizza? */
WITH cte AS (SELECT n.pizza_name, r.pizza_id, t.topping_name
             FROM pizza_recipes_c r
                      INNER JOIN pizza_names n ON n.pizza_id = r.pizza_id
                      INNER JOIN pizza_toppings t ON t.topping_id = r.topping_id
             ORDER BY n.pizza_name)
SELECT pizza_name, STRING_AGG(topping_name, ', ')
FROM CTE
GROUP BY pizza_name;

/* What was the most commonly added extra? */
SELECT extras,
       topping_name,
       COUNT(extras) AS times_ordered
FROM (SELECT order_id,
             CAST(
                     UNNEST(STRING_TO_ARRAY(extras, ', ')) AS INT
                 ) AS extras
      FROM customer_orders_c) AS extras_information
         JOIN pizza_toppings ON pizza_toppings.topping_id = extras_information.extras
GROUP BY extras,
         topping_name
ORDER BY times_ordered DESC;

/* What was the most common exclusion? */
SELECT exclusions,
       topping_name,
       COUNT(exclusions) AS times_ordered
FROM (SELECT order_id,
             CAST(
                     UNNEST(STRING_TO_ARRAY(exclusions, ', ')) AS INT
                 ) AS exclusions
      FROM customer_orders_c) AS extras_information
         JOIN pizza_toppings ON pizza_toppings.topping_id = extras_information.exclusions
GROUP BY exclusions,
         topping_name
ORDER BY times_ordered DESC;

/* Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */

/*Step 1: Assign Topping Name and Pizza Name to Exclusion and Extra Columns */
DROP VIEW IF EXISTS extras_exclusions;
CREATE VIEW extras_exclusions AS
SELECT order_id,
       customers_info.pizza_id,
       pizza_names.pizza_name,
       exclusion_col1,
       top1.topping_name AS excluded_1,
       CASE
           WHEN exclusion_col2 = '' THEN NULL
           ELSE TRIM(exclusion_col2) :: INTEGER
           END           AS exclusion_col2,
       extras_col1,
       top2.topping_name AS extra_1,
       CASE
           WHEN extras_col2 = '' THEN NULL
           ELSE TRIM(extras_col2) :: INTEGER
           END           AS extras_col2
FROM (SELECT order_id,
             pizza_id,
             SPLIT_PART(exclusions, ',', 1) AS exclusion_col1,
             SPLIT_PART(exclusions, ',', 2) AS exclusion_col2,
             SPLIT_PART(extras, ',', 1)     AS extras_col1,
             SPLIT_PART(extras, ',', 2)     AS extras_col2
      FROM customer_orders_c
      ORDER BY order_id) AS customers_info
         JOIN pizza_names ON customers_info.pizza_id = pizza_names.pizza_id
         LEFT JOIN pizza_toppings top1 ON customers_info.exclusion_col1 :: INT = top1.topping_id
         LEFT JOIN pizza_toppings top2 ON customers_info.extras_col1 :: INT = top2.topping_id;

/* Can't do Extra and Excluded Columns 2 Yet Because They have to be converted in view first */
SELECT order_id,
       CONCAT(pizza_name, ' ', exclusions, ' ', extras) AS pizza_details
FROM (WITH tabular_modifications AS (SELECT order_id,
                                            pizza_id,
                                            pizza_name,
                                            exclusion_col1,
                                            excluded_1,
                                            exclusion_col2 :: INT,
                                            t2.topping_name AS excluded_2,
                                            extras_col1,
                                            extra_1,
                                            extras_col2 :: INT,
                                            t3.topping_name AS extra_2
                                     FROM extras_exclusions t1
                                              LEFT JOIN pizza_toppings t2 ON t1.exclusion_col2 = t2.topping_id  /* We can convert here pretty easily */
                                              LEFT JOIN pizza_toppings t3 ON t1.extras_col2 = t3.topping_id)
      SELECT order_id,
             pizza_id,
             pizza_name,
             CASE
                 WHEN exclusion_col1 IS NULL THEN CONCAT(excluded_1, ' ', excluded_2)  /* concats are weird If its null, then it turns other concats as null*/
                 WHEN exclusion_col2 IS NULL THEN CONCAT('- Exclude', ' ', excluded_1)
                 ELSE CONCAT('- Exclude', ' ', excluded_1, ', ', excluded_2)            /* but if its in the middle, it gets ignored */
                 END AS exclusions,
             CASE
                 WHEN extras_col1 IS NULL THEN CONCAT(extra_1, ' ', extra_2)
                 WHEN extras_col2 IS NULL THEN CONCAT('- Extra', ' ', extra_1)
                 ELSE CONCAT('- Extra', ' ', extra_1, ', ', extra_2)
                 END AS extras
      FROM tabular_modifications) AS Modified_concat
ORDER BY order_id;





SELECT *
FROM extras_exclusions;



SELECT *
FROM customer_orders_c

SELECT * FROM pizza_toppings;