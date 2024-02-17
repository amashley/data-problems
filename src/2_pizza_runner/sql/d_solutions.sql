/* Pizza Runner */


-- Setup --

-- Create a new duckdb session using the setup script (`duckdb -init setup.sql`)


-- D. Pricing and Ratings --

-- 1. If a Meat Lovers pizza costs $12, Vegetarian costs $10, and there were no charges for changes, how much money has Pizza Runner made so far if there are no delivery fees?

-- Expected output:

-- | revenue_noncharged |
-- |--------------------|
-- | 138                |

select
    sum(
        case
            when pizza_name = 'Meat Lovers' 
            then 12
            
            when pizza_name = 'Vegetarian' 
            then 10
        end
    ) as revenue_noncharged

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

join pizza_runner.stg_pizza_names
    using (pizza_id)

where is_delivered
;


-- 2. What if there was an additional $1 charge for any pizza extras?

-- Expected output:

-- | revenue_charged |
-- |-----------------|
-- | 142             |

select
    sum(
        case
            when pizza_name = 'Meat Lovers' 
            then 12
            
            when pizza_name = 'Vegetarian' 
            then 10
        end

        + n_extras * 1

    ) as revenue_charged

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

join pizza_runner.stg_pizza_names
    using (pizza_id)

where is_delivered
;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner. How would you design an additional table for this new dataset? Generate a schema for this new table, and insert your own data for ratings for each successful customer order between 1 to 5.

-- Expected output:

-- | order_id | rating |
-- |----------|--------|
-- | 1        | 2      |
-- | 2        | 4      |
-- | 3        | 5      |
-- | 4        | 1      |
-- | 5        | 3      |
-- | 7        | 3      |
-- | 8        | 4      |
-- | 10       | 4      |

create or replace table pizza_runner.tmp_runner_ratings as (

    with base as (
    
        select setseed(1)

    )

    , final as (

        select
            order_id
            , least(random() * 5 + 1, 5)::int as rating

        from pizza_runner.stg_runner_orders

        where is_delivered

    )

    select * from final

);

select * from pizza_runner.tmp_runner_ratings
;


-- 4. Using your newly generated table, can you join all of the information together to form a table which has the following information for successful deliveries?
--     - `customer_id`
--     - `order_id`
--     - `runner_id`
--     - `rating`
--     - `order_time`
--     - `pickup_time`
--     - Time between order and pickup
--     - Delivery duration
--     - Average speed
--     - Total number of pizzas
    
-- Expected output:

-- | customer_id | order_id | runner_id | rating |   order_timestamp   |  pickup_timestamp   | pickup_min | delivery_min | delivery_km_hr | n_pizzas_delivered |
-- |-------------|----------|-----------|--------|---------------------|---------------------|------------|--------------|----------------|--------------------|
-- | 101         | 1        | 1         | 2      | 2021-01-01 18:05:02 | 2021-01-01 18:15:34 | 10         | 32           | 37.5           | 1                  |
-- | 101         | 2        | 1         | 4      | 2021-01-01 19:00:52 | 2021-01-01 19:10:54 | 10         | 27           | 44.4           | 1                  |
-- | 102         | 3        | 1         | 5      | 2021-01-02 23:51:23 | 2021-01-03 00:12:37 | 21         | 20           | 40.2           | 2                  |
-- | 103         | 4        | 2         | 1      | 2021-01-04 13:23:46 | 2021-01-04 13:53:03 | 29         | 40           | 35.1           | 3                  |
-- | 104         | 5        | 3         | 3      | 2021-01-08 21:00:29 | 2021-01-08 21:10:57 | 10         | 15           | 40.0           | 1                  |
-- | 105         | 7        | 2         | 3      | 2021-01-08 21:20:29 | 2021-01-08 21:30:45 | 10         | 25           | 60.0           | 1                  |
-- | 102         | 8        | 2         | 4      | 2021-01-09 23:54:33 | 2021-01-10 00:15:02 | 20         | 15           | 93.6           | 1                  |
-- | 104         | 10       | 1         | 4      | 2021-01-11 18:34:49 | 2021-01-11 18:50:20 | 15         | 10           | 60.0           | 2                  |

select
    customer_id
    , order_id
    , runner_id
    , rating
    , order_timestamp
    , pickup_timestamp

    , extract('minute' from pickup_timestamp - order_timestamp) as pickup_min
    , delivery_min
    , round(delivery_km / (delivery_min / 60.0), 1) as delivery_km_hr
    , count(*) as n_pizzas_delivered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

join pizza_runner.tmp_runner_ratings
    using (order_id)

where is_delivered

group by all

order by 2
;


-- 5. If a Meat Lovers pizza was $12, Vegetarian was $10 fixed prices with no cost for extras, and each runner is paid $0.30 per kilometre traveled, how much money does Pizza Runner have left over after these deliveries?

-- Expected output:

-- | total_profit |
-- |--------------|
-- | 94.4         |

with orders_deduped as (

    select
        order_id
        , delivery_km * 0.3 as cost

        , sum(
            case
                when pizza_name = 'Meat Lovers' 
                then 12
                
                when pizza_name = 'Vegetarian' 
                then 10
            end
        ) as revenue

    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_runner_orders
        using (order_id)

    join pizza_runner.stg_pizza_names
        using (pizza_id)

    where is_delivered

    group by 1, 2

)

, final as (

    select
        round(sum(revenue - cost), 1) as total_profit

    from orders_deduped

)

select * from final
;
