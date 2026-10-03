create table notification_delivery_guard (
    player_id uuid not null references player_account(id) on delete cascade,
    notification_type varchar(40) not null,
    delivery_key varchar(120) not null,
    created_at timestamp with time zone not null default current_timestamp,
    primary key (player_id, notification_type, delivery_key)
);

create index ix_notification_delivery_guard_created
    on notification_delivery_guard(created_at);
