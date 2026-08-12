ALTER TABLE player_cloud_progress
    ADD COLUMN opening_weakness INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN king_safety_weakness INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN hanging_pieces_weakness INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN missed_captures_weakness INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN time_management_weakness INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN endgame_weakness INTEGER NOT NULL DEFAULT 0;
