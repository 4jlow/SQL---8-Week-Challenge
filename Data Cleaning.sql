SET search_path = pizza_runner;

/* Data Cleaning */
DROP TABLE IF EXISTS customer_orders_c;
CREATE TABLE customer_orders_c AS
    (SELECT *
     FROM customer_orders);

UPDATE customer_orders_c
SET exclusions = CASE WHEN exclusions = 'null' THEN NULL
                      WHEN exclusions = '' THEN NULL ELSE exclusions END,
    extras     = CASE WHEN extras = 'null' THEN NULL
                      WHEN extras = '' THEN NULL ELSE extras END;

DROP TABLE IF EXISTS runner_orders_c;
CREATE TABLE runner_orders_c AS
    (SELECT order_id,
            runner_id,
            CAST(CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS timestamp),
            CAST(CASE WHEN distance = 'null' THEN NULL
                      WHEN distance LIKE '%km' THEN TRIM(distance, 'km')
                      ELSE distance END AS FLOAT)
                AS distance,
            CAST(CASE WHEN duration = 'null' THEN NULL
                      WHEN duration LIKE '%mins' THEN TRIM(duration, 'mins')
                      WHEN duration LIKE '%minute' THEN TRIM(duration, 'minute')
                      WHEN duration LIKE '%minutes' THEN TRIM(duration, 'minutes') ELSE duration END AS
                 FLOAT),
            CASE WHEN cancellation = 'null' or cancellation = '' THEN NULL ELSE cancellation END


     FROM runner_orders);

SELECT *
FROM runner_orders_C;



