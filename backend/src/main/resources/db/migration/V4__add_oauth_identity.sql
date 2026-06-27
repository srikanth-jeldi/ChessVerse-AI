create table oauth_identity (
    id uuid primary key,
    provider varchar(20) not null,
    subject varchar(255) not null,
    player_id uuid not null references player_account(id) on delete cascade,
    created_at timestamp with time zone not null,
    constraint uq_oauth_identity_provider_subject unique (provider, subject)
);

create index idx_oauth_identity_player on oauth_identity(player_id);
