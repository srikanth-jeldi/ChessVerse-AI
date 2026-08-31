-- Launch the first ChessVerseAI World Circuit using the existing tournament engine.
update chess_tournament
set name = 'Hyderabad Royal Cup',
    description = 'Seven-round rated rapid beneath the lights of the royal city.',
    time_control_minutes = 10,
    capacity = 128
where id = '22000000-0000-0000-0000-000000000001';

update chess_tournament
set name = 'Tokyo Neon Masters',
    description = 'Fast knockout chess in the electric neon arena.',
    time_control_minutes = 5,
    capacity = 128
where id = '22000000-0000-0000-0000-000000000002';

insert into chess_tournament(id,name,description,time_control_minutes,capacity,starts_at,ends_at,status)
values
('22000000-0000-0000-0000-000000000003','Dubai Gold Open','Precision rapid chess in a spectacular golden arena.',10,128,now()+interval '3 days',now()+interval '4 days','OPEN'),
('22000000-0000-0000-0000-000000000004','London Classic','Traditional tournament chess with a modern competitive edge.',15,128,now()+interval '6 days',now()+interval '7 days','OPEN'),
('22000000-0000-0000-0000-000000000005','New York Grand Final','The season finale where qualified circuit players chase the crown.',10,64,now()+interval '9 days',now()+interval '10 days','OPEN')
on conflict (id) do nothing;
