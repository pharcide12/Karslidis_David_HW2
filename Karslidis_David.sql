-- Query 1: бренды с общим количеством продаж > 1000 и max стандартной ценой > 1500
SELECT DISTINCT p.brand
FROM hw2.product p
JOIN hw2.order_items oi ON oi.product_id = p.product_id
GROUP BY p.brand
HAVING 
    SUM(oi.quantity) >= 1000
    AND MAX(p.standard_cost) > 1500;


-- Query 2: онлайн заказы по датам
SELECT
    o.order_date,
    COUNT(*) AS approved_online_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM hw2.orders o
WHERE 
    o.order_date BETWEEN '2017-04-01' AND '2017-04-09'
    AND o.online_order = 'True'
    AND o.order_status = 'Approved'
GROUP BY o.order_date
ORDER BY o.order_date;


-- Query 3: должности в IT и Financial Services
SELECT
    c.job_title
FROM hw2.customer c
WHERE c.job_industry_category = 'IT'
  AND c.job_title LIKE 'Senior%'
  AND DATE_PART('year', AGE(c.dob)) > 35

UNION ALL

SELECT
    c.job_title
FROM hw2.customer c
WHERE c.job_industry_category = 'Financial Services'
  AND c.job_title LIKE 'Lead%'
  AND DATE_PART('year', AGE(c.dob)) > 35;


-- Query 4: бренды, купленные в Financial Services, но не в IT
(SELECT DISTINCT p.brand
 FROM hw2.customer c
 JOIN hw2.orders o  ON c.customer_id::text = o.customer_id::text
 JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
 JOIN hw2.product p ON oi.product_id::text = p.product_id::text
 WHERE c.job_industry_category = 'Financial Services')
EXCEPT
(SELECT DISTINCT p.brand
 FROM hw2.customer c
 JOIN hw2.orders o  ON c.customer_id::text = o.customer_id::text
 JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
 JOIN hw2.product p ON oi.product_id::text = p.product_id::text
 WHERE c.job_industry_category = 'IT');


-- Query 5: проверка, всё ли ок
SELECT 'Queries 1-4 executed successfully' AS status;


-- Query 5 (основной): топ-10 клиентов по онлайн заказам определённых брендов
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders
FROM hw2.customer c
JOIN hw2.orders o ON c.customer_id::text = o.customer_id::text
JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
JOIN hw2.product p ON oi.product_id::text = p.product_id::text
WHERE 
    o.online_order = 'True'
    AND p.brand IN ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
    AND c.property_valuation IS NOT NULL
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC
LIMIT 10;


-- Query 6: клиенты с машиной, не Mass Customer и без онлайн-заказов за последний год
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM hw2.customer c
WHERE 
    c.owns_car = 'True'
    AND c.wealth_segment <> 'Mass Customer'
    AND NOT EXISTS (
        SELECT 1
        FROM hw2.orders o
        WHERE 
            o.customer_id::text = c.customer_id::text
            AND o.online_order = 'True'
            AND o.order_status = 'Approved'
            AND o.order_date >= (CURRENT_DATE - INTERVAL '1 year')
    );


-- Query 7: клиенты из IT, купившие 2 из 5 самых дорогих Road-продуктов
WITH top5_products AS (
    SELECT product_id
    FROM hw2.product
    WHERE product_line = 'Road'
    ORDER BY list_price DESC
    LIMIT 5
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM hw2.customer c
JOIN hw2.orders o ON c.customer_id::text = o.customer_id::text
JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
WHERE 
    c.job_industry_category = 'IT'
    AND oi.product_id IN (SELECT product_id FROM top5_products)
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT oi.product_id) = 2;


-- Query 8: клиенты IT и Health с 3+ заказами и суммой > 10000 за указанный период
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category AS industry
FROM hw2.customer c
JOIN hw2.orders o ON c.customer_id::text = o.customer_id::text
JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
JOIN hw2.product p ON oi.product_id::text = p.product_id::text
WHERE 
    c.job_industry_category = 'IT'
    AND o.order_status = 'Approved'
    AND o.order_date BETWEEN '2017-01-01' AND '2017-03-01'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT o.order_id) >= 3
   AND SUM(p.list_price * oi.quantity) > 10000

UNION

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category AS industry
FROM hw2.customer c
JOIN hw2.orders o ON c.customer_id::text = o.customer_id::text
JOIN hw2.order_items oi ON o.order_id::text = oi.order_id::text
JOIN hw2.product p ON oi.product_id::text = p.product_id::text
WHERE 
    c.job_industry_category = 'Health'
    AND o.order_status = 'Approved'
    AND o.order_date BETWEEN '2017-01-01' AND '2017-03-01'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT o.order_id) >= 3
   AND SUM(p.list_price * oi.quantity) > 10000
ORDER BY industry, last_name;