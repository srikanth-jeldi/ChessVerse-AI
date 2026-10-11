-- Closing the browser checkout does not cancel a bank payment. Retain its identifiers for reconciliation.
ALTER TABLE academy_checkout ADD COLUMN dismissed_at TIMESTAMP WITH TIME ZONE;
