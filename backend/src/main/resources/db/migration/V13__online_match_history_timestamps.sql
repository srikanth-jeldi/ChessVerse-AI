ALTER TABLE online_match
    ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS finished_at TIMESTAMPTZ;

UPDATE online_match
SET started_at = created_at
WHERE started_at IS NULL
  AND status IN ('ACTIVE', 'FINISHED');

UPDATE online_match
SET finished_at = updated_at
WHERE finished_at IS NULL
  AND status = 'FINISHED';

CREATE INDEX IF NOT EXISTS idx_online_match_finished_at
    ON online_match (finished_at DESC)
    WHERE status = 'FINISHED';
