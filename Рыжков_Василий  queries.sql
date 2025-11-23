--1
select distinct brand
from product p
where standard_cost > 1500
  and (select sum(quantity) from order_items o where o.product_id = p.product_id) > 1000;

--2
select order_date, count(order_id) as orders, count(distinct customer_id) as unique_customers
from orders
where order_status = 'Approved'
group by order_date;

--3.1
select job_title
from customer
where job_title like 'Senior%'
and job_industry_category = 'IT'
  and date_part('year', age(dob)) > 35;

--3.2
select job_title
from customer
where job_industry_category = 'Financial Services'
  and job_title like 'Lead%'
  and date_part('year', age(dob)) > 35;

--3.3
select job_title
from customer
where job_title like 'Senior%'
  and job_industry_category = 'IT'
  and date_part('year', age(dob)) > 35

union all

select job_title
from customer
where job_industry_category = 'Financial Services'
  and job_title like 'Lead%'
  and date_part('year', age(dob)) > 35;


--4
select distinct brand
from product p
         left join order_items oi using (product_id)
         left join orders o using (order_id)
         left join customer c using (customer_id)
where c.job_industry_category = 'Financial Services'

except

select distinct brand
from product p
         left join order_items oi using (product_id)
         left join orders o using (order_id)
         left join customer c using (customer_id)
where c.job_industry_category = 'IT';

--5
with state_avg_valuation as (select state,
                                    avg(property_valuation) as avg_val
                             from customer
                             group by state),

     relevant_orders as (select o.customer_id,
                                o.order_id
                         from orders o
                                  join order_items oi on o.order_id = oi.order_id
                                  join product p on oi.product_id = p.product_id
                         where p.brand in ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
                           and o.online_order = true),

     customer_order_count as (select ro.customer_id,
                                     count(ro.order_id) as order_count
                              from relevant_orders ro
                              group by ro.customer_id),

     eligible_customers as (select c.customer_id,
                                   c.first_name,
                                   c.last_name,
                                   cov.order_count
                            from customer c
                                     join customer_order_count cov on c.customer_id = cov.customer_id
                                     join state_avg_valuation sav on c.state = sav.state
                            where c.property_valuation > sav.avg_val
                              and c.deceased_indicator = false)

select customer_id, first_name, last_name
from (select customer_id,
             first_name,
             last_name,
             order_count
      from eligible_customers
      order by order_count desc
      limit 10);


--6
select c.customer_id,
       c.first_name,
       c.last_name
from customer c
where c.owns_car = true

  and c.wealth_segment != 'Mass Customer'

  and not exists (select 1
                  from orders o
                  where o.customer_id = c.customer_id
                    and o.online_order = true
                    and o.order_status = 'Approved'
                    and o.order_date >= current_date - interval '1 year')
order by c.customer_id;


--7
with
top_5_road_products as (
  select product_id
  from product
  where product_line = 'Road'
  order by list_price desc
  limit 5
),

it_customer_purchases as (
  select
    c.customer_id,
    c.first_name,
    c.last_name,
    oi.product_id
  from customer c
  join orders o on c.customer_id = o.customer_id
  join order_items oi on o.order_id = oi.order_id
  join top_5_road_products t5 on oi.product_id = t5.product_id
  where c.job_industry_category = 'IT'
),

it_customer_product_count as (
  select
    customer_id,
    first_name,
    last_name,
    count(distinct product_id) as purchased_top_products
  from it_customer_purchases
  group by customer_id, first_name, last_name
)

select
  customer_id,
  first_name,
  last_name
from it_customer_product_count
where purchased_top_products = 2
order by customer_id;



--8
--it
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category as industry
from customer c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
where
    c.job_industry_category = 'IT'
    and o.order_status = 'Approved'
    and o.order_date >= '2017-01-01'
    and o.order_date < '2017-04-01'
group by c.customer_id, c.first_name, c.last_name, c.job_industry_category
having
    count(distinct o.order_id) >= 3
    and sum(oi.item_list_price_at_sale * oi.quantity) > 10000

union all

-- группа health
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category as industry
from customer c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
where
    c.job_industry_category = 'Health'
    and o.order_status = 'Approved'
    and o.order_date >= '2017-01-01'
    and o.order_date < '2017-04-01'
group by c.customer_id, c.first_name, c.last_name, c.job_industry_category
having
    count(distinct o.order_id) >= 3
    and sum(oi.item_list_price_at_sale * oi.quantity) > 10000

order by industry, customer_id;


