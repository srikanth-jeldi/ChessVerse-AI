create table club_email_invitation (
    id uuid primary key,
    club_id uuid not null references chess_club(id) on delete cascade,
    sender_id uuid not null references player_account(id) on delete cascade,
    recipient_email varchar(254) not null,
    status varchar(16) not null default 'PENDING',
    created_at timestamptz not null,
    expires_at timestamptz not null,
    responded_by uuid references player_account(id) on delete set null,
    responded_at timestamptz,
    sent_at timestamptz,
    mail_attempts integer not null default 0,
    last_mail_attempt_at timestamptz,
    constraint club_invitation_status check (status in ('PENDING','ACCEPTED','DECLINED','EXPIRED'))
);
create unique index uq_pending_club_email on club_email_invitation(club_id,recipient_email) where status='PENDING';
create index ix_club_invite_recipient on club_email_invitation(recipient_email,status);
create index ix_club_invite_sender on club_email_invitation(sender_id,created_at);
