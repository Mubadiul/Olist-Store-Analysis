-- Payment Method Distribution: How many transactions were made using each payment method?
select 
	payment_type, 
	count(*) as total_transactions
from order_payments
group by payment_type
order by total_transactions desc;

-- Total Revenue Calculation: What is the total revenue from all transactions?
select 
	sum(price+freight_value) as revenue 
from order_items;

-- Total Orders & Revenue per Seller: What is the total number of orders and revenue for each seller?
select 
	seller_id, count( distinct seller_id) as order_total, 
	sum(price+freight_value) as revenue
from order_items
group by seller_id
order by revenue;

-- Top Customers by Number of Orders: Who are the top 10 customers with the highest number of purchases?
select 
	c.customer_unique_id, 
	count(o.order_id) 
from orders o
join customers c using(c.customer_id)
group by c.customer_unique_id
order by count(o.order_id) desc
limit 10;

-- Most Popular Product Categories: What are the top 5 product categories with the highest number of orders?
select 
	p.product_category_name, 
	count(oi.order_id) 
from products p
join order_items oi using(product_id)
group by p.product_category_name
order by count(oi.order_id) desc
limit 5;

-- Average Delivery Time: What is the average time from order_approved_at to order_delivered_customer_date?
select 
	avg(order_approved_at-order_delivered_customer_date) 
from orders
where order_delivered_customer_date is not null;

-- Top Payment Method by Transaction Value: Which payment method generates the highest total transaction value?
select 
	payment_type, 
	sum(payment_value) 
from order_payments
group by payment_type
order by sum(payment_value) desc;

-- Top Selling Products: Which products have the highest total sales value?
select 
	oi.product_id, 
	count(op.order_id) as total 
from order_payments op
join order_items oi using(order_id)
group by oi.product_id
order by total desc
limit 1;

-- Bottom Selling Products: Which products have the lowest total sales value?
select 
	product_id, 
	count(order_id) as total 
from order_payments
join order_items using(order_id)
group by product_id
order by total asc
limit 1;

-- Freight Cost per City: What is the average shipping cost by destination city?
select 
    c.customer_city, 
    round(avg(oi.freight_value), 2) as avg_freight_value
from customers c
join orders o using(customer_id)
join order_items oi using(order_id)
group by c.customer_city
order by c.customer_city;

-- Recency: When did the customer last make a purchase?
-- Frequency: How often do they make purchases?
-- Monetary: What is their total spending?
select 
    c.customer_unique_id,
   	max(o.order_purchase_timestamp) as last_purchase,  -- Recency
    count(o.order_id) as total_orders,  -- Frequency
    sum(oi.price) as total_spent  -- Monetary
from customers c
join orders o using(customer_id)
join order_items oi using(order_id)
group by c.customer_unique_id;

-- Customer Retention Rate: What percentage of customers have made more than one purchase?
select 
count(case when count_order>1 then customer_id end)*100.0/count(*) as percentage
from(select 
	customer_id,
	count(order_id) as count_order
from customers
join orders using(customer_id)
group by customer_id) as subquery;

-- Churn Rate Analysis: How many customers made only one transaction and never returned?
select count(customer_id)
from (
select 
	customer_id, 
	count(customer_id) as count_order
from customers
group by customer_id
having count(customer_id)=1);

-- Top 10 Sellers by Revenue: Who are the top 10 sellers with the highest total revenue?
select 
	seller_id, 
	sum(price) as revenue_total
from order_items
group by seller_id
order by revenue_total desc
limit 10;

-- What is the average total transaction value per unique customer?
select round(avg(count_order),2) as average
from(
select 
	customer_unique_id, 
	count(order_id) as count_order
from orders
join customers using(customer_id)
group by customer_unique_id);

-- Most Profitable Products: Which products have the highest profit margins?
select 
	product_id, 
	sum(price-freight_value) as profit
from order_items
group by product_id
order by profit desc
limit 5;

-- How many orders were canceled compared to the total number of orders?
select  
	order_status,
	count(*)
from orders
where order_status in('canceled','refunded')
group by order_status;

-- Do sellers located closer to customers have lower shipping costs?
select 
    s.seller_city,
    c.customer_city,
    abs(s.seller_zip_code_prefix - c.customer_zip_code_prefix) as zip_distance,
    ROUND(avg(oi.freight_value), 2) as avg_freight_cost
from order_items oi
join orders o using(order_id)
join customers c using(customer_id)
join sellers s using(seller_id)
group by s.seller_city, c.customer_city, zip_distance
order by zip_distance asc;

-- Average delivery time for each customer city
with shipping_time as (
    select 
        o.order_id,
        c.customer_city,
        date_part('day', o.order_delivered_customer_date - o.order_approved_at) as delivery_days
    from orders o
    join customers c on o.customer_id = c.customer_id
    where o.order_delivered_customer_date is not null 
      and o.order_approved_at is not null
)

select 
    customer_city, 
    round(avg(delivery_days)::numeric, 2) as avg_delivery_days
from shipping_time
group by customer_city
order by avg_delivery_days desc;


