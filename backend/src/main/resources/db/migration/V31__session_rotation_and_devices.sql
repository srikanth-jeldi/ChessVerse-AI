alter table auth_session add column refresh_token_hash varchar(64);
alter table auth_session add column token_family_id uuid;
alter table auth_session add column device_id varchar(128);
alter table auth_session add column device_name varchar(160);
alter table auth_session add column last_used_at timestamp with time zone;
alter table auth_session add column revoked_at timestamp with time zone;

update auth_session
set token_family_id = id,
    device_name = 'Legacy session',
    last_used_at = created_at
where token_family_id is null;

alter table auth_session alter column token_family_id set not null;
alter table auth_session alter column last_used_at set not null;
create unique index uq_auth_session_refresh_token_hash
    on auth_session(refresh_token_hash) where refresh_token_hash is not null;
create index idx_auth_session_family on auth_session(token_family_id);
create index idx_auth_session_player_last_used on auth_session(player_id, last_used_at desc);
