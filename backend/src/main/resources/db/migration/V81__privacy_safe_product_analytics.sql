create table product_analytics_event (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    event_name varchar(48) not null,
    context_value varchar(48),
    occurred_at timestamp with time zone not null,
    received_at timestamp with time zone not null default current_timestamp,
    unique (player_id, id)
);

create index ix_product_analytics_event_time
    on product_analytics_event(occurred_at desc);

create index ix_product_analytics_event_player_time
    on product_analytics_event(player_id, occurred_at desc);

create index ix_product_analytics_event_name_time
    on product_analytics_event(event_name, occurred_at desc);
