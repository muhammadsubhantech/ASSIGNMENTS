-- ============================================================
-- Assignment 6 - CTEs (Common Table Expressions)
-- Student: Muhammad Subhan
-- ID: 871856
-- Database: BikeStores
-- ============================================================


-- 6.1 Rewrite the derived table as a CTE
WITH store_counts AS (
    SELECT 
        store_id, 
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY store_id
)
SELECT AVG(order_count) AS avg_orders
FROM store_counts;


-- 6.2 CTE for high-value products + filter Mountain Bikes
WITH cte_high_value_products AS (
    SELECT 
        product_id,
        product_name,
        brand_id,
        category_id,
        list_price
    FROM production.products
    WHERE list_price > 2000
)
SELECT 
    h.product_id,
    h.product_name,
    h.list_price,
    c.category_name
FROM cte_high_value_products h
INNER JOIN production.categories c 
    ON h.category_id = c.category_id
WHERE c.category_name = 'Mountain Bikes';


-- 6.3 Two CTEs in one WITH clause
WITH 
cte_order_count AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY customer_id
),
cte_revenue AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.orders o
    INNER JOIN sales.order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT 
    oc.customer_id,
    oc.order_count,
    r.total_revenue
FROM cte_order_count oc
INNER JOIN cte_revenue r 
    ON oc.customer_id = r.customer_id
ORDER BY r.total_revenue DESC;


-- 6.4 Recursive CTE: numbers 1 to 10 with their squares
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM Numbers
    WHERE n < 10
)
SELECT 
    n,
    n * n AS square
FROM Numbers
OPTION (MAXRECURSION 10);


-- 6.5 Recursive CTE – Org Chart with manager name and level
WITH cte_org AS (
    -- Anchor member: top-level manager(s)
    SELECT 
        s.staff_id,
        s.first_name,
        s.manager_id,
        CAST(NULL AS VARCHAR(50)) AS manager_name,
        0 AS level
    FROM sales.staffs s
    WHERE s.manager_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT 
        s.staff_id,
        s.first_name,
        s.manager_id,
        o.first_name AS manager_name,
        o.level + 1
    FROM sales.staffs s
    INNER JOIN cte_org o 
        ON s.manager_id = o.staff_id
)
SELECT 
    staff_id,
    first_name,
    manager_id,
    manager_name,
    level
FROM cte_org
ORDER BY level, staff_id;


-- 6.6 Think About It
/*
Claim: "CTEs are faster than subqueries because the database computes 
the result once and reuses it."

This claim is NOT accurate in most cases.

- In SQL Server (and most modern engines), a CTE is usually just 
  syntactic sugar. The optimizer can expand it and may re-execute 
  the CTE definition every time it is referenced in the outer query.
- There is no guarantee that the result is materialized and reused.

If you genuinely need the result computed only once and reused:
→ Use a temporary table (#temp) or a table variable instead.

Example:
SELECT ... INTO #HighValueProducts FROM production.products WHERE list_price > 2000;
-- Then reference #HighValueProducts multiple times
*/