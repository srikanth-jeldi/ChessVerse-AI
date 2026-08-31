ALTER TABLE chess_tournament
    ADD COLUMN entry_coins INTEGER NOT NULL DEFAULT 100;

ALTER TABLE chess_tournament
    ADD CONSTRAINT chess_tournament_entry_coins_check
    CHECK (entry_coins IN (100, 200, 500));

UPDATE chess_tournament SET entry_coins = CASE
    WHEN name ILIKE '%Grand Final%' OR name ILIKE '%Dubai%' THEN 500
    WHEN name ILIKE '%London%' OR name ILIKE '%Tokyo%' THEN 200
    ELSE 100
END;

ALTER TABLE chess_tournament_entry
    ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN reserved_coins INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN reservation_id UUID,
    ADD COLUMN refunded_at TIMESTAMP WITH TIME ZONE;

-- Legacy registrations never reserved coins. Require those players to opt in
-- again so the displayed pool always equals the server-settled pool.
UPDATE chess_tournament_entry SET active = FALSE
WHERE reservation_id IS NULL;

CREATE INDEX ix_tournament_entry_active
    ON chess_tournament_entry(tournament_id, active, joined_at);
