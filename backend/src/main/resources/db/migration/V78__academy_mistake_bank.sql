ALTER TABLE academy_activity_sharing ADD COLUMN mistake_bank_enabled BOOLEAN NOT NULL DEFAULT FALSE;
CREATE TABLE academy_mistake_bank (
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 student_id UUID NOT NULL REFERENCES academy_student(id),
 mistake_id VARCHAR(100) NOT NULL,
 account_id UUID NOT NULL,
 snapshot TEXT NOT NULL,
 updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(organization_id,student_id,mistake_id)
);
