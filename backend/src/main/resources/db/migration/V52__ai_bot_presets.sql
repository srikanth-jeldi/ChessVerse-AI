CREATE TABLE ai_bot_presets (
    id UUID PRIMARY KEY,
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    name VARCHAR(30) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 400 AND 3000),
    style VARCHAR(12) NOT NULL CHECK (style IN ('balanced', 'aggressive', 'defensive')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (player_id, name)
);

CREATE INDEX idx_ai_bot_presets_player ON ai_bot_presets(player_id, updated_at DESC);
