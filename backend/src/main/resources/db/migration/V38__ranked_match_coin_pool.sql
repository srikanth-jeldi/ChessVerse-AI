alter table online_match
    add column entry_coins integer not null default 0 check (entry_coins in (0, 100));

alter table online_match
    add column coin_pool_settled boolean not null default false;
