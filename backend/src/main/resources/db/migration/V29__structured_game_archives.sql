ALTER TABLE game_analysis_job
    ADD COLUMN source_format VARCHAR(16) NOT NULL DEFAULT 'CHESSVERSE',
    ADD COLUMN source_site VARCHAR(120),
    ADD COLUMN original_pgn TEXT,
    ADD COLUMN pgn_headers_json TEXT,
    ADD COLUMN white_player VARCHAR(120),
    ADD COLUMN black_player VARCHAR(120),
    ADD COLUMN game_result VARCHAR(16),
    ADD COLUMN game_hash VARCHAR(64);

CREATE INDEX idx_analysis_job_player_hash
    ON game_analysis_job(player_id, game_hash)
    WHERE game_hash IS NOT NULL;

ALTER TABLE game_analysis_ply
    ADD COLUMN fen_after VARCHAR(120);

CREATE TABLE saved_chess_position (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    fen VARCHAR(120) NOT NULL,
    fen_hash VARCHAR(64) NOT NULL,
    label VARCHAR(120),
    source_format VARCHAR(16) NOT NULL DEFAULT 'FEN',
    source_job_id UUID REFERENCES game_analysis_job(id) ON DELETE SET NULL,
    source_ply INTEGER,
    tags_json TEXT NOT NULL DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_saved_position_player_hash UNIQUE(player_id, fen_hash)
);

CREATE INDEX idx_saved_position_player_created
    ON saved_chess_position(player_id, created_at DESC);
