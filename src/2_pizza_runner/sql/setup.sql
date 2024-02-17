/* Pizza Runner */


-- Schema --

create schema if not exists pizza_runner
;


-- Source --

create or replace view pizza_runner.src_customer_orders as (

    from read_csv(
        '../../../data/2_pizza_runner/customer_orders.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view pizza_runner.src_pizza_names as (

    from read_csv(
        '../../../data/2_pizza_runner/pizza_names.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view pizza_runner.src_pizza_recipes as (

    from read_csv(
        '../../../data/2_pizza_runner/pizza_recipes.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view pizza_runner.src_pizza_toppings as (

    from read_csv(
        '../../../data/2_pizza_runner/pizza_toppings.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view pizza_runner.src_runner_orders as (

    from read_csv(
        '../../../data/2_pizza_runner/runner_orders.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view pizza_runner.src_runners as (

    from read_csv(
        '../../../data/2_pizza_runner/runners.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);


-- Staging --

create or replace view pizza_runner.stg_pizza_names as (

    select
        pizza_id::int as pizza_id
        , pizza_name

    from pizza_runner.src_pizza_names

);

create or replace view pizza_runner.stg_pizza_recipes as (

    select
        pizza_id::int as pizza_id
        , string_split(toppings, ', ')::int[] as toppings

    from pizza_runner.src_pizza_recipes

);

create or replace view pizza_runner.stg_pizza_toppings as (

    select
        topping_id::int as topping_id
        , topping_name

    from pizza_runner.src_pizza_toppings

);

create or replace view pizza_runner.stg_runners as (

    select
        runner_id::int as runner_id
        , registration_date::date as registration_date

    from pizza_runner.src_runners

);

create or replace view pizza_runner.stg_customer_orders as (

    with sourced as (

        from pizza_runner.src_customer_orders

    )

    , cleaned as (

        select
            row_number() over () as order_item_id
            , order_id::int as order_id
            , customer_id::int as customer_id
            , pizza_id::int as pizza_id

            , case 
                when regexp_matches(exclusions, '[0-9]')
                then regexp_extract_all(exclusions, '[0-9]+')::int[]
                else []
            end as exclusions

            , case 
                when regexp_matches(extras, '[0-9]')
                then regexp_extract_all(extras, '[0-9]+')::int[]
                else []
            end as extras

            , order_time::timestamp as order_timestamp

        from sourced

    )

    , final as (
    
        select
            *
            , len(exclusions) as n_exclusions
            , len(extras) as n_extras
            , len(exclusions) + len(extras) as n_changes

        from cleaned

    )

    select * from final

);

create or replace view pizza_runner.stg_runner_orders as (

    with sourced as (

        from pizza_runner.src_runner_orders

    )

    , cleaned as (

        select
            order_id::int as order_id
            , runner_id::int as runner_id

            , try_strptime(pickup_time, '%Y-%m-%d %H:%M:%S') as pickup_timestamp

            , case  
                when regexp_matches(distance, '[0-9]')
                then regexp_extract(distance, '[0-9.]+')::float
                -- NOTE: null is used instead of 0 to prevent incorrect aggregations like avg()
                else null
            end as delivery_km

            , case  
                when regexp_matches(duration, '[0-9]')
                then regexp_extract(duration, '[0-9]+')::int
                -- NOTE: null is used instead of 0 to prevent incorrect aggregations like avg()
                else null
            end as delivery_min

            , case
                when cancellation like '%Cancellation'
                then replace(cancellation, ' Cancellation', '')
                else null
            end as cancelled_by
                
        from sourced

    )

    , final as (

        select
            *
            , cancelled_by is not null as is_cancelled
            , cancelled_by is null as is_delivered

        from cleaned

    )

    select * from final

);
