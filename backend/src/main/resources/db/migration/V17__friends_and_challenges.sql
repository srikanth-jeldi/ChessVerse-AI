create table friend_connection (
    id uuid primary key,
    requester_id uuid not null references player_account(id) on delete cascade,
    addressee_id uuid not null references player_account(id) on delete cascade,
    status varchar(16) not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    constraint friend_connection_not_self check (requester_id <> addressee_id)
);
create unique index uq_friend_connection_pair on friend_connection
    (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index ix_friend_requester on friend_connection(requester_id, status);
create index ix_friend_addressee on friend_connection(addressee_id, status);

create table social_challenge (
    id uuid primary key,
    challenger_id uuid not null references player_account(id) on delete cascade,
    challenged_id uuid not null references player_account(id) on delete cascade,
    match_id uuid not null references online_match(id) on delete cascade,
    room_code varchar(8) not null,
    time_control_minutes integer not null,
    status varchar(16) not null,
    expires_at timestamp with time zone not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);
create index ix_social_challenge_inbox on social_challenge(challenged_id, status, created_at desc);
create index ix_social_challenge_outbox on social_challenge(challenger_id, status, created_at desc);
