ALTER TABLE practice_cup ADD COLUMN starts_at TIMESTAMP WITH TIME ZONE;
-- Cups created before timed lobbies already have a roster.
UPDATE practice_cup SET starts_at=CURRENT_TIMESTAMP;
ALTER TABLE practice_cup ALTER COLUMN starts_at SET NOT NULL;
ALTER TABLE practice_cup ADD COLUMN finished_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX ix_practice_cup_recent ON practice_cup(finished_at);
