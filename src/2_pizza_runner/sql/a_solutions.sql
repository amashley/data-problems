/* Pizza Runner */


-- Setup --

-- Create a new duckdb session using the setup script (`duckdb -init setup.sql`)


-- A. Pizza Metrics --

-- 1. How many pizzas were ordered?

-- Expected output:

-- | n_pizzas |                           
-- |----------|       
-- | 14       |

select
    count(*) as n_pizzas

from pizza_runner.stg_customer_orders
;


-- 2. How many unique orders were made?

-- Expected output:

-- | n_orders |                       
-- |----------|
-- | 10       |

select
    count(*) as n_orders

from pizza_runner.stg_runner_orders
;


-- 3. How many successful orders were delivered by each runner?

-- Expected output:

-- | runner_id | n_orders_delivered |                        
-- |-----------|--------------------|  
-- | 1         | 4                  |
-- | 2         | 3                  |
-- | 3         | 1                  |

select
    runner_id
    , count(*) as n_orders_delivered

from pizza_runner.stg_runner_orders

where is_delivered

group by 1

order by 1
;


-- 4. How many of each type of pizza was delivered?

-- Expected output:

-- | pizza_name  | n_delivered |
-- |-------------|-------------|
-- | Meat Lovers | 9           |
-- | Vegetarian  | 3           |

select
    pizza_name
    , count(*) as n_delivered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

join pizza_runner.stg_pizza_names
    using (pizza_id)

where is_delivered

group by 1

order by 1
;


-- 5. How many Vegetarian and Meat Lovers were ordered by each customer?

-- Expected output:

-- | customer_id | n_veg_ordered | n_meat_ordered |
-- |-------------|---------------|----------------|                 
-- | 101         | 1             | 2              |                  
-- | 102         | 1             | 2              |               
-- | 103         | 1             | 3              |
-- | 104         | 0             | 3              |                     
-- | 105         | 1             | 0              |

select
    customer_id

    , count(*) 
        filter (where pizza_name = 'Vegetarian') as n_veg_ordered
    , count(*) 
        filter (where pizza_name = 'Meat Lovers') as n_meat_ordered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_pizza_names
    using (pizza_id)

group by 1

order by 1
;


-- 6. What was the maximum number of pizzas delivered in a single order?

-- Expected output:

-- | max_pizzas_delivered |
-- |----------------------|
-- | 3                    |

select
    max(count(*)) over () as max_pizzas_delivered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

where is_delivered

group by order_id

limit 1
;


-- 7. For each customer, how many delivered pizzas had at least 1 change? How many had no changes?

-- Expected output:

-- | customer_id | n_pizzas_changed_delivered | n_pizzas_nonchanged_delivered |
-- |-------------|----------------------------|-------------------------------|
-- | 101         | 0                          | 2                             |
-- | 102         | 0                          | 3                             |
-- | 103         | 3                          | 0                             |
-- | 104         | 2                          | 1                             |
-- | 105         | 1                          | 0                             |

select
    customer_id
    
    , count(*) 
        filter (where n_changes) as n_pizzas_changed_delivered
    , count(*) 
        filter (where not n_changes) as n_pizzas_nonchanged_delivered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

where is_delivered

group by 1

order by 1
;


-- 8. How many pizzas were delivered that had both exclusions and extras?

-- Expected output:

-- | n_pizzas_changed_delivered |
-- |----------------------------|
-- | 1                          |

select
    count(*) as n_pizzas_changed_delivered

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

where is_delivered
    and n_exclusions
    and n_extras
;


-- 9. What was the total volume of pizzas ordered for each hour of the day?

-- Expected output:

-- | hour | n_pizzas_ordered |
-- |------|------------------|
-- | 11   | 1                |
-- | 13   | 3                |
-- | 18   | 3                |
-- | 19   | 1                |
-- | 21   | 3                |
-- | 23   | 3                |

select
    extract('hour' from order_timestamp) as hour
    , count(*) as n_pizzas_ordered

from pizza_runner.stg_customer_orders

group by 1

order by 1
;


-- 10. What was the volume of orders for each day of the week?

-- Expected output:

-- | dow | dow_name | n_orders |
-- |-----|----------|----------|
-- | 0   | Sunday   | 1        |
-- | 1   | Monday   | 5        |
-- | 5   | Friday   | 5        |
-- | 6   | Saturday | 3        |

select
    extract('dow' from order_timestamp) as dow
    , dayname(order_timestamp) as dow_name
    , count(order_id) as n_orders

from pizza_runner.stg_customer_orders

group by 1, 2

order by 1
;
