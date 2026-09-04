-- Recurring, coin-only skill tournament circuit. Coins never represent cash
-- and cannot be withdrawn or transferred outside ChessVerseAI.
alter table chess_tournament drop constraint if exists chess_tournament_entry_coins_check;
alter table chess_tournament
    add constraint chess_tournament_entry_coins_check
    check (entry_coins in (100, 250, 500, 750, 1000)),
    add column if not exists series_code varchar(32),
    add column if not exists occurrence_number integer not null default 1,
    add column if not exists cadence_days integer,
    add column if not exists minimum_players integer not null default 2,
    add column if not exists badge_code varchar(48),
    add column if not exists champion_bonus integer not null default 0,
    add column if not exists runner_up_bonus integer not null default 0,
    add column if not exists participation_bonus integer not null default 0,
    add column if not exists runner_up_id uuid references player_account(id) on delete set null;

create unique index if not exists ux_tournament_series_occurrence
    on chess_tournament(series_code, occurrence_number)
    where series_code is not null;

create table if not exists player_tournament_badge (
    player_id uuid not null references player_account(id) on delete cascade,
    tournament_id uuid not null references chess_tournament(id) on delete cascade,
    badge_code varchar(48) not null,
    placement varchar(20) not null,
    awarded_at timestamp with time zone not null,
    primary key(player_id, tournament_id, badge_code)
);
create index if not exists ix_tournament_badge_player
    on player_tournament_badge(player_id, awarded_at desc);

-- Stagger the initial season. Later occurrences are created automatically by
-- TournamentScheduler only after the preceding occurrence completes.
update chess_tournament t set
    entry_coins=100, series_code='HYDERABAD_ROYAL', cadence_days=7,
    minimum_players=4, badge_code='HYDERABAD_ROYAL_CREST',
    champion_bonus=500, runner_up_bonus=250, participation_bonus=25,
    starts_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '7 days' else starts_at end,
    ends_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '8 days' else ends_at end
where id='22000000-0000-0000-0000-000000000001' and current_round=0;

update chess_tournament t set
    entry_coins=250, series_code='TOKYO_NEON', cadence_days=14,
    minimum_players=4, badge_code='TOKYO_NEON_SHOGUN',
    champion_bonus=1200, runner_up_bonus=600, participation_bonus=50,
    starts_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '14 days' else starts_at end,
    ends_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '15 days' else ends_at end
where id='22000000-0000-0000-0000-000000000002' and current_round=0;

update chess_tournament t set
    entry_coins=500, series_code='DUBAI_GOLD', cadence_days=30,
    minimum_players=4, badge_code='DUBAI_GOLD_FALCON',
    champion_bonus=3000, runner_up_bonus=1500, participation_bonus=100,
    starts_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '30 days' else starts_at end,
    ends_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '31 days' else ends_at end
where id='22000000-0000-0000-0000-000000000003' and current_round=0;

update chess_tournament t set
    entry_coins=750, series_code='LONDON_CLASSIC', cadence_days=60,
    minimum_players=8, badge_code='LONDON_CLASSIC_CROWN',
    champion_bonus=5000, runner_up_bonus=2500, participation_bonus=150,
    starts_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '60 days' else starts_at end,
    ends_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '61 days' else ends_at end
where id='22000000-0000-0000-0000-000000000004' and current_round=0;

update chess_tournament t set
    entry_coins=1000, series_code='NEW_YORK_FINAL', cadence_days=90,
    minimum_players=8, badge_code='NEW_YORK_GRAND_CHAMPION',
    champion_bonus=8000, runner_up_bonus=4000, participation_bonus=250,
    starts_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '90 days' else starts_at end,
    ends_at=case when not exists(select 1 from chess_tournament_entry e where e.tournament_id=t.id and e.active=true) then now()+interval '91 days' else ends_at end
where id='22000000-0000-0000-0000-000000000005' and current_round=0;
