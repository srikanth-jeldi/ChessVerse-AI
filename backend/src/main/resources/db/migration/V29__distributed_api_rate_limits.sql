create table api_rate_limit_bucket (
    bucket_key varchar(160) not null,
    window_start bigint not null,
    request_count integer not null,
    expires_at timestamp with time zone not null,
    primary key (bucket_key, window_start)
);

create index ix_api_rate_limit_bucket_expiry on api_rate_limit_bucket(expires_at);
