/* Foodie-Fi */


-- Setup --

-- Create a new duckdb session using the setup script (`duckdb -init setup.sql`)


-- A. Customer Journey --

-- 1. Based off the 8 sample customers (`customer_id` = [1, 2, 11, 13, 15, 16, 18, 19]), write a brief description about each customer’s onboarding journey.

-- Expected output:

-- | customer_id | start_date | plan_1 |    plan_2     |   plan_3    |
-- |-------------|------------|--------|---------------|-------------|
-- | 1           | 2020-08-01 | trial  | basic monthly |             |
-- | 16          | 2020-05-31 | trial  | basic monthly | pro annual  |
-- | 13          | 2020-12-15 | trial  | basic monthly | pro monthly |
-- | 11          | 2020-11-19 | trial  | churn         |             |
-- | 2           | 2020-09-20 | trial  | pro annual    |             |
-- | 18          | 2020-07-06 | trial  | pro monthly   |             |
-- | 15          | 2020-03-17 | trial  | pro monthly   | churn       |
-- | 19          | 2020-06-22 | trial  | pro monthly   | pro annual  |

select
    customer_id
    , start_date
    , plan_name as plan_1

    , coalesce(lead(plan_name, 1) over first_by_customer, '') as plan_2
    , coalesce(lead(plan_name, 2) over first_by_customer, '') as plan_3

from foodie_fi.stg_subscriptions

join foodie_fi.stg_plans
    using (plan_id)

where customer_id in (1, 2, 11, 13, 15, 16, 18, 19)

window first_by_customer as (
    partition by customer_id
    order by start_date
)

qualify rank() over first_by_customer = 1

order by 3, 4, 5
;
