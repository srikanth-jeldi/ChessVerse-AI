create table if not exists chat_e2ee_identity (
    player_id uuid primary key references player_account(id) on delete cascade,
    public_key varchar(128) not null,
    encrypted_private_key varchar(512) not null,
    backup_salt varchar(128) not null,
    backup_nonce varchar(128) not null,
    backup_kdf_iterations integer not null check (backup_kdf_iterations between 100000 and 2000000),
    updated_at timestamp with time zone not null default current_timestamp
);

alter table direct_message add column if not exists encrypted boolean not null default false;
alter table direct_message alter column body type text;

create index if not exists idx_chat_e2ee_identity_updated
    on chat_e2ee_identity(updated_at desc);
