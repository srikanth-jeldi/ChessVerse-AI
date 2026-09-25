-- B2B data is opt-in. Consumer history is never implicitly assigned to a tenant.
CREATE TABLE academy_organization (
 id UUID PRIMARY KEY, name VARCHAR(100) NOT NULL, kind VARCHAR(12) NOT NULL CHECK (kind IN ('ACADEMY','SCHOOL')),
 color VARCHAR(7) NOT NULL DEFAULT '#5754ff', logo_url VARCHAR(500) NOT NULL DEFAULT '',
 white_label BOOLEAN NOT NULL DEFAULT FALSE, plan VARCHAR(60) NOT NULL DEFAULT 'Starter',
 seats INTEGER NOT NULL DEFAULT 25 CHECK (seats > 0), renewal_date DATE,
 status VARCHAR(20) NOT NULL DEFAULT 'TRIAL' CHECK (status IN ('TRIAL','ACTIVE','SUSPENDED')),
 feature_flags VARCHAR(1000) NOT NULL DEFAULT '', created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE academy_super_admin (
 account_id UUID PRIMARY KEY REFERENCES player_account(id), created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE academy_member (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 account_id UUID NOT NULL REFERENCES player_account(id), name VARCHAR(100) NOT NULL,
 role VARCHAR(24) NOT NULL CHECK (role IN ('ORGANIZATION_ADMIN','COACH','STUDENT','PARENT')),
 active BOOLEAN NOT NULL DEFAULT TRUE, UNIQUE (organization_id,account_id), UNIQUE (organization_id,id)
);
CREATE TABLE academy_batch (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 name VARCHAR(100) NOT NULL, level VARCHAR(20) NOT NULL CHECK (level IN ('BEGINNER','INTERMEDIATE','ADVANCED')),
 schedule VARCHAR(200) NOT NULL, coach_id UUID, UNIQUE (organization_id,id),
 FOREIGN KEY (organization_id,coach_id) REFERENCES academy_member(organization_id,id)
);
CREATE TABLE academy_student (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 name VARCHAR(100) NOT NULL, email VARCHAR(254) NOT NULL, account_id UUID REFERENCES player_account(id),
 batch_id UUID, coach_id UUID, active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE (organization_id,id), UNIQUE (organization_id,email), UNIQUE (organization_id,account_id),
 FOREIGN KEY (organization_id,batch_id) REFERENCES academy_batch(organization_id,id),
 FOREIGN KEY (organization_id,coach_id) REFERENCES academy_member(organization_id,id)
);
CREATE TABLE academy_parent_link (
 organization_id UUID NOT NULL, member_id UUID NOT NULL, student_id UUID NOT NULL,
 PRIMARY KEY (organization_id,member_id,student_id),
 FOREIGN KEY (organization_id,member_id) REFERENCES academy_member(organization_id,id),
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id)
);
CREATE TABLE academy_assignment (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL, student_id UUID NOT NULL, created_by UUID NOT NULL,
 title VARCHAR(150) NOT NULL, kind VARCHAR(20) NOT NULL CHECK (kind IN ('PUZZLES','POSITIONS','OPENINGS','MASTER_GAMES')),
 instructions VARCHAR(2000) NOT NULL, due_date DATE NOT NULL, completed_at TIMESTAMP WITH TIME ZONE,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id),
 FOREIGN KEY (organization_id,created_by) REFERENCES academy_member(organization_id,id)
);
CREATE TABLE academy_observation (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL, student_id UUID NOT NULL, recorded_by UUID NOT NULL,
 practiced_on DATE NOT NULL, rating INTEGER NOT NULL CHECK (rating BETWEEN 0 AND 4000),
 accuracy INTEGER NOT NULL CHECK (accuracy BETWEEN 0 AND 100), minutes INTEGER NOT NULL CHECK (minutes BETWEEN 1 AND 1440),
 tactics INTEGER NOT NULL CHECK (tactics BETWEEN 0 AND 10000), blunders INTEGER NOT NULL CHECK (blunders BETWEEN 0 AND 1000),
 opening_errors INTEGER NOT NULL CHECK (opening_errors BETWEEN 0 AND 1000), middle_errors INTEGER NOT NULL CHECK (middle_errors BETWEEN 0 AND 1000),
 endgame_errors INTEGER NOT NULL CHECK (endgame_errors BETWEEN 0 AND 1000), retry_attempts INTEGER NOT NULL CHECK (retry_attempts BETWEEN 0 AND 1000),
 retry_failures INTEGER NOT NULL CHECK (retry_failures >= 0 AND retry_failures <= retry_attempts),
 notes VARCHAR(2000) NOT NULL, created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id),
 FOREIGN KEY (organization_id,recorded_by) REFERENCES academy_member(organization_id,id)
);
CREATE TABLE academy_game (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL, student_id UUID NOT NULL, game_id VARCHAR(80) NOT NULL,
 draft TEXT NOT NULL, created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE (organization_id,student_id,game_id),
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id)
);
CREATE TABLE academy_report (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL, student_id UUID NOT NULL, created_by UUID NOT NULL,
 period VARCHAR(10) NOT NULL CHECK (period IN ('WEEKLY','MONTHLY')), summary TEXT NOT NULL,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (organization_id,student_id) REFERENCES academy_student(organization_id,id),
 FOREIGN KEY (organization_id,created_by) REFERENCES academy_member(organization_id,id)
);
CREATE TABLE academy_seat_request (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 seats INTEGER NOT NULL CHECK (seats BETWEEN 1 AND 10000), status VARCHAR(12) NOT NULL DEFAULT 'PENDING',
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE academy_invoice (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 label VARCHAR(100) NOT NULL, amount_minor BIGINT NOT NULL CHECK (amount_minor >= 0), currency VARCHAR(3) NOT NULL,
 status VARCHAR(20) NOT NULL, issued_on DATE NOT NULL
);
CREATE TABLE academy_support (
 id UUID PRIMARY KEY, organization_id UUID NOT NULL REFERENCES academy_organization(id),
 subject VARCHAR(200) NOT NULL, status VARCHAR(12) NOT NULL DEFAULT 'OPEN',
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX academy_students_coach ON academy_student(organization_id,coach_id);
CREATE INDEX academy_observations_student ON academy_observation(organization_id,student_id,practiced_on);
CREATE INDEX academy_games_student ON academy_game(organization_id,student_id);
CREATE INDEX academy_assignments_student ON academy_assignment(organization_id,student_id);
CREATE INDEX academy_reports_student ON academy_report(organization_id,student_id);
CREATE TABLE academy_guidance_usage (
 organization_id UUID NOT NULL, member_id UUID NOT NULL, usage_date DATE NOT NULL, used_count INTEGER NOT NULL,
 PRIMARY KEY (organization_id,member_id,usage_date),
 FOREIGN KEY (organization_id,member_id) REFERENCES academy_member(organization_id,id)
);
