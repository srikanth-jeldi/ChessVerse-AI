-- Preserve existing checkout/invoice snapshots and active academy entitlements.
ALTER TABLE academy_plan_price ADD COLUMN annual_amount_minor BIGINT CHECK (annual_amount_minor > 0);
ALTER TABLE academy_checkout ADD COLUMN billing_months INTEGER NOT NULL DEFAULT 1 CHECK (billing_months IN (1,12));
ALTER TABLE academy_coupon ADD COLUMN first_payment_only BOOLEAN NOT NULL DEFAULT TRUE;
UPDATE academy_plan_price SET name='Starter Academy',seats=25,amount_minor=149900,annual_amount_minor=1499900 WHERE plan_code='STARTER' AND currency='INR';
UPDATE academy_plan_price SET name='Growth Academy',seats=60,amount_minor=399900,annual_amount_minor=3999900 WHERE plan_code='GROWTH' AND currency='INR';
UPDATE academy_plan_price SET name='Elite Academy',seats=300,amount_minor=999900,annual_amount_minor=9999900 WHERE plan_code='SCHOOL' AND currency='INR';
