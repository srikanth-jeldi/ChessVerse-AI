# ChessVerseAI direct coin purchase launch checklist

ChessVerseAI sells coin packs directly. It does not hold a money balance and
does not collect or store card numbers, CVV, UPI PINs, OTPs, or bank details.
Those inputs stay inside Google Play, Apple, or Razorpay checkout.

## Implemented and locally verified

- Server-priced, idempotent purchase orders and immutable history.
- Google Play app checkout with server receipt verification and post-credit
  consumable completion.
- Razorpay test-mode order creation, hosted checkout, constant-time signature
  verification, server-side captured-payment verification, signed raw-body
  webhooks, replay protection, refund reversal, and missed-webhook
  reconciliation.
- Refund debt handling prevents users from retaining already-spent refunded
  coins; future coin grants settle that debt first.
- Provider secrets are server-only and all providers fail closed when disabled
  or unconfigured.

## Google Play — activate after merchant verification

1. Finish BillDesk/Google merchant verification.
2. Create the one-time product `coins_500` and set its final customer price.
3. Grant the mounted service account Google Play order/purchase verification
   access for `com.epitomehub.chessverse`.
4. Set `GOOGLE_PLAY_BILLING_ENABLED=true` on the VPS and keep the service
   account JSON in the existing read-only secret mount.
5. Upload a new AAB with a new version code to an internal testing track.
6. Test success, cancellation, pending payment, duplicate callback, app restart,
   refund, and repurchase using a Play license tester.

## Razorpay — sandbox first

1. Obtain `rzp_test_...` key ID and its test secret.
2. Create a separate webhook secret and subscribe the webhook to
   `payment.captured`, `payment.refunded`, and `refund.processed` at
   `https://api.chessverseai.com/api/v1/purchases/webhooks/razorpay`.
3. Put all three values only in the uncommitted VPS `vps.env`, then set
   `RAZORPAY_ENABLED=true`.
4. Run test success, cancellation, failed payment, replayed callback, delayed
   webhook, refund, and reconciliation checks before requesting live keys.

## Apple — intentionally disabled

Apple checkout remains unavailable until the Apple Developer/App Store Connect
account exists, `coins_500` is created as a consumable, and server-side signed
transaction verification is configured. Do not set
`APPLE_STOREKIT_ENABLED=true` before that verifier is added and tested.

## Release evidence

Keep provider sandbox receipts, webhook delivery logs, refund evidence, and the
test report without copying secrets or raw payment credentials. A real external
penetration test must be commissioned independently; internal tests cannot be
represented as an independent penetration-test certificate.
