CREATE TABLE academy_invitation (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL REFERENCES academy_organization(id),
 email VARCHAR(254) NOT NULL,
 role VARCHAR(24) NOT NULL CHECK (role IN ('COACH','STUDENT','PARENT')),
 token_hash VARCHAR(64) NOT NULL UNIQUE,
 status VARCHAR(12) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACCEPTED','REVOKED','EXPIRED')),
 invited_by UUID NOT NULL,
 accepted_by UUID,
 expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 accepted_at TIMESTAMP WITH TIME ZONE,
 FOREIGN KEY (organization_id,invited_by) REFERENCES academy_member(organization_id,id),
 FOREIGN KEY (accepted_by) REFERENCES player_account(id)
);
CREATE INDEX academy_invitation_org ON academy_invitation(organization_id,created_at);
CREATE INDEX academy_invitation_email ON academy_invitation(email,status);
