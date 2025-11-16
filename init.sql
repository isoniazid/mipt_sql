--Спецификации продукта
create table product_spec
(
    spec_id       integer primary key not null,
    product_line  varchar         not null,
    product_class varchar         not null,
    product_size  varchar         not null
);

create table product
(
    product_id      integer primary key not null,
    brand           varchar,                  -- В исходных есть пустые
    list_price      decimal(12, 2)      not null, -- Цена указывается до двух знаков после запятой в оригинале
    standart_cost   decimal(12, 2),               -- Цена указывается до двух знаков после запятой в оригинале. Есть пустые
    product_spec_id integer             references product_spec (spec_id) on delete set null
    --set null, потому что в доке есть продукты без спецификаций
);

create table job
(
    job_id                integer primary key,
    job_title             varchar, --nullable, потому что в исходных есть пустые
    job_industry_category varchar  --nullable, потому что в исходных есть n/a
);

create table address
(
    address_id integer primary key,
    postcode   integer     not null,
    state      varchar not null,

    /*Вообще, судя по данным, все пользователи из Австралии, поэтому,
      если сервис исключительно австралийский, можно этот атрибут убрать вообще
    */
    country    varchar not null,
    building   integer,
    street     varchar
);

create table customer
(
    customer_id         integer primary key not null,
    first_name          varchar         not null,
    last_name           varchar,                  --nullable, потому что есть пустые

    --Female/F = false
    gender              boolean,                      --nullable, потому что есть Unknown, boolean потому что пола только два
    dob                 timestamp,                    --nullable, потому что есть пустые
    decreased_indicator boolean             not null, --boolean отому что только да/нет
    owns_car            boolean             not null, --boolean, потому что да/нет
    wealth_segment      varchar,

    --У нас нет клиентов без адреса, поэтому каскад
    address_id          integer             not null references address (address_id) on delete cascade,

    property_valuation  integer             not null,

    --Безработных тоже нет, поэтому каскад
    job_id              integer             not null references job (job_id) on delete cascade
);


create table transaction
(
    transaction_id   integer primary key not null,
    product_id       integer             not null
        references product (product_id) on delete cascade,
    --cascade, потому что смысл нет в транзакции без товара
    customer_id      integer             not null
        references customer (customer_id) on delete cascade,
    --cascade, потому что смысла нет в транзакции без клиента
    transaction_date timestamp           not null,
    online_order     boolean, --Т.к. принимает только true/false. nullable, потому что в исходных данных есть пустые
    order_status     varchar         not null
);


------Заполняем БД - данные для первых 5 клиентов (привел к виду, в котором будут в бд)
insert into job (job_id, job_title, job_industry_category)
values (1, 'Executive Secretary', 'Health'),
       (2, 'Administrative Officer', 'Financial Services'),
       (3, 'Recruiting Manager', 'Property'),
       (4, null, 'IT'),
       (5, 'Senior Editor', null);

insert into address (address_id, postcode, state, country, building, street)
values (1, 2016, 'New South Wales', 'Australia', 60, 'Morning Avenue'),
       (2, 2153, 'New South Wales', 'Australia', 6, 'Meadow Vale Court'),
       (3, 4211, 'QLD', 'Australia', 0, 'Holy Cross Court'),
       (4, 2448, 'New South Wales', 'Australia', 17979, 'Del Mar Point'),
       (5, 3216, 'VIC', 'Australia', 9, 'Oakridge Court');

insert into customer (customer_id,
                      first_name,
                      last_name,
                      gender,
                      dob,
                      decreased_indicator,
                      owns_car,
                      wealth_segment,
                      address_id,
                      property_valuation,
                      job_id)
values (1, 'Laraine', 'Medendorp', true, '1953-10-12 00:00:00', false, true, 'Mass Customer', 1, 10, 1),
       (2, 'Eli', 'Bockman', false, '1980-12-16 00:00:00', false, true, 'Mass Customer', 2, 10, 2),
       (3, 'Arlin', 'Dearle', false, '1954-01-20 00:00:00', false, true, 'Mass Customer', 3, 9, 3),
       (4, 'Talbot', null, false, '1961-10-03 00:00:00', false, false, 'Mass Customer', 4, 4, 4),
       (5, 'Sheila-kathryn', 'Calton', true, '1977-05-13 00:00:00', false, true, 'Affluent Customer', 5, 9, 5);


--Вставим 10 транзакций для первых 10 клиентов, приведенные к виду для бд
insert into product_spec (spec_id, product_line, product_class, product_size)
values
(1, 'Standard', 'medium', 'medium'),
(2, 'Road', 'low', 'small'),
(3, 'Standard', 'high', 'medium'),
(4, 'Mountain', 'low', 'medium'),
(5, 'Standard', 'medium', 'small'),
(6, 'Standard', 'medium', 'large'),
(7, 'Road', 'medium', 'large'),
(8, 'Road', 'medium', 'medium'),
(9, 'Standard', 'low', 'medium'),
(10, 'Road', 'high', 'large');

insert into product (product_id, brand, list_price, standart_cost, product_spec_id)
values
    (2, 'Solex', 71.49, 53.62, 1),
    (9, 'OHM Cycles', 742.54, 667.40, 8),
    (23, 'Norco Bicycles', 688.63, 612.88, 9),
    (25, 'Giant Bicycles', 1538.99, 829.65, 8),
    (31, 'Giant Bicycles', 230.91, 173.18, 1),
    (32, 'Giant Bicycles', 642.70, 211.37, 1),
    (38, 'Solex', 1577.53, 826.51, 1),
    (47, 'Trek Bicycles', 1720.70, 1531.42, 2),
    (72, 'Norco Bicycles', 360.40, 270.30, 1),
    (86, 'OHM Cycles', 235.63, 125.07, 1);


insert into transaction (transaction_id,
                         product_id,
                         customer_id,
                         transaction_date,
                         online_order,
                         order_status)
values (94, 86, 1, '2017-12-23', false, 'Approved'),
       (3765, 38, 1, '2017-04-06', true, 'Approved'),
       (5157, 47, 1, '2017-05-11', true, 'Approved'),
       (9785, 72, 1, '2017-01-05', false, 'Approved'),
       (13424, 2, 1, '2017-02-21', false, 'Approved'),
       (13644, 25, 1, '2017-05-19', false, 'Approved'),
       (14486, 23, 1, '2017-03-27', false, 'Approved'),
       (14931, 31, 1, '2017-12-14', true, 'Approved'),
       (15663, 32, 1, '2017-06-04', true, 'Approved'),
       (16423, 9, 1, '2017-12-09', true, 'Approved');