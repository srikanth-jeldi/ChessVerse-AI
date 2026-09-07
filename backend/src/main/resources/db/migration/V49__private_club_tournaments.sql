alter table chess_tournament
    add column club_id uuid references chess_club(id) on delete cascade,
    add column created_by uuid references player_account(id) on delete set null;

create index ix_chess_tournament_club
    on chess_tournament(club_id, starts_at desc)
    where club_id is not null;
