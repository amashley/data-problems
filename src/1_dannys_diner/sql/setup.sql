/* Danny's Diner */


-- Schema --

create schema if not exists dannys_diner
;


-- Source --

create or replace view dannys_diner.src_members as (

    from read_csv(
        '../../../data/1_dannys_diner/members.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view dannys_diner.src_menu as (

    from read_csv(
        '../../../data/1_dannys_diner/menu.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);

create or replace view dannys_diner.src_sales as (

    from read_csv(
        '../../../data/1_dannys_diner/sales.csv'
        , all_varchar=true
        , auto_detect=true
        , header=true
    )

);


-- Staging --

create or replace view dannys_diner.stg_members as (

    select
        customer_id
        , join_date::date as join_date

    from dannys_diner.src_members

);

create or replace view dannys_diner.stg_menu as (

    select
        product_id::int as product_id
        , product_name
        , price::int as price

    from dannys_diner.src_menu

);

create or replace view dannys_diner.stg_sales as (

    select
        customer_id
        , order_date::date as order_date
        , product_id::int as product_id

    from dannys_diner.src_sales

);
