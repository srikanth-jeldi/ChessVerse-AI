alter table auth_activity_event
    add column device_name varchar(160),
    add column client_platform varchar(120),
    add column country_code varchar(8),
    add column new_device boolean not null default false;

