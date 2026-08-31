create table purchase_product (
    id uuid primary key,
    sku varchar(80) not null unique,
    display_name varchar(100) not null,
    description varchar(220) not null,
    grant_currency varchar(16) not null check (grant_currency in ('COINS', 'DIAMONDS')),
    grant_amount bigint not null check (grant_amount > 0),
    price_minor bigint not null check (price_minor > 0),
    price_currency char(3) not null,
    active boolean not null default true,
    sort_order integer not null default 0,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create table purchase_order (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete restrict,
    product_id uuid not null references purchase_product(id) on delete restrict,
    provider varchar(24) not null check (provider in ('GOOGLE_PLAY', 'APPLE_STOREKIT', 'RAZORPAY')),
    status varchar(24) not null check (status in ('CREATED', 'PENDING', 'VERIFIED', 'FULFILLED', 'FAILED', 'REFUNDED', 'REVOKED')),
    idempotency_key uuid not null,
    price_minor bigint not null check (price_minor > 0),
    price_currency char(3) not null,
    grant_currency varchar(16) not null check (grant_currency in ('COINS', 'DIAMONDS')),
    grant_amount bigint not null check (grant_amount > 0),
    provider_order_id varchar(180),
    provider_transaction_hash char(64),
    failure_code varchar(80),
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    verified_at timestamp with time zone,
    fulfilled_at timestamp with time zone,
    unique (player_id, idempotency_key),
    unique (provider, provider_transaction_hash)
);

alter table player_wallet
    add column coin_debt bigint not null default 0 check (coin_debt >= 0);

create table purchase_provider_event (
    id uuid primary key,
    provider varchar(24) not null,
    event_id_hash char(64) not null,
    event_type varchar(80) not null,
    payload_hash char(64) not null,
    processing_status varchar(24) not null check (processing_status in ('RECEIVED','PROCESSED','IGNORED','FAILED')),
    received_at timestamp with time zone not null,
    processed_at timestamp with time zone,
    unique(provider,event_id_hash)
);

create table purchase_reversal (
    order_id uuid primary key references purchase_order(id) on delete restrict,
    player_id uuid not null references player_account(id) on delete restrict,
    coins_revoked bigint not null check (coins_revoked >= 0),
    coin_debt_added bigint not null check (coin_debt_added >= 0),
    provider_event_hash char(64) not null,
    created_at timestamp with time zone not null
);

create unique index ux_purchase_order_provider_order
    on purchase_order(provider,provider_order_id) where provider_order_id is not null;

create index ix_purchase_order_player_history
    on purchase_order(player_id, created_at desc);
create index ix_purchase_order_pending
    on purchase_order(status, updated_at) where status in ('CREATED', 'PENDING', 'VERIFIED');

-- Direct coin packs only. There is no stored-money balance: the amount below
-- is the pack's base price and is snapshotted server-side. Channel taxes and
-- the final payable amount are presented by the approved checkout provider.
insert into purchase_product(id,sku,display_name,description,grant_currency,grant_amount,
                             price_minor,price_currency,active,sort_order,created_at,updated_at)
values
('42000000-0000-0000-0000-000000000001','coins_500','500 Coins','Starter coin pack','COINS',500,38000,'INR',true,10,current_timestamp,current_timestamp);
