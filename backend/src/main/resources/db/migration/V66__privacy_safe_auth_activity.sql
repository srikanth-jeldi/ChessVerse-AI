create table auth_activity_event (
    id uuid primary key,
    player_id uuid references player_account(id) on delete set null,
    event_type varchar(24) not null,
    auth_method varchar(24) not null,
    created_at timestamp with time zone not null default current_timestamp,
    reported_at timestamp with time zone,
    constraint chk_auth_activity_event_type check (event_type in ('REGISTERED', 'LOGIN')),
    constraint chk_auth_activity_method check (auth_method in ('PASSWORD', 'GOOGLE', 'FACEBOOK'))
);

create index idx_auth_activity_unreported
    on auth_activity_event(created_at)
    where reported_at is null;

