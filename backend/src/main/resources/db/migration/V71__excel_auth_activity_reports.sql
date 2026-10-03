alter table auth_activity_event
    add column app_version varchar(40),
    add column installation_fingerprint varchar(32),
    add column excel_reported_at timestamp with time zone;

-- Existing rows intentionally remain pending so the first XLSX delivery
-- contains the historical login/register activity still retained in the DB.
create index idx_auth_activity_excel_unreported
    on auth_activity_event(created_at)
    where excel_reported_at is null;
