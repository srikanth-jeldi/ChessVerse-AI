ALTER TABLE academy_plan_price DROP CONSTRAINT IF EXISTS academy_plan_price_currency_check;
ALTER TABLE academy_plan_price ADD CONSTRAINT academy_plan_price_currency_check
  CHECK (currency IN ('INR','USD','EUR','GBP'));

INSERT INTO academy_plan_price(plan_code,name,seats,amount_minor,annual_amount_minor,currency,enabled)
VALUES
 ('STARTER','Starter Academy',25,1799,17999,'EUR',TRUE),
 ('GROWTH','Growth Academy',60,4499,44999,'EUR',TRUE),
 ('SCHOOL','Elite Academy',300,10999,109999,'EUR',TRUE),
 ('STARTER','Starter Academy',25,1499,14999,'GBP',TRUE),
 ('GROWTH','Growth Academy',60,3999,39999,'GBP',TRUE),
 ('SCHOOL','Elite Academy',300,9999,99999,'GBP',TRUE);

UPDATE academy_plan_price SET annual_amount_minor=CASE plan_code
 WHEN 'STARTER' THEN 19000 WHEN 'GROWTH' THEN 49000 WHEN 'SCHOOL' THEN 119000 END
WHERE currency='USD';
