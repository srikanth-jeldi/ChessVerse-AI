CREATE TABLE tournament_preview_slot (
  tournament_id UUID NOT NULL REFERENCES chess_tournament(id),
  player_id UUID NOT NULL REFERENCES player_account(id),
  slot INTEGER NOT NULL CHECK (slot >= 0),
  PRIMARY KEY (tournament_id, player_id),
  UNIQUE (tournament_id, slot)
);
