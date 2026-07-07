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
-- •       виторг за штатами (для карти в Tableau);
-- •       середня оцінка (review_score) за категоріями;
-- •       середній час доставки (різниця між датою купівлі і датою доставки);
-- •       розподіл способів оплати.
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
