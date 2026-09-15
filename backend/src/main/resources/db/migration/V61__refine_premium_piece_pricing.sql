-- Put the Royal 3D collection in a clear entry-to-legendary coin ladder.
-- Stable ids/slugs preserve every existing purchase and equipped loadout.
update cosmetic_item set
  name='Crimson Crown Starter',
  description='Your complimentary Royal 3D set. Full white and black armies included.',
  price_currency='FREE', price_amount=0, sort_order=10
where slug='crimson-crown-3d';

update cosmetic_item set
  name='Obsidian Regal',
  description='Premium silver and obsidian pieces with maximum board contrast.',
  price_currency='COINS', price_amount=900, sort_order=20
where slug='obsidian-regal';

update cosmetic_item set
  name='Emerald Sovereign',
  description='Premium ivory and emerald pieces for a distinctive royal board.',
  price_currency='COINS', price_amount=1200, sort_order=30
where slug='emerald-sovereign';

update cosmetic_item set
  name='Inferno Gold',
  description='Premium ivory and molten-gold pieces with a radiant finish.',
  price_currency='COINS', price_amount=1500, sort_order=40
where slug='inferno-gold';

update cosmetic_item set
  name='Sapphire Elite',
  description='Elite ivory and sapphire pieces tuned for clarity and prestige.',
  price_currency='COINS', price_amount=1800, sort_order=50
where slug='sapphire-elite';

update cosmetic_item set
  name='Ruby Emperor',
  description='Legendary ivory and ruby pieces—the crown jewel of the collection.',
  price_currency='COINS', price_amount=2200, sort_order=60
where slug='ruby-emperor';
