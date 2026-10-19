-- Keep the old account-wide ledger intact for audit; future awards are club-scoped.
create table club_daily_reward_by_club (
    player_id uuid not null references player_account(id) on delete cascade,
    club_id uuid not null references chess_club(id) on delete cascade,
    reward_day date not null,
    streak integer not null check (streak > 0),
    coins integer not null check (coins >= 0),
    primary key (player_id, club_id, reward_day)
);

-- Reconstruct each club's real consecutive completion history. Do not grant
-- retroactive coins or copy one account-wide streak into every club.
-- The first completed club that day owns the historical account-wide reward.
insert into club_daily_reward_by_club(player_id, club_id, reward_day, streak, coins)
with numbered as (
    select c.*,
           puzzle_day - (row_number() over (
               partition by player_id, club_id order by puzzle_day))::integer as run,
           row_number() over (
               partition by player_id, puzzle_day order by completed_at, club_id) as daily_order
    from club_daily_completion c
), history as (
    select n.*, row_number() over (
        partition by player_id, club_id, run order by puzzle_day)::integer as club_streak
    from numbered n
)
select h.player_id, h.club_id, h.puzzle_day, h.club_streak,
       case when h.daily_order=1 then coalesce(r.coins,0) else 0 end
from history h left join club_daily_reward r
    on r.player_id=h.player_id and r.reward_day=h.puzzle_day;
