create table online_player_rating (
    player_id uuid primary key references player_account(id) on delete cascade,
    display_name varchar(80) not null,
    country varchar(64) not null default 'Unknown',
    rating integer not null default 1200 check (rating >= 100),
    peak_rating integer not null default 1200 check (peak_rating >= 100),
    games_played integer not null default 0 check (games_played >= 0),
    wins integer not null default 0 check (wins >= 0),
    draws integer not null default 0 check (draws >= 0),
    losses integer not null default 0 check (losses >= 0),
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone not null
);

create index idx_online_rating_global
    on online_player_rating(rating desc, wins desc, games_played desc);
create index idx_online_rating_country
    on online_player_rating(country, rating desc, wins desc, games_played desc);

insert into online_player_rating (
    player_id, display_name, country, rating, peak_rating,
    games_played, wins, draws, losses, created_at, updated_at
)
select id, display_name, 'Unknown', 1200, 1200, 0, 0, 0, 0, now(), now()
from player_account
on conflict (player_id) do nothing;

alter table online_match
    add column rated_at timestamp with time zone,
    add column white_rating_before integer,
    add column white_rating_after integer,
    add column black_rating_before integer,
    add column black_rating_after integer;
