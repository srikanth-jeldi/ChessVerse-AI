ALTER TABLE game_analysis_job
    ADD COLUMN opening_eco VARCHAR(3),
    ADD COLUMN opening_name VARCHAR(200),
    ADD COLUMN book_plies INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN first_deviation_ply INTEGER;
