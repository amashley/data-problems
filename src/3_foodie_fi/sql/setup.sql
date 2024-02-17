/* Foodie-Fi */


-- Schema --

create schema if not exists foodie_fi
;


-- Source --

create or replace view foodie_fi.src_plans as (

    from read_csv(
        '../../../data/3_foodie_fi/plans.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view foodie_fi.src_subscriptions as (

    from read_csv(
        '../../../data/3_foodie_fi/subscriptions.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);


-- Staging --

create or replace view foodie_fi.stg_plans as (

    select
        plan_id::int as plan_id
        , plan_name
        , price::float as price

    from foodie_fi.src_plans

);

create or replace view foodie_fi.stg_subscriptions as (

    select
        customer_id::int as customer_id
        , plan_id::int as plan_id
        , start_date::date as start_date

    from foodie_fi.src_subscriptions

);
