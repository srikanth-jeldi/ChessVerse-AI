create table club_daily_completion (
    club_id uuid not null references chess_club(id) on delete cascade,
    player_id uuid not null references player_account(id) on delete cascade,
    puzzle_day date not null,
    completed_at timestamptz not null default now(),
    primary key (club_id, player_id, puzzle_day)
);
create index ix_club_daily_week on club_daily_completion(club_id,puzzle_day);
create table club_activity_match (
    match_id uuid primary key references online_match(id) on delete cascade,
    club_id uuid not null references chess_club(id) on delete cascade
);
create index ix_club_activity_matches on club_activity_match(club_id);
