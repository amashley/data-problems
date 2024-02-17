/* Pizza Runner */


-- Setup --

-- Before running any query in a new session, make sure to run the setup script first


-- C. Ingredient Optimisation --

-- 1. What are the standard ingredients for each pizza?

-- Expected output:

-- | pizza_name  |                            main_ingredients                             |
-- |-------------|-------------------------------------------------------------------------|
-- | Meat Lovers | [BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami] |
-- | Vegetarian  | [Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes]            |

select
    pizza_name
    , list(topping_name order by topping_name) as main_ingredients

from pizza_runner.stg_pizza_recipes

join pizza_runner.stg_pizza_names
    using (pizza_id)

join pizza_runner.stg_pizza_toppings
    on list_contains(toppings, topping_id)

group by 1

order by 1
;


-- 2. What was the most commonly added extra?

-- Expected output:

-- | topping_name | n_added |
-- |--------------|---------|
-- | Bacon        | 4       |

select
    topping_name
    , count(*) as n_added

from pizza_runner.stg_customer_orders

join pizza_runner.stg_pizza_toppings
    on list_contains(extras, topping_id)

group by 1

window most_by_all as (
    order by count(*) desc
)

qualify rank() over most_by_all = 1

order by 1
;    


-- 3. What was the most common exclusion?

-- Expected output:

-- | topping_name | n_excluded |
-- |--------------|------------|
-- | Cheese       | 4          |

select
    topping_name
    , count(*) as n_excluded

from pizza_runner.stg_customer_orders

join pizza_runner.stg_pizza_toppings
    on list_contains(exclusions, topping_id)

group by 1

window most_by_all as (
    order by count(*) desc
)

qualify rank() over most_by_all = 1

order by 1
;    


-- 4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
--     - Meat Lovers
--     - Meat Lovers - Exclude Beef
--     - Meat Lovers - Extra Bacon
--     - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- Expected output:

-- | order_item_id | order_id |                           description                            |
-- |---------------|----------|------------------------------------------------------------------|
-- | 1             | 1        | Meat Lovers                                                      |
-- | 2             | 2        | Meat Lovers                                                      |
-- | 3             | 3        | Meat Lovers                                                      |
-- | 4             | 3        | Vegetarian                                                       |
-- | 5             | 4        | Meat Lovers - Exclude Cheese                                     |
-- | 6             | 4        | Meat Lovers - Exclude Cheese                                     |
-- | 7             | 4        | Vegetarian - Exclude Cheese                                      |
-- | 8             | 5        | Meat Lovers - Extra Bacon                                        |
-- | 9             | 6        | Vegetarian                                                       |
-- | 10            | 7        | Vegetarian - Extra Bacon                                         |
-- | 11            | 8        | Meat Lovers                                                      |
-- | 12            | 9        | Meat Lovers - Exclude Cheese - Extra Bacon, Chicken              |
-- | 13            | 10       | Meat Lovers                                                      |
-- | 14            | 10       | Meat Lovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

with items_mapped as (

    select
        order_item_id
        , order_id
        , pizza_name

        , string_agg(topping_name, ', ')
            filter (where list_contains(exclusions, topping_id))
        as exclusions

        , string_agg(topping_name, ', ')
            filter (where list_contains(extras, topping_id))
        as extras
        
    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_pizza_names
        using (pizza_id)

    left join pizza_runner.stg_pizza_toppings
        on list_contains(exclusions || extras, topping_id)

    group by 1, 2, 3

)

, final as (

    select
        order_item_id
        , order_id

        , pizza_name
            || coalesce(' - Exclude ' || exclusions, '')
            || coalesce(' - Extra ' || extras, '')
        as description

    from items_mapped

    order by 1

)

select * from final
;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table. Add a "2x" in front of any relevant ingredients
--     - Meat Lovers: 2xBacon, Beef, ... , Salami

-- Expected output:

-- | order_item_id | order_id |                                     description                                      |
-- |---------------|----------|--------------------------------------------------------------------------------------|
-- | 1             | 1        | Meat Lovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
-- | 2             | 2        | Meat Lovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
-- | 3             | 3        | Meat Lovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
-- | 4             | 3        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes               |
-- | 5             | 4        | Meat Lovers: BBQ Sauce, Bacon, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
-- | 6             | 4        | Meat Lovers: BBQ Sauce, Bacon, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
-- | 7             | 4        | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                       |
-- | 8             | 5        | Meat Lovers: BBQ Sauce, 2xBacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
-- | 9             | 6        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes               |
-- | 10            | 7        | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes        |
-- | 11            | 8        | Meat Lovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
-- | 12            | 9        | Meat Lovers: BBQ Sauce, 2xBacon, Beef, 2xChicken, Mushrooms, Pepperoni, Salami       |
-- | 13            | 10       | Meat Lovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
-- | 14            | 10       | Meat Lovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami                     |

with ingredients_counted as (

    select
        order_item_id
        , order_id
        , pizza_name
        , topping_name

        , count(*)
            filter (where list_contains(toppings, topping_id))
        - count(*)
            filter (where list_contains(exclusions, topping_id))
        + count(*)
            filter (where list_contains(extras, topping_id))
        as n_used

    from pizza_runner.stg_customer_orders

    join pizza_runner.stg_pizza_names
        using (pizza_id)

    join pizza_runner.stg_pizza_recipes
        using (pizza_id)

    join pizza_runner.stg_pizza_toppings
        on list_contains(toppings || exclusions || extras, topping_id)

    group by all

)

, ingredients_flagged as (

    select
        *
        , case
            when n_used > 1
            then n_used || 'x'
            else ''
        end as n_flag

    from ingredients_counted

    where n_used

)

, final as (

    select
        order_item_id
        , order_id

        , max(pizza_name)
            || ': '
            || string_agg(n_flag || topping_name, ', ' order by topping_name)
        as description

    from ingredients_flagged

    group by 1, 2

    order by 1

)

select * from final
;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas, sorted by most frequent first?

-- Expected output:

-- | topping_name | n_used |
-- |--------------|--------|
-- | Bacon        | 12     |
-- | Mushrooms    | 11     |
-- | Cheese       | 10     |
-- | Beef         | 9      |
-- | Chicken      | 9      |
-- | Pepperoni    | 9      |
-- | Salami       | 9      |
-- | BBQ Sauce    | 8      |
-- | Onions       | 3      |
-- | Peppers      | 3      |
-- | Tomato Sauce | 3      |
-- | Tomatoes     | 3      |

select
    topping_name

    , count(*)
        filter (where list_contains(toppings, topping_id))
    - count(*)
        filter (where list_contains(exclusions, topping_id))
    + count(*)
        filter (where list_contains(extras, topping_id))
    as n_used

from pizza_runner.stg_customer_orders

join pizza_runner.stg_runner_orders
    using (order_id)

join pizza_runner.stg_pizza_recipes
    using (pizza_id)

join pizza_runner.stg_pizza_toppings
    on list_contains(toppings || exclusions || extras, topping_id)

where is_delivered

group by 1

order by 2 desc, 1
;
