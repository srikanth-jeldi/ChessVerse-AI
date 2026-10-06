-- Preserve all existing students and paid subscriptions; stop additional trial intake at 15.
UPDATE academy_organization SET seats=15 WHERE plan='Free trial';
