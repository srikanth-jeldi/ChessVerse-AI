CREATE TABLE online_match (
    id UUID PRIMARY KEY,
    room_code VARCHAR(8) NOT NULL UNIQUE,
    white_player_id UUID NOT NULL REFERENCES player_account(id),
    white_player_name VARCHAR(80) NOT NULL,
    black_player_id UUID REFERENCES player_account(id),
    black_player_name VARCHAR(80),
    status VARCHAR(16) NOT NULL,
    active_color VARCHAR(5) NOT NULL,
    ply_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_online_match_status_created
    ON online_match(status, created_at);
CREATE INDEX idx_online_match_white_player
    ON online_match(white_player_id, updated_at);
CREATE INDEX idx_online_match_black_player
    ON online_match(black_player_id, updated_at);

CREATE TABLE online_move (
    id UUID PRIMARY KEY,
    match_id UUID NOT NULL REFERENCES online_match(id) ON DELETE CASCADE,
    ply INTEGER NOT NULL,
    uci VARCHAR(5) NOT NULL,
    player_id UUID NOT NULL REFERENCES player_account(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uk_online_move_match_ply UNIQUE (match_id, ply)
);

