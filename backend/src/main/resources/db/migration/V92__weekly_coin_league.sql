create table coin_league_config (
 id integer primary key check (id=1), first_week date not null
);
-- Start with a complete week; never retroactively pay historical weeks.
insert into coin_league_config values (1,
 (date_trunc('week', now() at time zone 'Asia/Kolkata') + interval '7 days')::date);
create table coin_league_excluded_player (
 player_id uuid primary key references player_account(id) on delete cascade
);
insert into coin_league_excluded_player select id from player_account
 where id='6d79c348-1487-40b7-87bd-130bf3b9c43e';
create table coin_league_week (
 week_start date primary key, settled_at timestamptz not null
);
create table coin_league_prize (
 week_start date not null references coin_league_week(week_start),
 place integer not null check(place between 1 and 3),
 player_id uuid not null references player_account(id),
 coins_won bigint not null, prize integer not null,
 primary key(week_start,place), unique(week_start,player_id)
);
create index idx_online_match_coin_league on online_match(finished_at)
 where status='FINISHED' and coin_pool_settled=true and entry_coins>0;
