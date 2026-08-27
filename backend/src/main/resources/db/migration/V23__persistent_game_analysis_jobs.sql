CREATE TABLE game_analysis_job (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    client_request_id VARCHAR(64) NOT NULL,
    initial_fen VARCHAR(120) NOT NULL,
    moves_json TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    requested_depth INTEGER NOT NULL,
    total_plies INTEGER NOT NULL,
    analyzed_plies INTEGER NOT NULL DEFAULT 0,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    error_code VARCHAR(64),
    error_message VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);
ALTER TABLE game_analysis_job ADD CONSTRAINT uq_analysis_job_player_request
    UNIQUE(player_id, client_request_id);

CREATE INDEX idx_analysis_job_player_created
    ON game_analysis_job(player_id, created_at DESC);
CREATE INDEX idx_analysis_job_status_updated
    ON game_analysis_job(status, updated_at);
