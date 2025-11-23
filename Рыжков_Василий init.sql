/*
NB: Я немного поправил исходные данные, чтобы они более корректно отображались в таблице, а именно:
CUSTOMER:
1. Привел пол к единообразию, заменив текстовое обозначение на boolean. true - мужской, false - женский, U - null
2. Deceased indicator: true = Y, false = N
3. Owns car: true = yes, false = no
4. job_industry category: n/a = null

ORDERS:
убрал три записи, ссылающиеся на клиента 5034, поскольку его нет в таблице
customers. Без информации о заказчике запись о заказе все равно не имеет смысла.
Я бы мог разрешить ссылаться на несуществующих клиентов, например с помощью on delete no action,
но это бы не очень хорошо отразилось на целостности данных

PRODUCT:
в исходном CSV много дубликатов по ID, что нарушает целостность данных
и порождает вопросы к бизнес-логике
(например, у нас заказ order_item с product_id = 0  quantity = 10.
Что это? один из продуктов с ключом 0, заказанный в количестве 10 штук?
Все продукты с этим ключом, заказанные в количестве 10 штук (итого 30-40 товаров)?

Для решения проблемы убрал из исходных данных дубликаты, загружал только
первый вариант, встречавшийся из набора с одинаковыми первичными ключами

ORDER_ITEMS:
Убрал запись, ссылающуюся на заказ 8708, т.к. его нет в таблице заказов
(эта запись ссылается на несуществующего клиента, поэтому я ранее ее оттуда убрал)

P.S:
По требованию задания я приложил к ответу скриншоты из DBeaver, но лично мне удобней
работать в JetBrains DataGrip. Если для Вас при проверке не принципиально, в каком
редакторе были выполнены скрины, в следующий раз я бы мог приложить их из DataGrip,
тем более, что особых различий там не будет.
*/

--customer
create table customer
(
    customer_id           integer primary key not null,
    first_name            varchar             not null,
    last_name             varchar,
    gender                boolean,
    dob                   date,
    job_title             varchar,
    job_industry_category varchar,
    wealth_segment        varchar             not null,
    deceased_indicator    boolean             not null,
    owns_car              boolean             not null,
    address               varchar             not null,
    postcode              integer             not null,
    state                 varchar             not null,
    country               varchar             not null,
    property_valuation    integer             not null
);

--product
create table product
(
    product_id    integer primary key not null,
    brand         varchar             not null,
    product_line  varchar             not null,
    product_class varchar             not null,
    product_size  varchar             not null,
    list_price    decimal(12, 2)      not null,
    standard_cost decimal(12, 2)      not null
);

--order
create table orders
(
    order_id     integer primary key not null,
    customer_id  integer             not null references customer (customer_id) on delete cascade,
    order_date   date                not null,
    online_order boolean,
    order_status varchar             not null
);

--order_item
create table order_items
(
    order_item_id              integer primary key not null,
    order_id                   integer             not null references orders (order_id) on delete cascade,
    product_id                 integer             not null references product (product_id) on delete cascade,
    quantity                   integer             not null check ( quantity > 0 ), --Нам нет смысла делать запись, если товаров нет в заказе
    item_list_price_at_sale    decimal(12, 2)      not null,
    item_standard_cost_at_sale decimal(12, 2)      null
);