alter table player_account
    add column photo_url varchar(1024);

alter table online_match
    add column white_player_photo_url varchar(1024),
    add column black_player_photo_url varchar(1024);
