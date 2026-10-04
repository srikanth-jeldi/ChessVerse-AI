-- Per-academy student opt-in; no historical personal activity is exposed.
CREATE TABLE academy_activity_sharing (
 organization_id UUID NOT NULL,
 student_id UUID NOT NULL,
 account_id UUID NOT NULL REFERENCES player_account(id),
 enabled BOOLEAN NOT NULL DEFAULT FALSE,
 enabled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (organization_id, student_id),
 FOREIGN KEY (organization_id, student_id) REFERENCES academy_student(organization_id, id)
);
CREATE INDEX idx_academy_game_activity ON computer_game_history(player_id, created_at DESC);
CREATE TABLE player_position_retry (
 id UUID PRIMARY KEY,
 player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
 correct BOOLEAN NOT NULL,
 received_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_player_position_retry ON player_position_retry(player_id, received_at DESC);
