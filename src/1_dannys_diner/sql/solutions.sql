/* Danny's Diner */


-- Setup --

-- Create a new duckdb session using the setup script (`duckdb -init setup.sql`)


-- Questions --

-- 1. What is the total amount each customer spent at the restaurant?

-- Expected output:

-- | customer_id | total_amount |
-- |-------------|--------------|
-- | A           | 76           |
-- | B           | 74           |
-- | C           | 36           |

select
    customer_id
    , sum(price) as total_amount

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

group by 1

order by 1
;


-- 2. How many days has each customer visited the restaurant?

-- Expected output:

-- | customer_id | n_days |
-- |-------------|--------|
-- | A           | 4      |
-- | B           | 6      |
-- | C           | 2      |

select
    customer_id
    , count(distinct order_date) as n_days

from dannys_diner.stg_sales

group by 1

order by 1
;


-- 3. What was the first item from the menu purchased by each customer?

-- Expected output:

-- | customer_id | product_name |
-- |-------------|--------------|
-- | A           | curry        |
-- | A           | sushi        |
-- | B           | curry        |
-- | C           | ramen        |

select distinct
    customer_id
    , product_name

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

window first_by_customer as (
    partition by customer_id
    order by order_date
)

qualify rank() over first_by_customer = 1

order by 1, 2
;


-- 4. What is the most purchased item on the menu? How many times was it purchased by all customers?

-- Expected output:

-- | product_name | n_purchased |
-- |--------------|-------------|
-- | ramen        | 8           |

select
    product_name
    , count(*) as n_purchased

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

group by 1

window most_by_all as (
    order by count(*) desc
)

qualify rank() over most_by_all = 1

order by 1
;


-- 5. Which item was the most popular for each customer?

-- Expected output:

-- | customer_id | product_name | n_purchased |
-- |-------------|--------------|-------------|
-- | A           | ramen        | 3           |
-- | B           | curry        | 2           |
-- | B           | ramen        | 2           |
-- | B           | sushi        | 2           |
-- | C           | ramen        | 3           |

select
    customer_id
    , product_name
    , count(*) as n_purchased

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

group by 1, 2

window most_by_customer as (
    partition by customer_id
    order by count(*) desc
)

qualify rank() over most_by_customer = 1

order by 1, 2
;


-- 6. Which item was purchased first by the customer after they became a member?

-- Expected output:

-- | customer_id | product_name | order_date |
-- |-------------|--------------|------------|
-- | A           | curry        | 2021-01-07 |
-- | B           | sushi        | 2021-01-11 |

select
    customer_id
    , product_name
    , order_date

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

join dannys_diner.stg_members
    using (customer_id)

where order_date >= join_date

window first_by_customer as (
    partition by customer_id
    order by order_date
)

qualify rank() over first_by_customer = 1

order by 1, 2
;


-- 7. Which item was purchased just before the customer became a member?

-- Expected output:

-- | customer_id | product_name | order_date |
-- |-------------|--------------|------------|
-- | A           | curry        | 2021-01-01 |
-- | A           | sushi        | 2021-01-01 |
-- | B           | sushi        | 2021-01-04 |

select
    customer_id
    , product_name
    , order_date

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

join dannys_diner.stg_members
    using (customer_id)

where order_date < join_date

window last_by_customer as (
    partition by customer_id
    order by order_date desc
)

qualify rank() over last_by_customer = 1

order by 1, 2
;


-- 8. What is the total items and amount spent for each member before they became a member?

-- Expected output:

-- | customer_id | n_items | total_amount |
-- |-------------|---------|--------------|
-- | A           | 2       | 25           |
-- | B           | 3       | 40           |

select
    customer_id
    , count(*) as n_items
    , sum(price) as total_amount

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

join dannys_diner.stg_members
    using (customer_id)

where order_date < join_date

group by 1

order by 1
;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?

-- Expected output:

-- | customer_id | n_points |
-- |-------------|----------|
-- | A           | 860      |
-- | B           | 940      |
-- | C           | 360      |

select
    customer_id

    , sum(
        price * 10 * case when product_name = 'sushi' then 2 else 1 end
    ) as n_points

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

group by 1

order by 1
;


-- 10. In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi. How many points do customer A and B have at the end of January?

-- Expected output:

-- | customer_id | n_points |
-- |-------------|----------|
-- | A           | 1370     |
-- | B           | 820      |

with base as (

    select
        customer_id
        , price

        , case
            when order_date - join_date between 0 and 6
            then 2
            
            when product_name = 'sushi' 
            then 2
            
            else 1
        end as multiplier

    from dannys_diner.stg_sales

    join dannys_diner.stg_menu
        using (product_id)

    join dannys_diner.stg_members
        using (customer_id)

    where order_date <= '2021-01-31'

)

, final as (

    select
        customer_id
        , sum(price * 10 * multiplier) as n_points

    from base

    group by 1

    order by 1

)

select * from final
;


-- 11. Recreate the following table output using the available data

-- Expected output:

-- | customer_id | order_date | product_name | price | member |
-- |-------------|------------|--------------|-------|--------|
-- | A           | 2021-01-01 | curry        | 15    | N      |
-- | A           | 2021-01-01 | sushi        | 10    | N      |
-- | A           | 2021-01-07 | curry        | 15    | Y      |
-- | A           | 2021-01-10 | ramen        | 12    | Y      |
-- | A           | 2021-01-11 | ramen        | 12    | Y      |
-- | A           | 2021-01-11 | ramen        | 12    | Y      |
-- | B           | 2021-01-01 | curry        | 15    | N      |
-- | B           | 2021-01-02 | curry        | 15    | N      |
-- | B           | 2021-01-04 | sushi        | 10    | N      |
-- | B           | 2021-01-11 | sushi        | 10    | Y      |
-- | B           | 2021-01-16 | ramen        | 12    | Y      |
-- | B           | 2021-02-01 | ramen        | 12    | Y      |
-- | C           | 2021-01-01 | ramen        | 12    | N      |
-- | C           | 2021-01-01 | ramen        | 12    | N      |
-- | C           | 2021-01-07 | ramen        | 12    | N      |

select
    customer_id
    , order_date
    , product_name
    , price

    , case
        when order_date >= join_date
        then 'Y'
        else 'N'
    end as member

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

left join dannys_diner.stg_members
    using (customer_id)

order by 1, 2, 3
;


-- 12. Danny also requires further information about the `ranking` of customer products, but he purposely does not need the ranking for non-member purchases. He expects NULL ranking values for the records when customers are not yet part of the loyalty program.

-- Expected output:

-- | customer_id | order_date | product_name | price | member | ranking |
-- |-------------|------------|--------------|-------|--------|---------|
-- | A           | 2021-01-01 | curry        | 15    | N      | NULL    |
-- | A           | 2021-01-01 | sushi        | 10    | N      | NULL    |
-- | A           | 2021-01-07 | curry        | 15    | Y      | 1       |
-- | A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
-- | A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
-- | A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
-- | B           | 2021-01-01 | curry        | 15    | N      | NULL    |
-- | B           | 2021-01-02 | curry        | 15    | N      | NULL    |
-- | B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
-- | B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
-- | B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
-- | B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
-- | C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
-- | C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
-- | C           | 2021-01-07 | ramen        | 12    | N      | NULL    |

select
    customer_id
    , order_date
    , product_name
    , price

    , case
        when order_date >= join_date
        then 'Y'
        else 'N'
    end as member

    , case
        when order_date >= join_date
        then rank() over first_by_member
        else null
    end as ranking

from dannys_diner.stg_sales

join dannys_diner.stg_menu
    using (product_id)

left join dannys_diner.stg_members
    using (customer_id)

window first_by_member as (
    partition by customer_id, member
    order by order_date
)

order by 1, 2, 3
;
