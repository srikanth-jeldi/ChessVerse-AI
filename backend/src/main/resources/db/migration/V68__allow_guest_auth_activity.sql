alter table auth_activity_event
    drop constraint if exists chk_auth_activity_method;

alter table auth_activity_event
    add constraint chk_auth_activity_method
    check (auth_method in ('PASSWORD', 'GOOGLE', 'FACEBOOK', 'GUEST'));
