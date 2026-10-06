ALTER TABLE academy_enrollment ADD COLUMN trial_started_on DATE;
ALTER TABLE academy_coupon ADD COLUMN fixed_amount_minor BIGINT CHECK (fixed_amount_minor > 0);
ALTER TABLE academy_coupon ADD COLUMN currency VARCHAR(3);
INSERT INTO academy_coupon(code,percent_off,max_orders,expires_on,enabled,fixed_amount_minor,currency)
VALUES('FIRST100',1,2147483647,'9999-12-31',TRUE,10000,'INR');
