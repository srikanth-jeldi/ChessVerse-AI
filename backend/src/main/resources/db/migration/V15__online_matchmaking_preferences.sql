alter table online_match
    add column time_control_minutes integer not null default 10,
    add column queue_region varchar(16) not null default 'WORLDWIDE',
    add column queue_country varchar(64) not null default 'Unknown',
    add column queue_rating integer not null default 1200,
    add column rating_range integer not null default 0;

alter table online_match
    add constraint ck_online_match_time_control
        check (time_control_minutes in (3, 5, 10, 15)),
    add constraint ck_online_match_queue_region
        check (queue_region in ('WORLDWIDE', 'COUNTRY')),
    add constraint ck_online_match_rating_range
        check (rating_range between 0 and 800);

create index idx_online_match_preferences
    on online_match(random_queue, status, time_control_minutes, queue_region,
                    queue_country, queue_rating, updated_at);
