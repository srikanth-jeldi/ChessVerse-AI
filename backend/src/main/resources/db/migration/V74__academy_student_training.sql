CREATE TABLE player_puzzle_completion (
 player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
 puzzle_id VARCHAR(64) NOT NULL,
 received_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(player_id,puzzle_id)
);
CREATE INDEX idx_player_puzzle_completion_time ON player_puzzle_completion(player_id,received_at DESC);
ALTER TABLE academy_assignment ADD COLUMN puzzle_id VARCHAR(64);
ALTER TABLE academy_assignment ADD COLUMN position_fen VARCHAR(120);
ALTER TABLE academy_assignment ADD COLUMN best_move VARCHAR(5);
ALTER TABLE academy_assignment ADD CONSTRAINT uq_academy_assignment_org UNIQUE(organization_id,id);
CREATE TABLE academy_assignment_result (
 id UUID PRIMARY KEY,
 organization_id UUID NOT NULL,
 assignment_id UUID NOT NULL,
 student_id UUID NOT NULL,
 attempts INTEGER NOT NULL CHECK(attempts BETWEEN 1 AND 1000),
 solved BOOLEAN NOT NULL,
 notes VARCHAR(2000) NOT NULL DEFAULT '',
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(organization_id,assignment_id) REFERENCES academy_assignment(organization_id,id),
 FOREIGN KEY(organization_id,student_id) REFERENCES academy_student(organization_id,id)
);
CREATE INDEX idx_academy_assignment_result ON academy_assignment_result(organization_id,student_id,created_at);
