-- Stable per-club catalogue offsets: adding a club must not change live puzzles.
create sequence club_puzzle_seed_seq;
alter table chess_club add column puzzle_seed bigint not null default nextval('club_puzzle_seed_seq');

-- One reward per account/day across every club; kept independently of membership.
create table club_daily_reward (
    player_id uuid not null references player_account(id) on delete cascade,
    reward_day date not null,
    streak integer not null check (streak > 0),
    coins integer not null check (coins > 0),
    primary key (player_id, reward_day)
);
