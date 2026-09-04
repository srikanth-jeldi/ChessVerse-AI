-- V45 deliberately avoided changing dates on tournaments that had already
-- started, but that also left the completed Hyderabad and Tokyo records
-- without series metadata. The scheduler needs this metadata to create their
-- next recurring occurrence.
update chess_tournament
set series_code='HYDERABAD_ROYAL',
    occurrence_number=1,
    cadence_days=7,
    minimum_players=4,
    badge_code='HYDERABAD_ROYAL_CREST',
    entry_coins=100,
    champion_bonus=500,
    runner_up_bonus=250,
    participation_bonus=25
where id='22000000-0000-0000-0000-000000000001'
  and series_code is null;

update chess_tournament
set series_code='TOKYO_NEON',
    occurrence_number=1,
    cadence_days=14,
    minimum_players=4,
    badge_code='TOKYO_NEON_SHOGUN',
    entry_coins=250,
    champion_bonus=1200,
    runner_up_bonus=600,
    participation_bonus=50
where id='22000000-0000-0000-0000-000000000002'
  and series_code is null;
