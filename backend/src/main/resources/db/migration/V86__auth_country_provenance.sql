-- Historical countries may come from either locale or a request header.
-- Preserve the original value without claiming a source retrospectively.
alter table auth_activity_event
    add column country_source varchar(32) not null default 'LEGACY_UNVERIFIED',
    add column device_region varchar(8);
