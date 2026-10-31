-- Preserve the previously free Academy Scout for all existing accounts.
insert into player_cosmetic_inventory(player_id,item_id,acquired_at)
select p.id,i.id,current_timestamp from player_account p cross join cosmetic_item i
where i.slug='academy-scout'
on conflict (player_id,item_id) do nothing;

-- Separate proof of achievement from cosmetic ownership/purchases.
create table player_badge_achievement (
    player_id uuid not null references player_account(id) on delete cascade,
    item_id uuid not null references cosmetic_item(id),
    earned_at timestamp with time zone not null,
    primary key(player_id,item_id)
);

-- Keep existing prices/currencies for old clients; the service enforces earning.
update cosmetic_item set description='Complete your first Academy lesson. Existing ownership is preserved.' where slug='academy-scout';
update cosmetic_item set description='Complete 25 different puzzles.' where slug='puzzle-hunter';
update cosmetic_item set description='Complete 20 different medium or hard puzzles.' where slug='tactical-eye';
update cosmetic_item set description='Complete 5 different opening lessons.' where slug='opening-sage';
update cosmetic_item set description='Complete daily challenges on 7 consecutive days.' where slug='streak-flame';
update cosmetic_item set description='Win 10 online games by checkmate.' where slug='checkmate-crown';
update cosmetic_item set description='A decorative profile badge. This does not certify a chess title or grant coins.' where slug in ('royal-master','blitz-charger');
