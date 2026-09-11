-- Account-owned profile badges share the existing FRAME cosmetic slot. This
-- keeps purchases permanent and loadouts synchronized across every device.
insert into cosmetic_item values
('44000000-0000-0000-0000-000000000001','academy-scout','FRAME','Academy Scout','A free badge for every player beginning the learning journey.','FREE',0,'#63D2B8','#071625','shield',10,true),
('44000000-0000-0000-0000-000000000002','tactical-eye','FRAME','Tactical Eye','For players who hunt combinations before they appear.','COINS',500,'#6BE7D1','#071625','tactician',20,true),
('44000000-0000-0000-0000-000000000003','streak-flame','FRAME','Streak Flame','A luminous crest for disciplined daily learners.','COINS',800,'#FFB74D','#071625','streak',30,true),
('44000000-0000-0000-0000-000000000004','royal-master','FRAME','Royal Master','The premium crown badge for a complete chess profile.','COINS',1500,'#F4C75B','#071625','master',40,true)
on conflict (id) do nothing;
