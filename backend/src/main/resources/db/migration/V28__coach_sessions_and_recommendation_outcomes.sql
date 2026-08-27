ALTER TABLE ai_coach_interaction
    ADD COLUMN session_id UUID,
    ADD COLUMN answer TEXT,
    ADD COLUMN classification VARCHAR(20),
    ADD COLUMN best_move VARCHAR(5),
    ADD COLUMN centipawn_loss INTEGER,
    ADD COLUMN opponent_threat VARCHAR(5),
    ADD COLUMN principal_variation TEXT;

CREATE INDEX idx_ai_coach_interaction_session
    ON ai_coach_interaction(player_id, session_id, created_at);

CREATE TABLE ai_recommendation_outcome (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    interaction_id UUID NOT NULL REFERENCES ai_coach_interaction(id) ON DELETE CASCADE,
    recommendation_type VARCHAR(40) NOT NULL,
    opening_eco VARCHAR(3),
    player_color VARCHAR(5),
    time_control VARCHAR(20),
    accepted BOOLEAN NOT NULL,
    baseline_centipawn_loss INTEGER NOT NULL,
    followup_centipawn_loss INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_ai_recommendation_interaction UNIQUE(interaction_id)
);

CREATE INDEX idx_ai_recommendation_player_time
    ON ai_recommendation_outcome(player_id, created_at DESC);

CREATE TABLE ai_coach_daily_usage (
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL,
    used_count INTEGER NOT NULL CHECK (used_count >= 0),
    PRIMARY KEY (player_id, usage_date)
);
