create table player_notification (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    type varchar(40) not null,
    title varchar(120) not null,
    body varchar(360) not null,
    action_type varchar(32),
    action_id uuid,
    created_at timestamp with time zone not null,
    read_at timestamp with time zone
);
create index ix_player_notification_inbox
    on player_notification(player_id, created_at desc);
create index ix_player_notification_unread
    on player_notification(player_id, read_at) where read_at is null;
