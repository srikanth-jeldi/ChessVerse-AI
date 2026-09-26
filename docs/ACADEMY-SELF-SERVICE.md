# Academy self-service release

Registration uses the existing account API and email verification. A verified account creates one enrollment with billing country, academy name and kind, then supplies billing details. Enrollment alone grants no membership. Plans use INR for India and USD elsewhere. Monthly prices excluding GST: Starter 25 seats INR 999 / USD 19; Growth 100 seats INR 2499 / USD 39; School 300 seats INR 4999 / USD 79.

## Payment and activation

The academy has independent Razorpay configuration, leaving the consumer coin gateway unchanged. Configure `ACADEMY_PAYMENTS_ENABLED`, `ACADEMY_RAZORPAY_KEY_ID`, `ACADEMY_RAZORPAY_KEY_SECRET`, and `ACADEMY_RAZORPAY_WEBHOOK_SECRET` in the protected VPS environment. No secrets belong in Git or the browser. Only live keys can activate production academies. The raw-body-signed `payment.captured` webhook URL is `https://academy.chessverseai.com/api/v1/academy/onboarding/webhook`. Enable capture in the merchant dashboard. International payment support must be enabled by the merchant/provider independently of displaying USD prices.

Orders snapshot server prices, seats, discounts and billing details. The browser must confirm the same total. Signature verification is followed by a provider API lookup checking captured status, payment ID, exact order ID, currency and amount. A transaction with a row lock creates the organization, owner membership and invoice exactly once. Webhook retries and owner-triggered reconciliation recover missed browser callbacks. Pending checkouts are resumed rather than replaced; changing a pending plan/coupon requires support. If order creation times out, no provider order ID is returned to a browser and no activation occurs.

This release uses one-month access and manual renewal after expiry, not automatic subscription debits. Active plans cannot be purchased twice. Expired workspaces require renewal. Existing support-imposed suspensions cannot be bypassed through payment. Refunds, prorated upgrades and automated renewal mandates are not implemented and must be handled through support.

## GST setup remaining before accepting payment

Seller GSTIN: **36AAICE1029L1ZL**. Legal name: **EPITOMEHUB TECHNOLOGIES PRIVATE LIMITED**. Registered address: FLAT-101, MIG-521 BLOCK-A, RK Estates, PHASE-3 KPHB COLONY, Hyderabad, Medchal Malkajgiri, Telangana 500072.

The `academy_billing_config` singleton stores seller identity, SAC, tax rate and an `approved` flag. It is deliberately unapproved, with blank SAC. The 18% rate is a draft only; confirm classification, rate, place-of-supply treatment and invoice requirements with the merchant's accountant before approval. Do not turn on payments until this is complete. Customer billing name, email, address, city, state, postal code and optional GSTIN are collected before checkout. The supplied state code determines the domestic split: Telangana uses CGST/SGST; other domestic states use IGST. Coupon discounts precede tax. Buyers declaring an Indian GSTIN must use a matching Indian state code; this format check is not a GST registration lookup.

International USD checkout is deliberately blocked pending export-of-services/LUT/tax review. A foreign billing country or dollar price alone does not establish zero-rating eligibility. USD catalogs and billing detail collection work; international automatic activation remains a follow-up after that review.

Paid invoices snapshot seller and buyer details and monetary values, with a sequential invoice number, issue date, SAC, service description, taxable value, GST breakup and payment reference. The owner can print/save PDF from Owner billing → Plans, payments & invoices. Existing invoices do not change when billing configuration changes. Invoice signature/e-invoicing applicability and export invoice wording require the accountant's confirmation before merchant tax approval. No actual payment or email was sent during automated or fixture-browser tests.

## Offers

`WELCOME20` is prepared but disabled: 20% off the first month, once per academy, at most 100 reserved/paid checkouts, expiry 2026-12-31. Update dates and enable only when announcing the campaign. Coupon records support plan eligibility, expiry, percentage (1–50%) and total order limit. A pending checkout reserves the coupon use; support must reconcile abandoned payments before changing reservations. Codes never stack. Never edit an existing order amount to apply a later promotion.

## Sources and verification

- [Razorpay checkout integration](https://razorpay.com/docs/server-integration/python/test-app/)
- [CBIC invoice requirements](https://cbic-gst.gov.in/gst-invoice-rules.html)
- [CBIC export-of-services clarification](https://cbic-gst.gov.in/pdf/Circular_78-52-2018_Export_Services.pdf)

Tests cover tenant isolation, registration idempotency, unauthorized invoice access, capture failure, signature rejection, duplicate activation, missed-callback reconciliation, coupons before GST, invoice immutability, interstate/intrastate taxes, unverified accounts and disabled/unapproved billing. Provider verification is mocked in integration tests; a real merchant checkout smoke test remains required before live charges are enabled.

## Public academy information

Clean public routes: `/academy/about`, `/academy/pricing`, `/academy/contact`, `/academy/terms`, `/academy/privacy`, `/academy/refunds`. These pages require no login; the sign-in footer links to them. Pricing reads the same server catalog as onboarding, supports INR/USD display, and reports checkout availability without starting a payment. Seller contact/address/GSTIN are public on Contact.

The refund page currently states that paid checkout is not open and the final refund policy is pending. It describes manual renewal, digital delivery and payment support only; no unapproved refund guarantee or deadline is published. Obtain the merchant's choice of refund terms before payment launch or submitting the site as fully review-ready.
