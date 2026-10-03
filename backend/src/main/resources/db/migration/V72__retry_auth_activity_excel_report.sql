-- The first Excel digest was accepted by SMTP but was not visible in the
-- recipient mailbox. Re-queue the retained rows once for the new daily digest.
update auth_activity_event
set excel_reported_at = null
where excel_reported_at is not null;
