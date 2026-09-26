-- ============================================================
-- Assignment 7 - Window Functions
-- Student: Muhammad Subhan
-- ID: 871856
-- Database: BikeStores
-- ============================================================


-- 7.1 Sequential row number + partitioned row number by category
SELECT 
    product_id,
    product_name,
    category_id,
    list_price,
    ROW_NUMBER() OVER (ORDER BY list_price DESC) AS overall_row_num,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS category_row_num
FROM production.products
ORDER BY category_id, list_price DESC;


-- 7.2 RANK() vs DENSE_RANK() within each category
SELECT 
    product_id,
    product_name,
    category_id,
    list_price,
    RANK()       OVER (PARTITION BY category_id ORDER BY list_price DESC) AS rank_by_price,
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS dense_rank_by_price
FROM production.products
ORDER BY category_id, list_price DESC;

-- Note: RANK() and DENSE_RANK() differ when there are ties.
-- Example: If two products have the same highest price in a category,
-- RANK() gives both rank 1 and the next product rank 3.
-- DENSE_RANK() gives both rank 1 and the next product rank 2.


-- 7.3 Month-over-month revenue change per store using LAG()
WITH monthly_revenue AS (
    SELECT 
        o.store_id,
        YEAR(o.order_date)  AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
    FROM sales.orders o
    INNER JOIN sales.order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY 
        o.store_id,
        YEAR(o.order_date),
        MONTH(o.order_date)
)
SELECT 
    store_id,
    order_year,
    order_month,
    revenue AS current_month_revenue,
    LAG(revenue) OVER (
        PARTITION BY store_id 
        ORDER BY order_year, order_month
    ) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (
        PARTITION BY store_id 
        ORDER BY order_year, order_month
    ) AS revenue_difference
FROM monthly_revenue
ORDER BY store_id, order_year, order_month;


-- 7.4 NTILE(5) – divide products into 5 price bands
SELECT 
    product_name,
    list_price,
    NTILE(5) OVER (ORDER BY list_price) AS price_band
FROM production.products
ORDER BY list_price;


-- 7.5 Running total of revenue by order_date
WITH order_revenue AS (
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS order_revenue
    FROM sales.orders o
    INNER JOIN sales.order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_date
)
SELECT 
    order_id,
    order_date,
    order_revenue,
    SUM(order_revenue) OVER (
        ORDER BY order_date, order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM order_revenue
ORDER BY order_date, order_id;


-- 7.6 Think About It – FIRST_VALUE vs LAST_VALUE window frame
/*
Default window frame when ORDER BY is present:
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

This means the frame includes all rows from the start of the partition
up to the current row (and any peers with the same ORDER BY value).

FIRST_VALUE() works correctly with the default frame because the first
row is always included (UNBOUNDED PRECEDING).

LAST_VALUE() with the default frame only sees up to the current row,
so it returns the value of the current row (or the last peer), not the
actual last row of the entire partition.

To make LAST_VALUE() return the true last value of the partition,
you must expand the frame to:

    RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

(or ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
*/