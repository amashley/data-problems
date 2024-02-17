/* Pizza Runner */


-- Setup --

-- Before running any query in a new session, make sure to run the setup script first


-- E. Bonus Questions --

-- 1. If Danny wants to expand his range of pizzas, how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- Expected output:

-- | pizza_id | pizza_name  |
-- |----------|-------------|
-- | 1        | Meat Lovers |
-- | 2        | Vegetarian  |
-- | 3        | Supreme     |

-- | pizza_id |                toppings                 |
-- |----------|-----------------------------------------|
-- | 1        | [1, 2, 3, 4, 5, 6, 8, 10]               |
-- | 2        | [4, 6, 7, 9, 11, 12]                    |
-- | 3        | [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] |      

create or replace table pizza_runner.tmp_pizza_names as (

    with pizzas_tested as (

        values
            (3, 'Supreme')
        
    )

    , final as (

        select * from pizza_runner.src_pizza_names

        union

        select * from pizzas_tested

        order by pizza_id

    )

    select * from final

);

select * from pizza_runner.tmp_pizza_names
;

create or replace table pizza_runner.tmp_pizza_recipes as (

    with recipes_tested as (

        select
            3 as pizza_id
            , list(topping_id)::int[] as toppings

        from pizza_runner.src_pizza_toppings

    )

    , final as (

        select * from pizza_runner.stg_pizza_recipes

        union

        select * from recipes_tested

        order by pizza_id

    )

    select * from final

);

select * from pizza_runner.tmp_pizza_recipes
;
