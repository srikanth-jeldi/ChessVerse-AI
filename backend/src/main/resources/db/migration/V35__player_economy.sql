create table player_wallet (
    player_id uuid primary key references player_account(id) on delete cascade,
    coin_balance bigint not null default 500 check (coin_balance >= 0),
    diamond_balance bigint not null default 10 check (diamond_balance >= 0),
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create table economy_transaction (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    currency varchar(16) not null check (currency in ('COINS', 'DIAMONDS')),
    amount bigint not null check (amount <> 0),
    balance_after bigint not null check (balance_after >= 0),
    transaction_type varchar(40) not null,
    reference_key varchar(160) not null,
    description varchar(160) not null,
    created_at timestamp with time zone not null,
    unique (player_id, reference_key)
);

create index ix_economy_transaction_history
    on economy_transaction(player_id, created_at desc);
