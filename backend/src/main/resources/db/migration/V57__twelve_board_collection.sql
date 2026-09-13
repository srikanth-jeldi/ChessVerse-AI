-- Expand Royal Collection to twelve account-owned board loadouts. Existing ids
-- retain purchases; new ids extend the catalogue with earned-coin cosmetics.
update cosmetic_item set slug='frost-marble', name='Frost Marble', description='Quiet precision carved from winter stone.', price_currency='COINS', price_amount=1100, primary_color='#EEF3F8', secondary_color='#56616F', sort_order=70 where id='41000000-0000-0000-0000-000000000007';
update cosmetic_item set slug='jade-dynasty', name='Jade Dynasty', description='Imperial jade made for patient strategists.', price_currency='COINS', price_amount=1700, primary_color='#DDE8CF', secondary_color='#176844', sort_order=80 where id='41000000-0000-0000-0000-000000000008';
update cosmetic_item set slug='azure-temple', name='Azure Temple', description='Calm skies and flawless calculation.', price_currency='COINS', price_amount=1900, primary_color='#CFDFEE', secondary_color='#296990', sort_order=90 where id='41000000-0000-0000-0000-000000000009';

insert into cosmetic_item values
('41000000-0000-0000-0000-000000000010','volcanic-obsidian','BOARD','Volcanic Obsidian','Every move carries the fire beneath.','COINS',2300,'#D7C2AA','#5B1714','volcanic-obsidian',100,true),
('41000000-0000-0000-0000-000000000011','rose-quartz','BOARD','Rose Quartz','Grace, focus and a fearless finish.','COINS',1400,'#F5D6DC','#A84D6A','rose-quartz',110,true),
('41000000-0000-0000-0000-000000000012','celestial-silver','BOARD','Celestial Silver','A grand arena written in the stars.','COINS',2600,'#EEF2F7','#263B62','celestial-silver',120,true)
on conflict (id) do nothing;
