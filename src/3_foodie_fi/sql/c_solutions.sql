/* Foodie-Fi */


-- Setup --

-- Before running any query in a new session, make sure to run the setup script first


-- C. Challenge Payment --

-- 1. The Foodie-Fi team wants you to create a new `payments` table for 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
--     - REQ1: Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan
--     - REQ2: Upgrades from basic plan to pro plans are reduced by the current paid amount in that month and start immediately
--     - REQ3: Upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--     - REQ4: Once a customer churns, they will no longer make payments

-- Expected output:

-- | customer_id | payment_order | payment_date |   plan_name   | amount |
-- |-------------|---------------|--------------|---------------|--------|
-- | 1           | 1             | 2020-08-08   | basic monthly | 9.9    |
-- | 1           | 2             | 2020-09-08   | basic monthly | 9.9    |
-- | 1           | 3             | 2020-10-08   | basic monthly | 9.9    |
-- | 1           | 4             | 2020-11-08   | basic monthly | 9.9    |
-- | 1           | 5             | 2020-12-08   | basic monthly | 9.9    |
-- | 2           | 1             | 2020-09-27   | pro annual    | 199.0  |
-- | 13          | 1             | 2020-12-22   | basic monthly | 9.9    |
-- | 15          | 1             | 2020-03-24   | pro monthly   | 19.9   |
-- | 15          | 2             | 2020-04-24   | pro monthly   | 19.9   |
-- | 16          | 1             | 2020-06-07   | basic monthly | 9.9    |
-- | 16          | 2             | 2020-07-07   | basic monthly | 9.9    |
-- | 16          | 3             | 2020-08-07   | basic monthly | 9.9    |
-- | 16          | 4             | 2020-09-07   | basic monthly | 9.9    |
-- | 16          | 5             | 2020-10-07   | basic monthly | 9.9    |
-- | 16          | 6             | 2020-10-21   | pro annual    | 189.1  |
-- | 18          | 1             | 2020-07-13   | pro monthly   | 19.9   |
-- | 18          | 2             | 2020-08-13   | pro monthly   | 19.9   |
-- | 18          | 3             | 2020-09-13   | pro monthly   | 19.9   |
-- | 18          | 4             | 2020-10-13   | pro monthly   | 19.9   |
-- | 18          | 5             | 2020-11-13   | pro monthly   | 19.9   |
-- | 18          | 6             | 2020-12-13   | pro monthly   | 19.9   |
-- | 19          | 1             | 2020-06-29   | pro monthly   | 19.9   |
-- | 19          | 2             | 2020-07-29   | pro monthly   | 19.9   |
-- | 19          | 3             | 2020-08-29   | pro annual    | 199.0  |

create or replace table foodie_fi.tmp_payments as (

    with subscriptions_led as (

        select
            customer_id
            , start_date as this_date
            , plan_name as this_plan
            , price as this_price

            , lead(start_date) over first_by_customer as next_date
            , lead(plan_name) over first_by_customer as next_plan
            , lead(price) over first_by_customer as next_price

        from foodie_fi.stg_subscriptions

        join foodie_fi.stg_plans
            using (plan_id)

        where start_date >= '2020-01-01'
            and start_date <= '2020-12-31'
            and plan_name != 'trial'

        window first_by_customer as (
            partition by customer_id
            order by start_date
        )

        qualify this_plan != 'churn'
            
    )

    , subscriptions_grouped as (

        select
            customer_id
            , this_plan
            , this_price
            , this_date as start_date

            , case
                when this_plan like '%annual' and next_plan is null
                then this_date

                -- REF: REQ1
                when this_plan like '%monthly' and next_plan is null
                then '2020-12-31'::date

                -- REF: REQ2 & REQ3
                when next_price > this_price
                then next_date - 1

                -- REF: REQ4
                when next_plan = 'churn'
                then next_date
            end as end_date

        from subscriptions_led

    )

    , subscriptions_unnested as (

        select
            customer_id
            , this_plan
            , this_price

            , unnest(
                generate_series(start_date, end_date, '1 month'::interval)
            )::date as payment_date

        from subscriptions_grouped

    )

    , subscriptions_lagged as (

        select
            *
            , lag(this_plan) over first_by_customer as prev_plan
            , lag(this_price) over first_by_customer as prev_price
            , row_number() over first_by_customer as payment_order

        from subscriptions_unnested

        window first_by_customer as (
            partition by customer_id
            order by payment_date
        )

    )

    , final as (

        select
            customer_id
            , payment_order
            , payment_date
            , this_plan as plan_name

            , case
                -- REF: REQ2
                when this_plan like 'pro%' and prev_plan like 'basic%'
                then this_price - prev_price
                else this_price
            end as amount

        from subscriptions_lagged

    )

    select * from final

);

select 
    * 

from foodie_fi.tmp_payments

-- NOTE: To show only a few samples
where customer_id in (1, 2, 13, 15, 16, 18, 19)

order by customer_id, payment_order
;
