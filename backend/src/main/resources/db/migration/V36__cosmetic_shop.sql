create table cosmetic_item (
    id uuid primary key,
    slug varchar(80) not null unique,
    category varchar(24) not null check (category in ('BOARD','PIECES','EFFECT','FRAME')),
    name varchar(80) not null,
    description varchar(200) not null,
    price_currency varchar(16) not null check (price_currency in ('FREE','COINS','DIAMONDS')),
    price_amount bigint not null check (price_amount >= 0),
    primary_color varchar(9),
    secondary_color varchar(9),
    asset_key varchar(120),
    sort_order integer not null default 0,
    active boolean not null default true
);

create table player_cosmetic_inventory (
    player_id uuid not null references player_account(id) on delete cascade,
    item_id uuid not null references cosmetic_item(id),
    acquired_at timestamp with time zone not null,
    primary key(player_id,item_id)
);

create table player_cosmetic_loadout (
    player_id uuid primary key references player_account(id) on delete cascade,
    board_item_id uuid references cosmetic_item(id),
    pieces_item_id uuid references cosmetic_item(id),
    effect_item_id uuid references cosmetic_item(id),
    frame_item_id uuid references cosmetic_item(id),
    updated_at timestamp with time zone not null
);

insert into cosmetic_item values
('41000000-0000-0000-0000-000000000001','royal-walnut','BOARD','Royal Walnut','Classic tournament walnut with warm ivory squares.','FREE',0,'#E7D6B0','#6E4128',null,10,true),
('41000000-0000-0000-0000-000000000002','ocean-teal','BOARD','Ocean Teal','Deep ocean squares with crisp aqua highlights.','COINS',600,'#B8E3DF','#176B70',null,20,true),
('41000000-0000-0000-0000-000000000003','midnight-sapphire','BOARD','Midnight Sapphire','Premium navy board with luminous sapphire contrast.','COINS',900,'#AFC8E8','#183B66',null,30,true),
('41000000-0000-0000-0000-000000000004','royal-emerald','BOARD','Royal Emerald','Regal green tournament board with polished cream squares.','COINS',1200,'#E9E2C5','#226B4B',null,40,true),
('41000000-0000-0000-0000-000000000005','neon-arena','BOARD','Neon Arena','Animated-ready cyber board reserved for premium players.','DIAMONDS',180,'#65F4E5','#5B32B4',null,50,true),
('42000000-0000-0000-0000-000000000001','classic-staunton','PIECES','Classic Staunton','Clean competitive pieces designed for maximum clarity.','FREE',0,'#F4E5C1','#20242D','staunton',10,true),
('42000000-0000-0000-0000-000000000002','ivory-obsidian','PIECES','Ivory & Obsidian','Polished high-contrast pieces for dark arenas.','COINS',800,'#FFF4D6','#111827','staunton',20,true),
('42000000-0000-0000-0000-000000000003','golden-crown','PIECES','Golden Crown 3D','Royal metallic piece set with premium highlights.','DIAMONDS',250,'#F5C451','#111827','staunton-gold',30,true);
