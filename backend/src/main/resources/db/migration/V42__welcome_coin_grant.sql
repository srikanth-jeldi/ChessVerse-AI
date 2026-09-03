-- One-time, auditable launch grant for every account that already exists.
insert into player_wallet(player_id, coin_balance, diamond_balance, created_at, updated_at)
select id, 0, 10, current_timestamp, current_timestamp
from player_account
on conflict (player_id) do nothing;

update player_wallet
set coin_balance = coin_balance + 700,
    updated_at = current_timestamp
where player_id in (select id from player_account);

insert into economy_transaction(
    id, player_id, currency, amount, balance_after,
    transaction_type, reference_key, description, created_at)
select gen_random_uuid(), wallet.player_id, 'COINS', 700, wallet.coin_balance,
       'WELCOME', 'WELCOME_700_2026', 'ChessVerseAI launch welcome coins', current_timestamp
from player_wallet wallet
join player_account player on player.id = wallet.player_id;
