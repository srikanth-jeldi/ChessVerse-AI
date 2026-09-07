alter table direct_message
    add column deleted_for_sender boolean not null default false,
    add column deleted_for_recipient boolean not null default false,
    add column deleted_for_everyone_at timestamp with time zone;

create table direct_message_reaction (
    message_id uuid not null references direct_message(id) on delete cascade,
    player_id uuid not null references player_account(id) on delete cascade,
    emoji varchar(16) not null,
    reacted_at timestamp with time zone not null,
    primary key (message_id, player_id)
);
