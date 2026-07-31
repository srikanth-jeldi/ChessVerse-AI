alter table player_account
    add column guest_account boolean not null default false;

create table guest_installation (
    installation_hash varchar(64) primary key,
    player_id uuid not null unique references player_account(id) on delete cascade,
    created_at timestamp with time zone not null,
    last_seen_at timestamp with time zone not null
);

create index idx_guest_installation_player on guest_installation(player_id);
