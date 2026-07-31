alter table online_match
    add column white_time_ms bigint not null default 600000,
    add column black_time_ms bigint not null default 600000,
    add column turn_started_at timestamp with time zone,
    add column result varchar(16),
    add column result_reason varchar(32),
    add column draw_offered_by uuid,
    add column rematch_requested_by uuid,
    add column rematch_match_id uuid;

create index idx_online_match_history
    on online_match(updated_at desc, white_player_id, black_player_id);
