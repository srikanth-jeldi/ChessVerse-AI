ALTER TABLE academy_invitation ADD COLUMN email_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE academy_invitation ADD COLUMN reminder_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE academy_checkout ADD COLUMN failure_reason VARCHAR(200);
ALTER TABLE academy_checkout ADD COLUMN failed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE academy_checkout ADD COLUMN invoice_emailed_at TIMESTAMP WITH TIME ZONE;

CREATE TABLE academy_audit_event (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 actor_account_id UUID REFERENCES player_account(id),
 event_type VARCHAR(60) NOT NULL,
 target_type VARCHAR(40),
 target_id VARCHAR(100),
 details VARCHAR(1000),
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX academy_audit_org_created ON academy_audit_event(organization_id,created_at);

CREATE TABLE academy_announcement (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 created_by UUID NOT NULL,
 audience VARCHAR(20) NOT NULL CHECK (audience IN ('ALL','COACH','STUDENT','PARENT')),
 title VARCHAR(150) NOT NULL,
 message VARCHAR(2000) NOT NULL,
 expires_at TIMESTAMP WITH TIME ZONE,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,created_by) REFERENCES academy_member(organization_id,id)
);
CREATE INDEX academy_announcement_org_created ON academy_announcement(organization_id,created_at);

CREATE TABLE academy_attendance (
 organization_id UUID NOT NULL,
 student_id UUID NOT NULL,
 class_date DATE NOT NULL,
 status VARCHAR(12) NOT NULL CHECK (status IN ('PRESENT','ABSENT','LATE','EXCUSED')),
 recorded_by UUID NOT NULL,
 note VARCHAR(500),
 updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (organization_id,student_id,class_date),
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id),
 FOREIGN KEY (organization_id,recorded_by) REFERENCES academy_member(organization_id,id)
);

CREATE TABLE academy_notification_preference (
 organization_id UUID NOT NULL,
 member_id UUID NOT NULL,
 announcements BOOLEAN NOT NULL DEFAULT TRUE,
 assignments BOOLEAN NOT NULL DEFAULT TRUE,
 reports BOOLEAN NOT NULL DEFAULT TRUE,
 billing BOOLEAN NOT NULL DEFAULT TRUE,
 email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
 PRIMARY KEY (organization_id,member_id),
 FOREIGN KEY (organization_id,member_id) REFERENCES academy_member(organization_id,id)
);

CREATE TABLE academy_subscription_request (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 requested_by UUID NOT NULL,
 action VARCHAR(12) NOT NULL CHECK (action IN ('UPGRADE','DOWNGRADE','CANCEL')),
 plan_code VARCHAR(20),
 seats INTEGER CHECK (seats IS NULL OR seats > 0),
 effective_on DATE NOT NULL,
 status VARCHAR(12) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','APPLIED')),
 reviewed_by UUID REFERENCES player_account(id),
 reviewed_at TIMESTAMP WITH TIME ZONE,
 processed_at TIMESTAMP WITH TIME ZONE,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,requested_by) REFERENCES academy_member(organization_id,id)
);
CREATE INDEX academy_subscription_org_created ON academy_subscription_request(organization_id,created_at);

CREATE TABLE academy_billing_notice (
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 recipient_account_id UUID NOT NULL REFERENCES player_account(id),
 notice_type VARCHAR(30) NOT NULL,
 renewal_date DATE NOT NULL,
 sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (organization_id,recipient_account_id,notice_type,renewal_date)
);

CREATE TABLE academy_report_schedule (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 created_by UUID NOT NULL,
 student_id UUID,
 period VARCHAR(10) NOT NULL CHECK (period IN ('WEEKLY','MONTHLY')),
 email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
 active BOOLEAN NOT NULL DEFAULT TRUE,
 next_run_on DATE NOT NULL,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,created_by) REFERENCES academy_member(organization_id,id),
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id)
);
