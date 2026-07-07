--Головний датасет: позиції доставлених замовлень з контекстом
SELECT o.order_id,
	   o.order_purchase_t,
       strftime('%Y-%m', o.order_purchase_t) as ym,
       cu.customer_state,
       t.product_category_1 as category_en,
       oi.price,
       oi.freight_value,
       op.payment_type as payment_method,
       r.review_score
from olist_order_items_dataset oi
join olist_orders_dataset o USING(order_id)
join olist_customers_dataset cu on o.customer_id = cu.customer_id
JOIN olist_products_dataset p USING(product_id)
left JOIN product_category_name_translation t USING (product_category)
left join olist_order_payments_dataset op using(order_id)
left join olist_order_reviews_dataset r USING(order_id)
where o.order_status = 'delivered';
------------------------------------------------------------------------
--місячний виторг і кількість замовлень
SELECT
	  strftime('%Y-%m',o.order_purchase_t) as ym,
      ROUND(sum(oi.price),2) as revenue,
      count(DISTINCT o.order_id) as orders
from olist_orders_dataset o
join olist_order_items_dataset oi using (order_id)
where o.order_status = 'delivered'
GROUP by ym
order by ym;
------------------------------------------------------------------------
-- Розвідувальні запити
-- •       топ-10 категорій за виторгом;
select t.product_category_1 as category_en,
	   round(sum(oi.price),2) as revenue
from olist_order_items_dataset oi
join olist_orders_dataset o using(order_id)
join olist_products_dataset p using(product_id)
left join product_category_name_translation t using (product_category)
where o.order_status = 'delivered'
GROUP by category_en
order by revenue DESC
limit 10;
-----------------------------------------------------------------

-- виторг за штатами (для карти в Tableau)
SELECT
	cu.customer_state,
    ROUND(SUM(oi.price), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o USING (order_id)
JOIN olist_customers_dataset cu USING (customer_id)
WHERE o.order_status = 'delivered'
GROUP BY cu.customer_state
ORDER BY revenue DESC;

-----------------------------------------------------------------
--•       середня оцінка (review_score) за категоріями;
-- Рахує avg(review_score) і кількість відгуків за категоріями, 
-- але з фільтром HAVING reviews > 50 це важливо, щоб відсіяти категорії з малою кількістю відгуків, 
-- де середня оцінка статистично не показова (шум від 2-3 відгуків).
select 
	   t.product_category_1 as category_en,
       round(avg(r.review_score),2) as avg_score,
       count(*) as reviews
from olist_order_reviews_dataset r
join olist_order_items_dataset oi using(order_id)
join olist_products_dataset p using (product_id)
left join product_category_name_translation t using (product_category)
GROUP by category_en
HAVING reviews > 50
order by avg_score desc;
-----------------------------------------------------------------
-- середній час доставки (різниця між датою купівлі і датою доставки)
-- Різниця в днях між покупкою і доставкою через julianday(), усереднена по всіх доставлених замовленнях.
-- Результат  12.6
select 
  	   round(avg(julianday(order_delivered_6) - julianday(order_purchase_t)),1) as avg_delivery_days
from olist_orders_dataset 
where order_status = 'delivered' and order_delivered_6 is not NULL;
-----------------------------------------------------------------
-- розподіл способів оплати
--Рахує кількість транзакцій і сумарну суму за кожним payment_type, сортування за частотою використання.
select payment_type,
	   count(*) as n,
       round(sum(payment_value),2) as total_value
FROM olist_order_payments_dataset
GROUP by payment_type
order by n desc
