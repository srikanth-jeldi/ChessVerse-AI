-- This stable id originally represented the normal Staunton set, but V57
-- repurposed it as Crimson Crown. Older and newly-created loadouts therefore
-- treated a premium set as the default. Clear that inherited selection once;
-- players can explicitly equip Crimson Crown again from the collection.
update player_cosmetic_loadout
set pieces_item_id = null,
    updated_at = current_timestamp
where pieces_item_id = '42000000-0000-0000-0000-000000000001';
