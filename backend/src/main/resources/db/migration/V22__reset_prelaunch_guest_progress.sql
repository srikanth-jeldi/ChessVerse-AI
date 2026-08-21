-- Pre-launch cleanup: early mobile builds uploaded device-global demo/test
-- progress into guest accounts. Registered-player progress is untouched.
delete from player_completed_academy_lesson
where player_id in (select id from player_account where guest_account = true);

delete from player_completed_puzzle
where player_id in (select id from player_account where guest_account = true);

delete from player_completed_daily_challenge
where player_id in (select id from player_account where guest_account = true);

delete from player_cloud_progress
where player_id in (select id from player_account where guest_account = true);
