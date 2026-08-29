alter table chess_tournament add column current_round integer not null default 0;
alter table chess_tournament add column champion_id uuid references player_account(id) on delete set null;

create table chess_tournament_round (
    id uuid primary key,
    tournament_id uuid not null references chess_tournament(id) on delete cascade,
    round_number integer not null check (round_number > 0),
    status varchar(16) not null,
    created_at timestamp with time zone not null,
    completed_at timestamp with time zone,
    unique (tournament_id, round_number)
);

create table chess_tournament_pairing (
    id uuid primary key,
    round_id uuid not null references chess_tournament_round(id) on delete cascade,
    board_number integer not null check (board_number > 0),
    white_player_id uuid references player_account(id) on delete set null,
    black_player_id uuid references player_account(id) on delete set null,
    online_match_id uuid references online_match(id) on delete set null,
    winner_id uuid references player_account(id) on delete set null,
    status varchar(16) not null,
    created_at timestamp with time zone not null,
    completed_at timestamp with time zone,
    unique (round_id, board_number)
);
create index ix_tournament_pairing_match on chess_tournament_pairing(online_match_id);

-- The original catalog used migration-relative demo dates. Re-open empty
-- catalog tournaments with a real registration window on upgrade.
update chess_tournament t set starts_at=now()+interval '1 day',ends_at=now()+interval '8 days'
where status='OPEN' and not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id);
