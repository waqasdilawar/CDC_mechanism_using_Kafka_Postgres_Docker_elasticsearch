-- docker exec -it postgres bash

-- psql -U postgres postgres

create database test_cdc;

\c test_cdc;

create table order_equipment_detail
(
    web_id                    bigint not null
        constraint pk_order_equipment_detail
            primary key,
    version                   bigint,
    date_created              timestamp with time zone,
    date_updated              timestamp with time zone,
    equipment_id              bigint,
    last_segment_id           bigint,
    last_completed_segment_id bigint
);


create table equipment
(
    web_id       bigint                                 not null
        constraint pk_equipment
            primary key,
    version      integer                  default 0     not null,
    date_updated timestamp with time zone default now() not null,
    date_created timestamp with time zone default now() not null,
    product_id   bigint
);


create table product
(
    web_id          bigint                                 not null
        constraint pk_product
            primary key,
    version         integer                  default 0     not null,
    date_created    timestamp with time zone default now() not null,
    date_updated    timestamp with time zone default now() not null,
    manufacturer_id bigint
);


ALTER TABLE order_equipment_detail
    REPLICA IDENTITY FULL;
ALTER TABLE equipment
    REPLICA IDENTITY FULL;
ALTER TABLE product
    REPLICA IDENTITY FULL;


SELECT CASE relreplident
           WHEN 'd' THEN 'default'
           WHEN 'n' THEN 'nothing'
           WHEN 'f' THEN 'full'
           WHEN 'i' THEN 'index'
           END AS replica_identity
FROM pg_class
WHERE oid in ('order_equipment_detail'::regclass,'equipment'::regclass,'product'::regclass);

CREATE PUBLICATION dbz_full_publication
    FOR TABLE order_equipment_detail,equipment,product;



SELECT * FROM pg_replication_slots;

select *
from order_equipment_detail d
where d .web_id = 1;

insert into product (web_id, version, date_created, date_updated, manufacturer_id)
values (1, DEFAULT, DEFAULT, DEFAULT, 1);

insert into equipment (web_id, version, date_updated, date_created, product_id)
values (3, DEFAULT, DEFAULT, DEFAULT, 1);

insert into order_equipment_detail (web_id, version, date_created, date_updated, equipment_id, last_segment_id,
                                    last_completed_segment_id)
values (7, 0, '2025-12-24 16:26:59.373000 +00:00', '2025-12-24 16:27:01.450000 +00:00', 3, 1, 3);