alter table online_match
    add column queue_connection_quality varchar(16) not null default 'STANDARD';

alter table online_match
    add constraint ck_online_match_connection_quality
    check (queue_connection_quality in ('EXCELLENT', 'STANDARD', 'LIMITED'));

create index ix_online_match_connection_quality
    on online_match(random_queue, status, queue_connection_quality, updated_at);
