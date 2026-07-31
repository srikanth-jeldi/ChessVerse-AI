ALTER TABLE online_match
    ADD COLUMN white_disconnected_at TIMESTAMPTZ,
    ADD COLUMN black_disconnected_at TIMESTAMPTZ;

CREATE INDEX idx_online_match_disconnect_expiry
    ON online_match (status, white_disconnected_at, black_disconnected_at);
