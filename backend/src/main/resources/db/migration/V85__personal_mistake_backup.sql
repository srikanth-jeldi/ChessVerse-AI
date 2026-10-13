CREATE TABLE player_mistake_backup (
    player_id UUID NOT NULL REFERENCES player_account(id) ON DELETE CASCADE,
    mistake_id VARCHAR(100) NOT NULL,
    snapshot TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (player_id, mistake_id)
);
