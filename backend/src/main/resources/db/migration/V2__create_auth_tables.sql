create table player_account (
    id uuid primary key,
    username varchar(40) not null unique,
    display_name varchar(80) not null,
    email varchar(254) not null unique,
    password_hash varchar(100) not null,
    verified boolean not null default false,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create table email_verification (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    code_hash varchar(100) not null,
    expires_at timestamp with time zone not null,
    consumed_at timestamp with time zone,
    attempts integer not null default 0,
    created_at timestamp with time zone not null
);

create index idx_email_verification_player on email_verification(player_id);

create table auth_session (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    token_hash varchar(64) not null unique,
    expires_at timestamp with time zone not null,
    created_at timestamp with time zone not null
);

create index idx_auth_session_player on auth_session(player_id);
