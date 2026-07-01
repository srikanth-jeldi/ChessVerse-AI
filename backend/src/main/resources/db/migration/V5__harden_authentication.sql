alter table player_account
    add column failed_login_attempts integer not null default 0;

alter table player_account
    add column locked_until timestamp with time zone;

create table password_reset (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    code_hash varchar(100) not null,
    expires_at timestamp with time zone not null,
    consumed_at timestamp with time zone,
    attempts integer not null default 0,
    created_at timestamp with time zone not null
);

create index idx_password_reset_player on password_reset(player_id);
