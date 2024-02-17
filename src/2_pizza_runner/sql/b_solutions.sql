/* Pizza Runner */


-- Setup --

-- Create a new duckdb session using the setup script (`duckdb -init setup.sql`)


-- B. Runner and Customer Experience --

-- 1. How many runners signed up for each 1-week period? Assume the first week started on 2021-01-01

-- Expected output:

-- | week_start_date | n_runners_registered |
-- |-----------------|----------------------|
-- | 2021-01-01      | 2                    |
-- | 2021-01-08      | 1                    |
-- | 2021-01-15      | 1                    |

select
    date_trunc('week', registration_date) + 4 as week_start_date
    , count(*) as n_runners_registered

from pizza_runner.stg_runners

group by 1

order by 1
;


-- 2. What was the average time in minutes it took for each runner to arrive at Pizza Runner HQ to pickup the order?

-- Expected output:

-- | runner_id | avg_pickup_min |
-- |-----------|----------------|
-- | 1         | 14.0           |
-- | 2         | 19.7           |
-- | 3         | 10.0           |

with orders_deduped as (

    select
        order_id
        , runner_id
        
        , extract('minute' from pickup_timestamp - order_timestamp) as pickup_min

    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_runner_orders
        using (order_id)

    where pickup_timestamp is not null

    group by 1, 2, 3

)

, final as (

    select
        runner_id
        , round(avg(pickup_min), 1) as avg_pickup_min

    from orders_deduped

    group by 1

    order by 1

)

select * from final
;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- Expected output:

-- | order_id | pickup_min | n_pizzas | pickup_min_per_pizza |
-- |----------|------------|----------|----------------------|
-- | 1        | 10         | 1        | 10.0                 |
-- | 2        | 10         | 1        | 10.0                 |
-- | 5        | 10         | 1        | 10.0                 |
-- | 7        | 10         | 1        | 10.0                 |
-- | 10       | 15         | 2        | 7.5                  |
-- | 8        | 20         | 1        | 20.0                 |
-- | 3        | 21         | 2        | 10.5                 |
-- | 4        | 29         | 3        | 9.7                  |

with orders_counted as (

    select
        order_id

        , extract('minute' from pickup_timestamp - order_timestamp) as pickup_min
        , count(*) as n_pizzas

    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_runner_orders
        using (order_id)

    where pickup_timestamp is not null

    group by 1, 2

)

, final as (

    select
        *
        , round(1.0 * pickup_min / n_pizzas, 1) as pickup_min_per_pizza

    from orders_counted

    order by 2, 3

)

select * from final
;


-- 4. What was the average distance travelled for each customer?

-- Expected output:

-- | customer_id | avg_delivery_km |
-- |-------------|-----------------|
-- | 101         | 20.0            |
-- | 102         | 18.4            |
-- | 103         | 23.4            |
-- | 104         | 10.0            |
-- | 105         | 25.0            |

with orders_deduped as (

    select
        order_id
        , customer_id
        , delivery_km

    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_runner_orders
        using (order_id)

    where is_delivered

    group by 1, 2, 3

)

, final as (

    select
        customer_id
        , round(avg(delivery_km), 1) as avg_delivery_km

    from orders_deduped

    group by 1

    order by 1

)

select * from final
;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

-- Expected output:

-- | diff_delivery_min |             
-- |-------------------|             
-- | 30                | 

select
    max(delivery_min) - min(delivery_min) as diff_delivery_min

from pizza_runner.stg_runner_orders

where is_delivered
;


-- 6. What was the average speed for each runner for each delivery? Do you notice any trend for these values?

-- Expected output:

-- | order_id | runner_id | pickup_hour | delivery_km | delivery_km_hr | n_items |
-- |----------|-----------|-------------|-------------|----------------|---------|
-- | 3        | 1         | 0           | 13.4        | 40.2           | 2       |
-- | 8        | 2         | 0           | 23.4        | 93.6           | 1       |
-- | 4        | 2         | 13          | 23.4        | 35.1           | 3       |
-- | 10       | 1         | 18          | 10.0        | 60.0           | 2       |
-- | 1        | 1         | 18          | 20.0        | 37.5           | 1       |
-- | 2        | 1         | 19          | 20.0        | 44.4           | 1       |
-- | 5        | 3         | 21          | 10.0        | 40.0           | 1       |
-- | 7        | 2         | 21          | 25.0        | 60.0           | 1       |

select
    order_id
    , runner_id
    
    , extract('hour' from pickup_timestamp) as pickup_hour
    , delivery_km
    , round(delivery_km / (delivery_min / 60.0), 1) as delivery_km_hr
    , count(*) as n_items

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

where is_delivered

group by all

order by 3, 4
;


-- 7. What is the successful delivery percentage for each runner?

-- Expected output:

-- | runner_id | pct_orders_delivered |
-- |-----------|----------------------|
-- | 1         | 100.0                |
-- | 2         | 75.0                 |
-- | 3         | 50.0                 |

select
    runner_id

    , 100.0
        * count(*) filter (where is_delivered)
        / count(*)
    as pct_orders_delivered

from pizza_runner.stg_runner_orders

group by 1

order by 1
;
