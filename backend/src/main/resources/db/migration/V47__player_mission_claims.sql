create table player_mission_claim (
    player_id uuid not null references player_account(id) on delete cascade,
    mission_code varchar(48) not null,
    period_start date not null,
    reward_coins integer not null check (reward_coins between 1 and 500),
    claimed_at timestamp with time zone not null,
    primary key (player_id, mission_code, period_start)
);

create index ix_player_mission_claim_recent
    on player_mission_claim(player_id, claimed_at desc);
