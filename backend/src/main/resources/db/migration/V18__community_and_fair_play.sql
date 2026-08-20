create table chess_club (
    id uuid primary key,
    name varchar(80) not null unique,
    description varchar(240) not null,
    rating_requirement integer not null default 0,
    created_at timestamp with time zone not null
);
create table chess_club_member (
    club_id uuid not null references chess_club(id) on delete cascade,
    player_id uuid not null references player_account(id) on delete cascade,
    role varchar(16) not null default 'MEMBER',
    joined_at timestamp with time zone not null,
    primary key (club_id, player_id)
);
create index ix_chess_club_member_player on chess_club_member(player_id);

create table chess_tournament (
    id uuid primary key,
    name varchar(100) not null,
    description varchar(300) not null,
    time_control_minutes integer not null,
    capacity integer not null,
    starts_at timestamp with time zone not null,
    ends_at timestamp with time zone not null,
    status varchar(16) not null
);
create table chess_tournament_entry (
    tournament_id uuid not null references chess_tournament(id) on delete cascade,
    player_id uuid not null references player_account(id) on delete cascade,
    joined_at timestamp with time zone not null,
    primary key (tournament_id, player_id)
);

create table direct_message (
    id uuid primary key,
    sender_id uuid not null references player_account(id) on delete cascade,
    recipient_id uuid not null references player_account(id) on delete cascade,
    body varchar(500) not null,
    sent_at timestamp with time zone not null,
    read_at timestamp with time zone
);
create index ix_direct_message_conversation on direct_message(sender_id, recipient_id, sent_at desc);

create table fair_play_signal (
    id uuid primary key,
    player_id uuid not null references player_account(id) on delete cascade,
    match_id uuid references online_match(id) on delete cascade,
    signal_type varchar(40) not null,
    severity integer not null check (severity between 1 and 5),
    evidence varchar(500) not null,
    created_at timestamp with time zone not null
);
create index ix_fair_play_player on fair_play_signal(player_id, created_at desc);

insert into chess_club values
('11000000-0000-0000-0000-000000000001', 'Royal Knights', 'Learn together, compete together, grow together.', 1200, now()),
('11000000-0000-0000-0000-000000000002', 'Checkmate Academy', 'Structured improvement for ambitious players.', 800, now()),
('11000000-0000-0000-0000-000000000003', 'Blitz Warriors', 'Fast chess, sharp tactics and weekly arenas.', 1000, now());

insert into chess_tournament values
('22000000-0000-0000-0000-000000000001', 'Rapid Arena', 'Seven-round rated rapid arena.', 10, 256, now(), now() + interval '7 days', 'OPEN'),
('22000000-0000-0000-0000-000000000002', 'Blitz Sprint', 'Five-round fast pairing tournament.', 5, 128, now() + interval '1 day', now() + interval '8 days', 'OPEN');
