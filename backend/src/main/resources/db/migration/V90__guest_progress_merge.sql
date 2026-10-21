-- A guest archive can be claimed by one authenticated account only.
-- Deliberately independent of wallets, reward ledgers and streak awards.
create table guest_progress_merge (
    guest_id uuid primary key references player_account(id) on delete cascade,
    target_id uuid not null references player_account(id) on delete cascade,
    merged_at timestamp with time zone not null default current_timestamp
);
