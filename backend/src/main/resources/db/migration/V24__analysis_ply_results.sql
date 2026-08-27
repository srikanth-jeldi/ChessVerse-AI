CREATE TABLE game_analysis_ply (
    id UUID PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES game_analysis_job(id) ON DELETE CASCADE,
    ply INTEGER NOT NULL,
    fen_before VARCHAR(120) NOT NULL,
    played_move VARCHAR(5) NOT NULL,
    best_move VARCHAR(5) NOT NULL,
    classification VARCHAR(20) NOT NULL,
    coaching_theme VARCHAR(40) NOT NULL,
    centipawn_loss INTEGER NOT NULL,
    evaluation_before_cp INTEGER NOT NULL,
    evaluation_after_cp INTEGER NOT NULL,
    mate_before INTEGER,
    mate_after INTEGER,
    principal_variation VARCHAR(500) NOT NULL,
    depth INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_analysis_ply_job_ply UNIQUE(job_id, ply)
);
CREATE INDEX idx_analysis_ply_job ON game_analysis_ply(job_id, ply);
