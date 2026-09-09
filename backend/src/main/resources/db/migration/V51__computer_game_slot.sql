CREATE TABLE computer_game_slot (
    player_id UUID PRIMARY KEY REFERENCES player_account(id) ON DELETE CASCADE,
    revision BIGINT NOT NULL DEFAULT 0,
    draft TEXT,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE computer_game_history (
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    game_id VARCHAR(80) NOT NULL,
    draft TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (player_id, game_id)
);
