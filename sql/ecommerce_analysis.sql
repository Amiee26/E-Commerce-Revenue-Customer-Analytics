-- 1. Order Status Analysis
-- Purpose: Understand the distribution of orders by status.

SELECT
    order_status,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 2. Revenue Analysis
-- Purpose: Calculate total product revenue from delivered orders.

SELECT
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    ROUND(
        (SUM(oi.price) / COUNT(DISTINCT o.order_id))::NUMERIC,
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- 3. Revenue by Product Category
-- Purpose: Identify the highest-revenue product categories.

SELECT
    p.product_category_name,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS category_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY category_revenue DESC
LIMIT 10;

-- 4. Customer Purchase Analysis
-- Purpose: Identify new and returning customers.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS returning_customers
FROM customer_orders;

-- 5. Monthly Revenue Trend
-- Purpose: Analyse revenue performance month by month.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY order_month;

-- 6. Delivery Performance Analysis
-- Purpose: Analyse average delivery time and late deliveries.

SELECT
    COUNT(*) AS total_delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date -
                    order_purchase_timestamp
                )
            ) / 86400
        )::NUMERIC,
        2
    ) AS avg_delivery_days,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date >
              order_estimed_delivery_date
    ) AS late_deliveries

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimed_delivery_date IS NOT NULL;

  -- 7. Customer Review Analysis
-- Purpose: Analyse customer satisfaction through review scores.

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- 8. State-wise Revenue Analysis
-- Purpose: Identify states generating the highest revenue.

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(
        (SUM(oi.price) /
        COUNT(DISTINCT c.customer_unique_id))::NUMERIC,
        2
    ) AS revenue_per_customer

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 9. Payment Method Analysis
-- Purpose: Understand customer payment preferences.

SELECT
    op.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_payment,
    ROUND(
        AVG(op.payment_value)::NUMERIC,
        2
    ) AS average_payment

FROM orders o
JOIN order_payments op
    ON o.order_id = op.order_id

GROUP BY op.payment_type
ORDER BY total_payment DESC;

-- 10. Seller Performance Analysis
-- Purpose: Identify top-performing sellers by revenue.

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_product_price

FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN sellers s
    ON oi.seller_id = s.seller_id

WHERE o.order_status = 'delivered'

GROUP BY s.seller_id, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;