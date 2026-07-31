create table player_cloud_progress (
    player_id uuid primary key references player_account(id) on delete cascade,
    profile_username varchar(24),
    country varchar(64) not null default 'India',
    chess_level integer not null default 0 check (chess_level between 0 and 4),
    avatar integer not null default 0 check (avatar between 0 and 5),
    profile_updated_at timestamp with time zone,
    daily_streak integer not null default 0 check (daily_streak >= 0),
    last_daily_completed_at timestamp with time zone,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create table player_completed_puzzle (
    player_id uuid not null references player_cloud_progress(player_id) on delete cascade,
    puzzle_id varchar(64) not null,
    primary key (player_id, puzzle_id)
);

create table player_completed_daily_challenge (
    player_id uuid not null references player_cloud_progress(player_id) on delete cascade,
    challenge_id varchar(64) not null,
    primary key (player_id, challenge_id)
);
