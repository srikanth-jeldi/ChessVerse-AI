alter table online_match drop constraint if exists online_match_entry_coins_check;
alter table online_match
    add constraint online_match_entry_coins_check
    check (entry_coins in (0, 100, 200, 500));

-- ChessVerseAI play coins are earned-only virtual gameplay points.  Keep the
-- historical purchase ledger for auditability, but expose no purchasable pack.
update purchase_product set active = false, updated_at = current_timestamp;
