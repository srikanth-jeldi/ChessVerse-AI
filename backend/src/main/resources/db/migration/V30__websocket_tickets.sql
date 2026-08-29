create table websocket_access_ticket (
    token_hash char(64) primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    match_id uuid not null references online_match(id) on delete cascade,
    expires_at timestamp with time zone not null,
    used_at timestamp with time zone,
    created_at timestamp with time zone not null
);

create index ix_websocket_ticket_expiry on websocket_access_ticket(expires_at);
