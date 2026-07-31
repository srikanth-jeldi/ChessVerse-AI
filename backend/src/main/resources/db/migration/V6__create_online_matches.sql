create table online_match (
    id uuid primary key,
    room_code varchar(8) not null unique,
    status varchar(16) not null,
    white_player_id uuid not null references player_account(id),
    white_player_name varchar(80) not null,
    black_player_id uuid references player_account(id),
    black_player_name varchar(80),
    random_queue boolean not null,
    active_color varchar(8) not null,
    fen varchar(128) not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null,
    version bigint not null default 0
);

create table online_match_move (
    match_id uuid not null references online_match(id) on delete cascade,
    ply_index integer not null,
    uci varchar(8) not null,
    primary key (match_id, ply_index)
);

create index idx_online_match_queue on online_match(random_queue, status, created_at);
create index idx_online_match_white on online_match(white_player_id, status);
create index idx_online_match_black on online_match(black_player_id, status);
