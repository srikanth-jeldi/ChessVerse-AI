create table push_notification_device (
    id uuid primary key,
    player_id uuid not null,
    installation_id varchar(80) not null,
    platform varchar(20) not null,
    token text not null,
    enabled boolean not null default true,
    created_at timestamptz not null,
    updated_at timestamptz not null,
    constraint uq_push_device_installation unique (player_id, installation_id),
    constraint uq_push_device_token unique (token)
);

create index idx_push_device_player on push_notification_device(player_id, enabled);
