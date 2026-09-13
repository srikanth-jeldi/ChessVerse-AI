-- Complete the premium eight-badge Royal Collection. Badges use the existing
-- FRAME slot so purchases and the equipped selection stay account-owned.
insert into cosmetic_item values
('44000000-0000-0000-0000-000000000005','puzzle-hunter','FRAME','Puzzle Hunter','For players who love to solve, one puzzle at a time.','COINS',500,'#55E6D2','#071625','puzzle',50,true),
('44000000-0000-0000-0000-000000000006','opening-sage','FRAME','Opening Sage','Knowledge builds brighter victories.','COINS',650,'#9B7BFF','#071625','opening',60,true),
('44000000-0000-0000-0000-000000000007','blitz-charger','FRAME','Blitz Charger','For players who think fast and move faster.','COINS',800,'#42BFFF','#071625','blitz',70,true),
('44000000-0000-0000-0000-000000000008','checkmate-crown','FRAME','Checkmate Crown','For those who see the end before it begins.','COINS',2000,'#FFD24A','#071625','checkmate',80,true)
on conflict (id) do nothing;
