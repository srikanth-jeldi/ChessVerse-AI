-- ChessVerseAI uses one earned-only virtual currency. Existing diamond-priced
-- cosmetics are converted to coins so every displayed item has an attainable
-- in-game earning path.
update cosmetic_catalog
set price_currency = 'COINS',
    price_amount = case slug
        when 'neon-arena' then 1500
        when 'golden-crown' then 2000
        else price_amount
    end
where price_currency = 'DIAMONDS';
