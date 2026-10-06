-- Update the international monthly catalog only. Existing purchases keep their snapshots.
-- Annual USD pricing and international checkout remain separately configured.
UPDATE academy_plan_price SET name='Starter Academy',seats=25,amount_minor=1900 WHERE plan_code='STARTER' AND currency='USD';
UPDATE academy_plan_price SET name='Growth Academy',seats=60,amount_minor=4900 WHERE plan_code='GROWTH' AND currency='USD';
UPDATE academy_plan_price SET name='Elite Academy',seats=300,amount_minor=11900 WHERE plan_code='SCHOOL' AND currency='USD';
