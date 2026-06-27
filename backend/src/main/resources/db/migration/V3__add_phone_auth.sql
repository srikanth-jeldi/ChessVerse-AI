alter table player_account alter column email drop not null;
alter table player_account add column phone varchar(20);
create unique index idx_player_account_phone on player_account(phone);
