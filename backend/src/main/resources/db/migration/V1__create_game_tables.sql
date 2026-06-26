create table chess_game (
    id uuid primary key,
    mode varchar(32) not null,
    status varchar(32) not null,
    fen varchar(128) not null,
    active_color varchar(16) not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create table chess_game_moves (
    chess_game_id uuid not null references chess_game(id) on delete cascade,
    moves varchar(8) not null
);

create index idx_chess_game_status on chess_game(status);

