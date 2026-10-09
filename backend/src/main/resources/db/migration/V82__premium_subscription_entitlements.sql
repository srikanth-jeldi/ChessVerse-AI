create table premium_entitlement (
    player_id uuid primary key references player_account(id) on delete cascade,
    status varchar(16) not null check (status in ('TRIAL','ACTIVE','EXPIRED','REVOKED')),
    source varchar(24) not null check (source in ('APP_TRIAL','GOOGLE_PLAY','APPLE_STOREKIT','SUPPORT')),
    product_id varchar(80),
    base_plan_id varchar(80),
    started_at timestamp with time zone not null,
    expires_at timestamp with time zone not null,
    auto_renewing boolean not null default false,
    provider_token_hash char(64),
    updated_at timestamp with time zone not null,
    unique (source, provider_token_hash)
);

-- The raw installation identifier never leaves the request. Only a one-way
-- SHA-256 digest is retained to prevent repeated trials on the same install.
create table premium_trial_installation (
    installation_hash char(64) primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    claimed_at timestamp with time zone not null
);

create index ix_premium_entitlement_expiry
    on premium_entitlement(status, expires_at);

create table premium_plan_catalog (
    base_plan_id varchar(80) primary key,
    product_id varchar(80) not null,
    billing_period varchar(16) not null check (billing_period in ('MONTHLY','YEARLY')),
    india_price_minor bigint not null check (india_price_minor > 0),
    currency char(3) not null,
    active boolean not null default true,
    updated_at timestamp with time zone not null
);

insert into premium_plan_catalog(base_plan_id,product_id,billing_period,
                                 india_price_minor,currency,active,updated_at)
values
('monthly','chessverse_premium','MONTHLY',9900,'INR',true,current_timestamp),
('yearly','chessverse_premium','YEARLY',99900,'INR',true,current_timestamp);
