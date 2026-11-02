CREATE TABLE practice_cup_day (day DATE PRIMARY KEY);
CREATE TABLE practice_cup (
    id UUID PRIMARY KEY,
    day DATE NOT NULL REFERENCES practice_cup_day(day)
);
CREATE INDEX ix_practice_cup_day ON practice_cup(day);
CREATE TABLE practice_cup_seat (
    cup_id UUID NOT NULL REFERENCES practice_cup(id),
    seat INTEGER NOT NULL CHECK (seat BETWEEN 0 AND 5),
    player_id UUID REFERENCES player_account(id),
    name VARCHAR(100) NOT NULL,
    PRIMARY KEY (cup_id, seat),
    UNIQUE (cup_id, player_id)
);
CREATE TABLE practice_cup_game (
    cup_id UUID NOT NULL REFERENCES practice_cup(id),
    board_no INTEGER NOT NULL,
    round_no INTEGER NOT NULL,
    white_seat INTEGER NOT NULL,
    black_seat INTEGER NOT NULL,
    moves TEXT NOT NULL DEFAULT '',
    started BOOLEAN NOT NULL DEFAULT FALSE,
    result VARCHAR(7) NOT NULL DEFAULT '*',
    PRIMARY KEY (cup_id, board_no),
    FOREIGN KEY (cup_id, white_seat) REFERENCES practice_cup_seat(cup_id, seat),
    FOREIGN KEY (cup_id, black_seat) REFERENCES practice_cup_seat(cup_id, seat)
);
