CREATE TABLE ai_coach_response_cache (
    cache_key VARCHAR(64) PRIMARY KEY,
    answer TEXT NOT NULL,
    engine_evidence TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE ai_coach_interaction (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    cache_key VARCHAR(64) NOT NULL,
    question VARCHAR(500) NOT NULL,
    candidate_move VARCHAR(5),
    cache_hit BOOLEAN NOT NULL,
    helpful BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_ai_coach_interaction_player_time
    ON ai_coach_interaction(player_id, created_at DESC);
CREATE INDEX idx_ai_coach_interaction_cache_key
    ON ai_coach_interaction(cache_key);
