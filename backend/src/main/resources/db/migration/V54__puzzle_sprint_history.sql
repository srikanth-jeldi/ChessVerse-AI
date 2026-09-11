create table puzzle_sprint_result (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    mode varchar(20) not null check (mode in ('RUSH','SURVIVAL','MATE_IN_ONE')),
    score integer not null check (score >= 0),
    attempted integer not null check (attempted >= score),
    duration_seconds integer not null check (duration_seconds >= 0),
    played_at timestamp with time zone not null
);

create index idx_puzzle_sprint_leaderboard
    on puzzle_sprint_result(mode, score desc, duration_seconds asc, played_at asc);
create index idx_puzzle_sprint_player
    on puzzle_sprint_result(player_id, played_at desc);
