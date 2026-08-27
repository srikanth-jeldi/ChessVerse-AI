ALTER TABLE game_analysis_job
    ADD COLUMN player_color VARCHAR(5),
    ADD COLUMN time_control VARCHAR(20);

CREATE TABLE player_weakness_event (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES game_analysis_job(id) ON DELETE CASCADE,
    ply INTEGER NOT NULL,
    category VARCHAR(40) NOT NULL,
    severity INTEGER NOT NULL,
    classification VARCHAR(20) NOT NULL,
    centipawn_loss INTEGER NOT NULL,
    played_move VARCHAR(5) NOT NULL,
    best_move VARCHAR(5) NOT NULL,
    player_color VARCHAR(5),
    time_control VARCHAR(20),
    opening_eco VARCHAR(3),
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_weakness_event_job_ply UNIQUE(job_id, ply)
);
CREATE INDEX idx_weakness_event_player_time
    ON player_weakness_event(player_id, occurred_at DESC);
CREATE INDEX idx_weakness_event_player_category
    ON player_weakness_event(player_id, category);
