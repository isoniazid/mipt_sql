-- 1
select job_industry_category, count(*)
from customer
group by job_industry_category
order by count(*) desc;


-- 2
-- NB из задания было не совсем очевидно, надо ли группировать по всем признакам вместе, или по отдельности
-- Сгруппировал вместе
select extract(year from order_date)  as year,
       extract(month from order_date) as month,
       job_industry_category,
       sum(quantity * list_price)     as total_revenue
from orders
         left join customer using (customer_id)
         left join order_items using (order_id)
         left join product using (product_id)
where order_status = 'Approved'
group by extract(year from order_date),
         extract(month from order_date),
         job_industry_category
order by year,
         month,
         job_industry_category;

--3
--Не очень понятно из задания, что имеется ввиду под "уникальным" заказом.
-- Взял уникальность по order_id
with it_online_orders as (select distinct o.order_id
                          from orders o
                                   join customer c on o.customer_id = c.customer_id
                          where o.order_status = 'Approved'
                            and c.job_industry_category = 'IT'
                            and o.online_order = true),
     all_brands as (select distinct brand
                    from product),
     branded_orders as (select distinct p.brand,
                                        ioo.order_id
                        from it_online_orders ioo
                                 join order_items oi on ioo.order_id = oi.order_id
                                 join product p on oi.product_id = p.product_id)
select ab.brand,
       count(bo.order_id) as unique_online_orders_count
from all_brands ab
         left join branded_orders bo on ab.brand = bo.brand
group by ab.brand
order by ab.brand;



--4
--С GroupBy выполняется быстрее (93мс против 128мс)
-- И использует меньше памяти (93кб против 153)
-- Изучил с помощью explain analyze/memory

--4.1 group by
select customer_id,
       sum(order_price),
       max(order_price),
       min(order_price),
       count(order_price),
       avg(order_price)
from (select order_id, customer_id, coalesce(sum(quantity * list_price), 0) as order_price
      from orders
               left join order_items using (order_id)
               left join product using (product_id)
      group by order_id, customer_id) orders_price_with_customer
group by customer_id
order by sum(order_price) desc, count(order_price) desc;

--4.2 window func
with order_totals as (select o.order_id,
                             o.customer_id,
                             coalesce(sum(oi.quantity * p.list_price), 0) as order_price
                      from orders o
                               left join order_items oi on o.order_id = oi.order_id
                               left join product p on oi.product_id = p.product_id
                      group by o.order_id, o.customer_id),
     customer_aggregates as (select customer_id,
                                    order_price,
                                    sum(order_price) over (partition by customer_id)                       as total_revenue,
                                    max(order_price) over (partition by customer_id)                       as max_order,
                                    min(order_price) over (partition by customer_id)                       as min_order,
                                    count(order_price) over (partition by customer_id)                     as order_count,
                                    avg(order_price) over (partition by customer_id)                       as avg_order_amount,
                                    row_number() over (partition by customer_id order by order_price desc) as rn
                             from order_totals)
select customer_id,
       total_revenue,
       max_order,
       min_order,
       order_count,
       avg_order_amount
from customer_aggregates
where rn = 1
order by total_revenue desc,
         order_count desc;


--5
--5.1 ТОП-3 максимальной суммой транзакций
(select first_name, last_name, coalesce(sum(order_price), 0)
 from customer
          left join
      (select order_id, customer_id, coalesce(sum(quantity * list_price), 0) as order_price
       from orders
                left join order_items using (order_id)
                left join product using (product_id)
       group by order_id, customer_id) orders_price_with_customer using (customer_id)
 group by first_name, last_name
 order by coalesce(sum(order_price), 0) desc
 limit 3)


/*NB было не очень понятно, надо выводить и тех, и других вместе, или раздельно
Если нужно вместе, раскомментируйте строку ниже:*/

--union all

--5.2 ТОП-3 с минимальной суммой транзакций
(select first_name, last_name, coalesce(sum(order_price), 0)
 from customer
          left join
      (select order_id, customer_id, coalesce(sum(quantity * list_price), 0) as order_price
       from orders
                left join order_items using (order_id)
                left join product using (product_id)
       group by order_id, customer_id) orders_price_with_customer using (customer_id)
 group by first_name, last_name
 order by coalesce(sum(order_price), 0) asc
 limit 3);


--6
with ranked_orders as (select o.order_id,
                              o.customer_id,
                              o.order_date,
                              sum(oi.quantity * p.list_price) as order_total,
                              -- нумеруем заказы каждого клиента по дате
                              row_number() over (
                                  partition by o.customer_id
                                  order by o.order_date asc
                                  )                           as order_rank
                       from orders o
                                join customer c on o.customer_id = c.customer_id
                                join order_items oi on o.order_id = oi.order_id
                                join product p on oi.product_id = p.product_id
                       group by o.order_id, o.customer_id, c.first_name, c.last_name, o.order_date)
-- выбираем только вторые заказы (order_rank = 2)
select customer_id,
       order_id,
       order_date,
       order_total
from ranked_orders
where order_rank = 2
order by customer_id;


--7
select first_name, last_name, job_title, max(days_since_last_order) as max_gap
from (select customer_id,
             order_date -
             lag(order_date) over (partition by customer_id order by order_date) AS days_since_last_order
      from orders) deltas
         left join customer using (customer_id)
where days_since_last_order is not null
group by first_name, last_name, job_title
order by max_gap desc;


--8
with customer_revenue as (
    select
        c.first_name,
        c.last_name,
        c.wealth_segment,
        coalesce(sum(oi.quantity * p.list_price), 0) as total_revenue
    from
        customer c
        left join orders o on c.customer_id = o.customer_id
        left join order_items oi on o.order_id = oi.order_id
        left join product p on oi.product_id = p.product_id
    group by
        c.customer_id, c.first_name, c.last_name, c.wealth_segment
),
ranked_customers as (
    select
        first_name,
        last_name,
        wealth_segment,
        total_revenue,
        row_number() over (
            partition by wealth_segment
            order by total_revenue desc
        ) as revenue_rank
    from
        customer_revenue
)
select
    first_name,
    last_name,
    wealth_segment,
    total_revenue
from
    ranked_customers
where
    revenue_rank <= 5
order by
    wealth_segment,
    revenue_rank;
