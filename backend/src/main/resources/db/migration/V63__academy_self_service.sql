-- Regional monthly catalog; checkout additionally requires gateway and tax approval.
CREATE TABLE academy_plan_price (
 plan_code VARCHAR(20) NOT NULL, currency VARCHAR(3) NOT NULL CHECK(currency IN ('INR','USD')),
 name VARCHAR(60) NOT NULL, seats INTEGER CHECK(seats > 0), amount_minor BIGINT CHECK(amount_minor > 0),
 enabled BOOLEAN NOT NULL DEFAULT FALSE, PRIMARY KEY(plan_code,currency)
);
INSERT INTO academy_plan_price(plan_code,currency,name) VALUES
 ('STARTER','INR','Starter'),('GROWTH','INR','Growth'),('SCHOOL','INR','School'),
 ('STARTER','USD','Starter'),('GROWTH','USD','Growth'),('SCHOOL','USD','School');
-- Launch prices exclude GST. No payment can start until seller tax setup is approved.
UPDATE academy_plan_price SET seats=25,amount_minor=99900 WHERE plan_code='STARTER' AND currency='INR';
UPDATE academy_plan_price SET seats=100,amount_minor=249900 WHERE plan_code='GROWTH' AND currency='INR';
UPDATE academy_plan_price SET seats=300,amount_minor=499900 WHERE plan_code='SCHOOL' AND currency='INR';
UPDATE academy_plan_price SET seats=25,amount_minor=1900 WHERE plan_code='STARTER' AND currency='USD';
UPDATE academy_plan_price SET seats=100,amount_minor=3900 WHERE plan_code='GROWTH' AND currency='USD';
UPDATE academy_plan_price SET seats=300,amount_minor=7900 WHERE plan_code='SCHOOL' AND currency='USD';
-- Catalog is visible; payment gateway and approved tax configuration gate charging separately.
UPDATE academy_plan_price SET enabled=TRUE;
CREATE TABLE academy_enrollment (
 id UUID PRIMARY KEY, account_id UUID NOT NULL UNIQUE REFERENCES player_account(id),
 name VARCHAR(100) NOT NULL, kind VARCHAR(12) NOT NULL CHECK(kind IN ('ACADEMY','SCHOOL')),
 country VARCHAR(2) NOT NULL, organization_id UUID UNIQUE REFERENCES academy_organization(id),
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE academy_checkout (
 id UUID PRIMARY KEY, enrollment_id UUID NOT NULL REFERENCES academy_enrollment(id),
 provider_order VARCHAR(100) NOT NULL UNIQUE, payment_id VARCHAR(100) UNIQUE,
 plan_code VARCHAR(20) NOT NULL, plan_name VARCHAR(60) NOT NULL, seats INTEGER NOT NULL CHECK(seats > 0),
 amount_minor BIGINT NOT NULL CHECK(amount_minor > 0), currency VARCHAR(3) NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','PAID')),
 created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, paid_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX academy_checkout_enrollment ON academy_checkout(enrollment_id,created_at);
CREATE TABLE academy_coupon (
 code VARCHAR(30) PRIMARY KEY, percent_off INTEGER NOT NULL CHECK(percent_off BETWEEN 1 AND 50),
 plan_code VARCHAR(20), max_orders INTEGER NOT NULL CHECK(max_orders > 0),
 expires_on DATE NOT NULL, enabled BOOLEAN NOT NULL DEFAULT FALSE
);
-- A prepared launch campaign; enable only when announcing the offer.
INSERT INTO academy_coupon(code,percent_off,max_orders,expires_on,enabled) VALUES('WELCOME20',20,100,'2026-12-31',FALSE);
ALTER TABLE academy_checkout ADD COLUMN coupon_code VARCHAR(30) REFERENCES academy_coupon(code);
ALTER TABLE academy_checkout ADD COLUMN subtotal_minor BIGINT;
ALTER TABLE academy_checkout ADD COLUMN discount_minor BIGINT NOT NULL DEFAULT 0;
ALTER TABLE academy_enrollment ADD COLUMN billing_details TEXT;
ALTER TABLE academy_checkout ADD COLUMN billing_snapshot TEXT;
ALTER TABLE academy_checkout ADD COLUMN tax_minor BIGINT NOT NULL DEFAULT 0;
CREATE TABLE academy_billing_config (
 id INTEGER PRIMARY KEY CHECK(id=1), legal_name VARCHAR(150) NOT NULL DEFAULT '',
 address VARCHAR(1000) NOT NULL DEFAULT '', gstin VARCHAR(15) NOT NULL,
 sac VARCHAR(10) NOT NULL DEFAULT '', india_rate_bps INTEGER NOT NULL DEFAULT 1800 CHECK(india_rate_bps BETWEEN 0 AND 2800),
 approved BOOLEAN NOT NULL DEFAULT FALSE
);
INSERT INTO academy_billing_config(id,gstin) VALUES(1,'36AAICE1029L1ZL');
UPDATE academy_billing_config SET legal_name='EPITOMEHUB TECHNOLOGIES PRIVATE LIMITED',address='FLAT-101, MIG-521 BLOCK-A, RK Estates, PHASE-3 KPHB COLONY, Hyderabad, Medchal Malkajgiri, Telangana 500072' WHERE id=1;
CREATE TABLE academy_invoice_counter(id INTEGER PRIMARY KEY CHECK(id=1),next_number BIGINT NOT NULL);
INSERT INTO academy_invoice_counter VALUES(1,1);
CREATE TABLE academy_invoice_document (
 invoice_id UUID PRIMARY KEY REFERENCES academy_invoice(id), invoice_number VARCHAR(16) NOT NULL UNIQUE,
 snapshot TEXT NOT NULL
);
