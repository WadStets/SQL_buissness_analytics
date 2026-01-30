use magist;
select * from product_category_name_translation;
--- 1ords qty
SELECT 
    COUNT(*) AS orders_count
FROM
    orders;


---- 2delivered
SELECT 
    order_status, 
    COUNT(*) AS orders
FROM
    orders
GROUP BY order_status;


--- 3ussrs growth
SELECT 
    YEAR(order_purchase_timestamp) AS year_,
    MONTH(order_purchase_timestamp) AS month_,
    COUNT(customer_id)
FROM
    orders
GROUP BY year_ , month_
ORDER BY year_ , month_;


--- 4 products qty
SELECT 
    COUNT(DISTINCT product_id) AS products_count
FROM
    products;
    
    
    
    --- 5 biggest categ
    
    SELECT 
    product_category_name, 
    COUNT(DISTINCT product_id) AS n_products
FROM
    products
GROUP BY product_category_name
ORDER BY COUNT(product_id) DESC;

---- 6products sold
SELECT 
	count(DISTINCT product_id) AS n_products
FROM
	order_items;
    
    ---- most exp ch
    
    
    --- 7 highest price
    SELECT 
    MIN(price) AS cheapest, 
    MAX(price) AS most_expensive
FROM 
	order_items;
    
    
    
    --- 8 hihest payment
    
    SELECT 
	MAX(payment_value) as highest,
    MIN(payment_value) as lowest
FROM
	order_payments;
    
    
    


    SELECT DISTINCT t.product_category_name_english
    fROM product_category_name_translation AS t
WHERE t.product_category_name_english IN (
'electronics',
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer'
)

ORDER BY t.product_category_name_english ;

    
    
    
    
    
    
    --- How many months of data are included in the magist database?

 SELECT 
    COUNT(DISTINCT DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) AS months_of_data
FROM orders;

--- How many sellers are there?
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;

--- total rev
select 
SUM(price) AS total_earned_all_sellers
FROM order_items;

--- Can you work out the average monthly income of all sellers?
SELECT 
    SUM(oi.price) / COUNT(DISTINCT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'))
        AS avg_monthly_income_all_sellers
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id;

WITH Total_Revenue AS (
    -- 1. Обчислюємо загальний дохід, отриманий усіма продавцями
    SELECT
        SUM(t1.price) AS Overall_Total_Revenue
    FROM
        order_items AS t1 -- Використовуємо поле price для визначення доходу [1, 2]
),
Date_Range AS (
    -- 2. Визначаємо часовий проміжок бази даних (у місяцях)
    SELECT
        -- Обчислюємо кількість повних місяців у проміжку
        -- Використовуємо order_purchase_timestamp з таблиці orders [1, 2]
        TIMESTAMPDIFF(MONTH, MIN(t1.order_purchase_timestamp), MAX(t1.order_purchase_timestamp)) + 1 AS Total_Months
    FROM
        orders AS t1
)
-- 3. Обчислюємо середній щомісячний дохід
SELECT
    TR.Overall_Total_Revenue AS 'Загальний дохід усіх продавців',
    DR.Total_Months AS 'Кількість місяців у базі даних',
    -- Розділяємо загальний дохід на кількість місяців
    (TR.Overall_Total_Revenue / DR.Total_Months) AS 'Avg monthly income all sellers'
FROM
    Total_Revenue TR,
    Date_Range DR;




--- What’s the average time between the order being placed and the product being delivered?
SELECT 
    AVG(TIMESTAMPDIFF(
        DAY,
        order_purchase_timestamp,
        order_delivered_customer_date
    )) AS avg_days_purchase_to_delivery
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- How many orders are delivered on time vs orders delivered with a delay?

SELECT
    SUM(CASE 
            WHEN order_delivered_customer_date <= order_estimated_delivery_date
                 THEN 1 ELSE 0
        END) AS on_time_orders,
    SUM(CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                 THEN 1 ELSE 0
        END) AS delayed_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

SELECT
    -- Використовуємо CASE WHEN для класифікації
    CASE
        -- 1. Успішна доставка (вчасно): фактична дата доставки раніше або дорівнює очікуваній
        WHEN t1.order_delivered_customer_date <= t1.order_estimated_delivery_date THEN 'Доставлено вчасно (On Time)'
        -- 2. Затримка: фактична дата доставки пізніша за очікувану
        WHEN t1.order_delivered_customer_date > t1.order_estimated_delivery_date THEN 'Доставлено із затримкою (Delayed)'
        -- 3. Інші: випадки, де одна з дат доставки відсутня або статус не дозволяє оцінити
        ELSE 'Неможливо оцінити (N/A)'
    END AS Delivery_Performance,
    COUNT(t1.order_id) AS Number_of_Orders
FROM
    orders AS t1
WHERE
    -- Фільтруємо, щоб включити лише ті замовлення, які мають дату доставки
    t1.order_delivered_customer_date IS NOT NULL
GROUP BY
    Delivery_Performance
ORDER BY
    Number_of_Orders DESC;

--- How many products of these tech categories have been sold (within the time window of the database snapshot)? 
--- What percentage does that represent from the overall number of products sold?
SELECT DISTINCT
t.product_category_name_english as category,
count(oi.product_id) as sold_in_category,
(sum(oi.order_item_id) / count(oi.product_id)) as percentage -- subquery here
FROM
product_category_name_translation AS t
join products as p on t.product_category_name = p.product_category_name
join order_items as oi on p.product_id = oi.product_id
WHERE
t.product_category_name_english IN (
'electronics',
'computers',
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer'
)
group by t.product_category_name_english
ORDER BY
t.product_category_name_english ;


WITH Tech_Categories AS (
    -- Список технічних категорій, які ми шукаємо (за product_category_name_english)
    SELECT product_category_name
    FROM product_category_name_translation -- Таблиця для фільтрації за англомовними назвами [1, 2]
    WHERE product_category_name_english IN (
        'computers', 
        'computers_accessories', 
        'telephony', 
        'consoles_games', 
        'audio', 
        'tablets_printing_image', 
        'cine_photo', 
        'books_technical', 
        'pc_gamer'
    )
),
Tech_Sales_Count AS (
    -- КРОК 1: Підрахунок кількості проданих одиниць у технічних категоріях
    SELECT
        COUNT(t1.order_id) AS Tech_Products_Sold
    FROM
        order_items AS t1 -- Використовуємо order_items для підрахунку проданих одиниць [1, 2]
    JOIN
        products AS t2 ON t1.product_id = t2.product_id -- З'єднуємо, щоб отримати назву категорії [1, 2]
    JOIN
        Tech_Categories AS t3 ON t2.product_category_name = t3.product_category_name
),
Total_Sales_Count AS (
    -- КРОК 2: Підрахунок загальної кількості проданих одиниць
    SELECT 
        COUNT(order_id) AS Total_Products_Sold
    FROM 
        order_items -- Загальна кількість проданих одиниць - це кількість рядків у order_items [1, 2]
)

-- КРОК 3: Виведення результатів та обчислення відсотка
SELECT
    TSC.Tech_Products_Sold AS 'Кількість проданих тех. товарів',
    TCS.Total_Products_Sold AS 'Загальна кількість проданих товарів',
    (TSC.Tech_Products_Sold * 100.0 / TCS.Total_Products_Sold) AS 'Відсоток від загального продажу (%)'
FROM
    Tech_Sales_Count TSC,
    Total_Sales_Count TCS;




sELECT DISTINCT
t.product_category_name_english as category,
sum(oi.order_item_id) as sold_in_category,
round((sum(oi.order_item_id) * 100 / (SELECT count(oi.order_id)
FROM order_items as oi)), 2) AS percentage_of_total_sales
FROM
product_category_name_translation AS t
join products as p on t.product_category_name = p.product_category_name
join order_items as oi on p.product_id = oi.product_id
WHERE
t.product_category_name_english IN (
'electronics',
'computers',
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer'

)
group by t.product_category_name_english
ORDER BY
percentage_of_total_sales desc ;



--- What’s the average price of the products being sold?
SELECT
ROUND(AVG(oi.price), 2)
FROM
product_category_name_translation AS t
JOIN
products AS p ON t.product_category_name = p.product_category_name
JOIN
order_items AS oi ON p.product_id = oi.product_id
WHERE
t.product_category_name_english
IN 
(
'electronics',
'computers',
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer'
) 
;
SELECT AVG(price)
FROM order_items;


SELECT
    -- Використовуємо CASE WHEN для класифікації ціни
    CASE
        -- Якщо ціна проданого товару вища або дорівнює наданій середній ціні 107.8
        WHEN t1.price >= 107.8 THEN 'Expensive Tech Products'
        -- Інакше
        ELSE 'Affordable Tech Products'
    END AS Price_Popularity_Category,
    COUNT(t1.order_id) AS Number_of_Sales -- Популярність визначається кількістю продажів
FROM 
    order_items AS t1 -- Містить ціну (price) проданого товару [1, 2]
JOIN 
    products AS t2 ON t1.product_id = t2.product_id -- З'єднуємо, щоб отримати назву категорії [1, 2]
JOIN 
    product_category_name_translation AS t3 
        ON t2.product_category_name = t3.product_category_name
WHERE 
    -- Фільтруємо лише технічні категорії, визначені у нашій розмові
    t3.product_category_name_english IN (
        'computers', 
        'computers_accessories', 
        'telephony', 
        'consoles_games', 
        'audio', 
        'tablets_printing_image', 
        'cine_photo', 
        'electronics',
        'books_technical', 
        'pc_gamer'
    )
GROUP BY
    Price_Popularity_Category
ORDER BY
    Number_of_Sales DESC;
    
    SELECT
    -- Використовуємо CASE WHEN для класифікації ціни проданого товару
    CASE
        -- Якщо ціна вища або дорівнює наданому середньому значенню
        WHEN t1.price >= 107.8 THEN 'A. Дорогі технічні продукти (Expensive Tech Products)'
        -- Інакше
        ELSE 'B. Доступні технічні продукти (Affordable Tech Products)'
    END AS Price_Popularity_Category,
    COUNT(t1.order_id) AS Number_of_Sales -- Популярність визначається кількістю продажів
FROM 
    order_items AS t1 -- Містить ціну (price) проданого товару [1, 2]
JOIN 
    products AS t2 ON t1.product_id = t2.product_id -- З'єднуємо, щоб отримати назву категорії [1, 2]
JOIN 
    product_category_name_translation AS t3 
        ON t2.product_category_name = t3.product_category_name
WHERE 
    -- Фільтруємо лише технічні категорії, включаючи 'electronics'
    t3.product_category_name_english IN (
        'computers', 
        'computers_accessories', 
        'telephony', 
        'consoles_games', 
        'audio', 
        'tablets_printing_image', 
        'cine_photo', 
        'books_technical', 
        'pc_gamer',
        'electronics' -- Додана категорія
    )
GROUP BY
    Price_Popularity_Category
ORDER BY
    Number_of_Sales DESC;
    
    --- How many sellers are there? 
    SELECT
    COUNT(t1.seller_id) AS Overall_Sellers_Count
FROM
    sellers AS t1;
    
    
    
    --- How many Tech sellers are there? 
    SELECT
    COUNT(DISTINCT t1.seller_id) AS Tech_Sellers_Count
FROM
    order_items AS t1 -- Джерело інформації про продавця (seller_id)
JOIN
    products AS t2 ON t1.product_id = t2.product_id
JOIN
    product_category_name_translation AS t3 
        ON t2.product_category_name = t3.product_category_name
WHERE 
    t3.product_category_name_english IN (
        'computers', 
        'computers_accessories', 
        'telephony', 
        'consoles_games', 
        'audio', 
        'tablets_printing_image', 
        'cine_photo', 
        'books_technical', 
        'pc_gamer',
        'electronics'
    );
    
    
    
    --- What percentage of overall sellers are Tech sellers?
    
    WITH Overall_Sellers AS (
    -- Загальна кількість продавців
    SELECT COUNT(t1.seller_id) AS Total_Sellers
    FROM sellers AS t1
),
Tech_Sellers AS (
    -- Кількість унікальних продавців технічних товарів
    SELECT
        COUNT(DISTINCT t1.seller_id) AS Tech_Sellers
    FROM
        order_items AS t1 
    JOIN
        products AS t2 ON t1.product_id = t2.product_id
    JOIN
        product_category_name_translation AS t3 
            ON t2.product_category_name = t3.product_category_name
    WHERE 
        t3.product_category_name_english IN (
            'computers', 
            'computers_accessories', 
            'telephony', 
            'consoles_games', 
            'audio', 
            'tablets_printing_image', 
            'cine_photo', 
            'books_technical', 
            'electronics'
            'pc_gamer'
        )
)
-- Виведення результатів та обчислення відсотка
SELECT
    TS.Tech_Sellers AS 'Кількість технічних продавців',
    OS.Total_Sellers AS 'Загальна кількість продавців',
    (TS.Tech_Sellers * 100.0 / OS.Total_Sellers) AS 'Відсоток технічних продавців (%)'
FROM
    Tech_Sellers TS,
    Overall_Sellers OS;


--- What is the total amount earned by all Tech sellers?

SELECT
    -- Сумуємо ціни (дохід) усіх проданих технічних товарів
    SUM(t1.price) AS Total_Amount_Earned_By_Tech_Sellers
FROM
    order_items AS t1 -- Джерело ціни (price) та ідентифікатора продавця (seller_id) [1, 2]
JOIN
    products AS t2 ON t1.product_id = t2.product_id -- З'єднуємо для отримання назви категорії продукту [1, 2]
JOIN
    product_category_name_translation AS t3 
        ON t2.product_category_name = t3.product_category_name -- З'єднуємо для використання англомовних назв категорій [1, 2]
WHERE 
    -- Фільтруємо лише ті продажі, що належать до технічних категорій
    t3.product_category_name_english IN (
        'computers', 
        'computers_accessories', 
        'telephony', 
        'consoles_games', 
        'audio', 
        'tablets_printing_image', 
        'cine_photo', 
        'electronics',
        'books_technical', 
        'pc_gamer'
    );








--- Can you work out the average monthly income of Tech sellers?

WITH Tech_Income AS (
    -- 1. Обчислюємо загальний дохід від продажу технічних товарів
    SELECT
        SUM(t1.price) AS Total_Tech_Revenue
    FROM
        order_items AS t1
    JOIN
        products AS t2 ON t1.product_id = t2.product_id
    JOIN
        product_category_name_translation AS t3 
            ON t2.product_category_name = t3.product_category_name
    WHERE 
        t3.product_category_name_english IN (
            'computers', 
            'computers_accessories', 
            'telephony', 
            'consoles_games', 
            'audio', 
            'electronics',
            'tablets_printing_image', 
            'cine_photo', 
            'books_technical', 
            'pc_gamer'
        )
),
Date_Range AS (
    -- 2. Визначаємо часовий проміжок бази даних (в місяцях)
    SELECT
        -- Знаходимо найранішу та найпізнішу дату купівлі
        MIN(t1.order_purchase_timestamp) AS Start_Date,
        MAX(t1.order_purchase_timestamp) AS End_Date,
        -- Обчислюємо кількість повних місяців у проміжку
        -- (YEAR(End) - YEAR(Start)) * 12 + (MONTH(End) - MONTH(Start)) + 1
        -- (Додаємо +1, щоб включити обидва місяці, якщо вони не співпадають)
        TIMESTAMPDIFF(MONTH, MIN(t1.order_purchase_timestamp), MAX(t1.order_purchase_timestamp)) + 1 AS Total_Months
    FROM
        orders AS t1 -- Використовуємо таблицю orders для отримання часових міток [1, 2]
)

-- 3. Обчислюємо середній щомісячний дохід
SELECT
    ---- TI.Total_Tech_Revenue AS 'Загальний дохід тех. продавців',
    ------ DR.Total_Months AS 'Кількість місяців у базі даних',
    -- Розділяємо загальний дохід на кількість місяців
    (TI.Total_Tech_Revenue / DR.Total_Months) AS 'avg monthly income techsellers'
FROM
    Tech_Income TI,
    Date_Range DR;


--- Is there any pattern for delayed orders, e.g. big products being delayed more often?
SELECT
    -- Класифікуємо статус доставки
    CASE
        WHEN t1.order_delivered_customer_date > t1.order_estimated_delivery_date THEN 'B. Із затримкою (Delayed)'
        WHEN t1.order_delivered_customer_date <= t1.order_estimated_delivery_date THEN 'A. Вчасно (On Time)'
        ELSE 'Неможливо оцінити (N/A)'
    END AS Delivery_Status,

    -- Обчислюємо середню вагу проданих одиниць у цій групі (у грамах)
    AVG(t3.product_weight_g) AS Average_Product_Weight_g,

    -- Обчислюємо середній об'єм (довжина * ширина * висота, у см³)
    AVG(t3.product_length_cm * t3.product_height_cm * t3.product_width_cm) AS Average_Product_Volume_cm3,
    
    COUNT(t1.order_id) AS Number_of_Orders

FROM
    orders AS t1
JOIN
    order_items AS t2 ON t1.order_id = t2.order_id
JOIN
    products AS t3 ON t2.product_id = t3.product_id -- З'єднання для отримання даних про розмір/вагу
WHERE
    -- Фільтруємо лише доставлені замовлення, які мають дату доставки
    t1.order_delivered_customer_date IS NOT NULL 
    AND t3.product_weight_g IS NOT NULL -- Виключаємо продукти без даних про вагу
GROUP BY
    Delivery_Status
ORDER BY
    Delivery_Status;




--- delyed
SELECT
    -- Використовуємо CASE WHEN для класифікації
    CASE
        -- 1. Успішна доставка (вчасно): фактична дата доставки раніше або дорівнює очікуваній
        WHEN t1.order_delivered_customer_date <= t1.order_estimated_delivery_date THEN 'Доставлено вчасно (On Time)'
        -- 2. Затримка: фактична дата доставки пізніша за очікувану
        WHEN t1.order_delivered_customer_date > t1.order_estimated_delivery_date THEN 'Доставлено із затримкою (Delayed)'
        -- 3. Інші: випадки, де одна з дат доставки відсутня
        ELSE 'Неможливо оцінити (N/A)'
    END AS Delivery_Performance,
    COUNT(t1.order_id) AS Number_of_Orders
FROM
    orders AS t1
WHERE
    -- Фільтруємо, щоб включити лише ті замовлення, які мають дату доставки
    t1.order_delivered_customer_date IS NOT NULL 
GROUP BY
    Delivery_Performance
ORDER BY
    Number_of_Orders DESC;
    
    
    
    
    
    select count(*) as total_products_sold,
count(case when pct.product_category_name_english in('audio', 'cine_foto', 'console_games', 'electronics','small_appliances',
'computer_accessories', 'pc_gamer', 'computers', 'tablet_printing_image','telephony','fixed_telephony') then 1 end) as tech_products_sold,
    
    
    select count(*) as total_products_sold,
count(case when pct.product_category_name_english in('audio', 'cine_foto', 'console_games', 'electronics','small_appliances',
'computer_accessories', 'pc_gamer', 'computers', 'tablet_printing_image','telephony','fixed_telephony') then 1 end) as tech_products_sold,



SELECT
    COUNT(*) AS tech_products_sold,
    ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM order_items), 2) AS percentage_of_total_sales,
    ROUND(AVG(price), 2) AS avg_tech_price
FROM order_items oi
JOIN products USING (product_id)
WHERE product_category_name IN (
    'informatica_acessorios',
    'telefonia',
    'eletronicos',
    'pcs',
    'pc_gamer',
    'audio',
    'tablets_impressao_imagem'
);

SELECT
 
    CASE
        WHEN t1.order_delivered_customer_date > t1.order_estimated_delivery_date THEN 'B. Із затримкою (Delayed)'
        WHEN t1.order_delivered_customer_date <= t1.order_estimated_delivery_date THEN 'A. Вчасно (On Time)'
        ELSE ' (N/A)'
    END AS Delivery_Status,

    AVG(t3.product_weight_g) AS Average_Product_Weight_g,

    AVG(t3.product_length_cm * t3.product_height_cm * t3.product_width_cm) AS Average_Product_Volume_cm3,
    
    COUNT(t1.order_id) AS Number_of_Orders

FROM
    orders AS t1
JOIN
    order_items AS t2 ON t1.order_id = t2.order_id
JOIN
    products AS t3 ON t2.product_id = t3.product_id 
WHERE
    
    t1.order_delivered_customer_date IS NOT NULL 
    AND t3.product_weight_g IS NOT NULL 
GROUP BY
    Delivery_Status
ORDER BY
    Delivery_Status;
    
    SELECT
 
    CASE
        WHEN t1.order_delivered_customer_date > t1.order_estimated_delivery_date THEN 'Delayed'
        WHEN t1.order_delivered_customer_date <= t1.order_estimated_delivery_date THEN 'On Time'
        ELSE ' (N/A)'
    END AS Delivery_Status,

    AVG(t3.product_weight_g) AS Average_Product_Weight_g,

    AVG(t3.product_length_cm * t3.product_height_cm * t3.product_width_cm) AS Average_Product_Volume_cm3,
    
    COUNT(t1.order_id) AS Number_of_Orders

FROM
    orders AS t1
JOIN
    order_items AS t2 ON t1.order_id = t2.order_id
JOIN
    products AS t3 ON t2.product_id = t3.product_id 
WHERE
    
    t1.order_delivered_customer_date IS NOT NULL 
    AND t3.product_weight_g IS NOT NULL 
GROUP BY
    Delivery_Status
ORDER BY
    Delivery_Status;
    
    
    
    
    
    SELECT AVG(monthly_r.revenue) monthly_income
FROM
(SELECT
seller_id s,
SUM(price) revenue,
MONTH(order_purchase_timestamp) m
FROM order_items oi
JOIN orders o
ON o.order_id=oi.order_id
JOIN products p
ON oi.product_id=p.product_id
JOIN product_category_name_translation t
ON t.product_category_name=p.product_category_name
WHERE t.product_category_name_english IN (

'electronics',
'computers',
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer')

GROUP BY m,s

) monthly_r;
-- 938.33
-- 866.49

-- 17/9 What’s the average time between the order being placed and the product being delivered?

SELECT
ROUND(AVG(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)),1) avg_diff_days
FROM
orders; -- 12.5

-- 18/10 How many orders are delivered on time vs orders delivered with a delay?

SELECT
COUNT(*) num_orders,
-- DATEDIFF(order_estimated_delivery_date,order_delivered_customer_date) timediff,
CASE
WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 'on time'
WHEN order_estimated_delivery_date < order_delivered_customer_date THEN 'delayed'
ELSE 'no data'
END AS status
FROM
orders
GROUP BY status
ORDER BY num_orders DESC
;




WITH Date_Range AS (
    -- 1. Визначаємо загальну кількість місяців, охоплених базою даних (для ділення)
    SELECT
        -- Використовуємо TIMESTAMPDIFF, щоб отримати різницю в місяцях + 1
        TIMESTAMPDIFF(MONTH, MIN(t1.order_purchase_timestamp), MAX(t1.order_purchase_timestamp)) + 1 AS Total_Months
    FROM
        orders AS t1 -- Використовуємо orders для часових міток [1]
),
Total_Revenue AS (
    -- 2. Обчислюємо загальний дохід, отриманий усіма продавцями (для середнього доходу всіх)
    SELECT
        SUM(t1.price) AS Overall_Total_Revenue
    FROM
        order_items AS t1 -- Використовуємо order_items для отримання ціни [1]
),
Tech_Revenue AS (
    -- 3. Обчислюємо загальний дохід від продажу лише технічних товарів (для середнього доходу тех. продавців)
    SELECT
        SUM(t1.price) AS Total_Tech_Revenue
    FROM
        order_items AS t1
    JOIN
        products AS t2 ON t1.product_id = t2.product_id -- З'єднання для категорії [1]
    JOIN
        product_category_name_translation AS t3 
            ON t2.product_category_name = t3.product_category_name -- З'єднання для англомовного імені категорії [1]
    WHERE 
        t3.product_category_name_english IN (
            'computers', 
            'computers_accessories', 
            'telephony', 
            'consoles_games', 
            'audio', 
            'tablets_printing_image', 
            'cine_photo', 
            'books_technical', 
            'pc_gamer',
            'electronics' -- Оновлений список
        )
)
-- 4. Фінальний SELECT для обчислення середнього щомісячного доходу
SELECT
    (TR.Overall_Total_Revenue / DR.Total_Months) AS 'all sellers',
    (TCR.Total_Tech_Revenue / DR.Total_Months) AS 'tech sellers'
FROM
    Date_Range DR,
    Total_Revenue TR,
    Tech_Revenue TCR;