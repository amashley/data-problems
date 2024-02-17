/* Foodie-Fi */


-- Setup --

-- Before running any query in a new session, make sure to run the setup script first


-- B. Data Analysis --

-- 1. How many customers has Foodie-Fi ever had?

-- Expected output:

-- | n_customers |                                    
-- |-------------|
-- | 1000        | 

select
    count(distinct customer_id) as n_customers

from foodie_fi.stg_subscriptions
;


-- 2. What is the monthly distribution of trial plan `start_date` values? Use the start of the month as the group by value

-- Expected output:

-- | month_start_date | n_trial |                                     
-- |------------------|---------|
-- | 2020-01-01       | 88      |
-- | 2020-02-01       | 68      |
-- | 2020-03-01       | 94      |
-- | 2020-04-01       | 81      |
-- | 2020-05-01       | 88      |
-- | 2020-06-01       | 79      |
-- | 2020-07-01       | 89      |
-- | 2020-08-01       | 88      |
-- | 2020-09-01       | 87      |
-- | 2020-10-01       | 79      |
-- | 2020-11-01       | 75      |
-- | 2020-12-01       | 84      |

select
    date_trunc('month', start_date) as month_start_date
    , count(*) as n_trial

from foodie_fi.stg_subscriptions

join foodie_fi.stg_plans
    using (plan_id)

where plan_name = 'trial'

group by 1

order by 1
;


-- 3. What plan `start_date` values occur after 2020? Show the breakdown by count of events for each `plan_name`

-- Expected output:

-- |   plan_name   | n_events |
-- |---------------|----------|
-- | churn         | 71       |
-- | pro annual    | 63       |
-- | pro monthly   | 60       |
-- | basic monthly | 8        |

select
    plan_name
    , count(*) as n_events

from foodie_fi.stg_subscriptions

join foodie_fi.stg_plans
    using (plan_id)

where start_date >= '2021-01-01'

group by 1

order by 2 desc
;


-- 4. What is the count and percentage of customers who have churned rounded to 1 decimal place?

-- Expected output:

-- | n_customers_churned | pct_customers_churned |
-- |---------------------|-----------------------|
-- | 307                 | 30.7                  |

select
    count(distinct customer_id) 
        filter (where plan_name = 'churn') 
    as n_customers_churned

    , round(
        100.0
            * count(distinct customer_id) 
                filter (where plan_name = 'churn')
            / count(distinct customer_id)
        , 1
    ) as pct_customers_churned

from foodie_fi.stg_subscriptions

join foodie_fi.stg_plans
    using (plan_id)
;


-- 5. How many customers have churned straight after their initial free trial? What percentage is this rounded to the nearest whole number?

-- Expected output:

-- | n_customers_churned_after_trial | pct_customers_churned_after_trial |
-- |---------------------------------|-----------------------------------|
-- | 92                              | 9.0                               |

with subscriptions_led as (

    select
        customer_id
        , start_date
        , plan_name as this_plan

        , lead(plan_name) over first_by_customer as next_plan

    from foodie_fi.stg_subscriptions

    join foodie_fi.stg_plans
        using (plan_id)

    window first_by_customer as (
        partition by customer_id
        order by start_date
    )

)

, final as (

    select
        count(distinct customer_id)
            filter (where this_plan = 'trial' and next_plan = 'churn')
        as n_customers_churned_after_trial

        , round(
            100.0
                * count(distinct customer_id)
                    filter (where this_plan = 'trial' and next_plan = 'churn')
                / count(distinct customer_id)
        ) as pct_customers_churned_after_trial

    from subscriptions_led

)

select * from final
;


-- 6. What is the number and percentage of customers after their initial free trial?

-- Expected output:

-- |   plan_name   | n_customers_after_trial | pct_customers_after_trial |
-- |---------------|-------------------------|---------------------------|
-- | basic monthly | 546                     | 54.6                      |
-- | pro monthly   | 325                     | 32.5                      |
-- | churn         | 92                      | 9.2                       |
-- | pro annual    | 37                      | 3.7                       |

with subscriptions_led as (

    select
        customer_id
        , start_date
        , plan_name as this_plan

        , lead(plan_name) over first_by_customer as next_plan

    from foodie_fi.stg_subscriptions

    join foodie_fi.stg_plans
        using (plan_id)

    window first_by_customer as (
        partition by customer_id
        order by start_date
    )

    qualify this_plan = 'trial'

)

, final as (

    select
        next_plan as plan_name
        , count(distinct customer_id) as n_customers_after_trial

        , 100.0
            * count(distinct customer_id)
            / sum(count(distinct customer_id)) over ()
        as pct_customers_after_trial

    from subscriptions_led

    group by 1

    order by 2 desc

)

select * from final
;


-- 7. What is the customer count and percentage breakdown of all 5 `plan_name` values as of 2020-12-31?

-- Expected output:

-- |   plan_name   | n_customers | pct_customers |
-- |---------------|-------------|---------------|
-- | pro monthly   | 326         | 32.6          |
-- | churn         | 236         | 23.6          |
-- | basic monthly | 224         | 22.4          |
-- | pro annual    | 195         | 19.5          |
-- | trial         | 19          | 1.9           |

with subscriptions_ranked as (

    select
        customer_id
        , plan_name

    from foodie_fi.stg_subscriptions

    join foodie_fi.stg_plans
        using (plan_id)

    where start_date <= '2020-12-31'

    window last_by_customer as (
        partition by customer_id
        order by start_date desc
    )

    qualify rank() over last_by_customer = 1

)

, final as (

    select
        plan_name
        , count(distinct customer_id) as n_customers

        , 100.0
            * count(distinct customer_id)
            / sum(count(distinct customer_id)) over ()
        as pct_customers        

    from subscriptions_ranked

    group by 1

    order by 2 desc

)

select * from final
;


-- 8. How many customers have upgraded to an annual plan in 2020?

-- Expected output:

-- | n_customers_annual |
-- |--------------------|
-- | 195                |

select
    count(distinct customer_id) as n_customers_annual

from foodie_fi.stg_subscriptions

join foodie_fi.stg_plans
    using (plan_id)

where start_date >= '2020-01-01'
    and start_date <= '2020-12-31'
    and plan_name = 'pro annual'
;


-- 9. How many days on average does it take for a customer to an annual plan from the day they joined Foodie-Fi?

-- Expected output:

-- | avg_days_to_annual |
-- |--------------------|
-- | 105                |

select
    avg(s2.start_date - s1.start_date)::int as avg_days_to_annual

from foodie_fi.stg_subscriptions as s1

join foodie_fi.stg_plans as p1
    on s1.plan_id = p1.plan_id

join foodie_fi.stg_subscriptions as s2
    on s1.customer_id = s2.customer_id

join foodie_fi.stg_plans as p2
    on s2.plan_id = p2.plan_id

where p1.plan_name = 'trial'
    and p2.plan_name = 'pro annual'
;


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-29 days, 30-59 days)?

-- Expected output:

-- | days_to_annual | n_customers |
-- |----------------|-------------|
-- | 0 - 29         | 48          |
-- | 30 - 59        | 25          |
-- | 60 - 89        | 33          |
-- | 90 - 119       | 35          |
-- | 120 - 149      | 43          |
-- | 150 - 179      | 35          |
-- | 180 - 209      | 27          |
-- | 210 - 239      | 4           |
-- | 240 - 269      | 5           |
-- | 270 - 299      | 1           |
-- | 300 - 329      | 1           |
-- | 330 - 359      | 1           |

with subscriptions_grouped as (

    select
        floor((s2.start_date - s1.start_date) / 30)::int * 30 as lower_bound
        , count(distinct s1.customer_id) as n_customers

    from foodie_fi.stg_subscriptions as s1

    join foodie_fi.stg_plans as p1
        on s1.plan_id = p1.plan_id

    join foodie_fi.stg_subscriptions as s2
        on s1.customer_id = s2.customer_id

    join foodie_fi.stg_plans as p2
        on s2.plan_id = p2.plan_id

    where p1.plan_name = 'trial'
        and p2.plan_name = 'pro annual'

    group by 1

)

, final as (

    select
        lower_bound || ' - ' || lower_bound + 29 as days_to_annual
        , n_customers

    from subscriptions_grouped

    order by lower_bound

)

select * from final
;


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- Expected output:

-- | n_customers |
-- |-------------|
-- | 0           |

with subscriptions_led as (

    select
        customer_id
        , start_date
        , plan_name as this_plan

        , lead(plan_name) over first_by_customer as next_plan

    from foodie_fi.stg_subscriptions

    join foodie_fi.stg_plans
        using (plan_id)

    where start_date >= '2020-01-01'
        and start_date <= '2020-12-31'

    window first_by_customer as (
        partition by customer_id
        order by start_date
    )

    qualify this_plan = 'pro monthly'
        and next_plan = 'basic monthly'

)

, final as (

    select
        count(distinct customer_id) as n_customers

    from subscriptions_led

)

select * from final
;
