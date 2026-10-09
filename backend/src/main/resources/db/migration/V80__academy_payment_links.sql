-- Provider identifiers remain unique; USD checkouts store a plink_ id instead of an order_ id.
ALTER TABLE academy_checkout ADD COLUMN payment_link_url VARCHAR(500);
