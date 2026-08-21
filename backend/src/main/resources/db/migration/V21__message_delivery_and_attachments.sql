alter table direct_message add column delivered_at timestamp with time zone;
alter table direct_message add column attachment_name varchar(255);
alter table direct_message add column attachment_type varchar(120);
alter table direct_message add column attachment_size bigint;
alter table direct_message add column attachment_path varchar(255);

create index ix_direct_message_delivery
    on direct_message(recipient_id, delivered_at)
    where delivered_at is null;
