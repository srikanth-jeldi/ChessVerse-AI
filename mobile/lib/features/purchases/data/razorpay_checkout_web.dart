import 'dart:convert';
import 'dart:js_interop';

import 'purchase_api.dart';

@JS('chessverseOpenRazorpay')
external JSPromise<JSString> _openRazorpay(
    JSString key,
    JSString orderId,
    JSNumber amount,
    JSString currency,
    JSString name,
    JSString description);

Future<RazorpayPaymentResult> openRazorpayCheckoutImpl(
    RazorpayCheckoutDto checkout) async {
  final raw = (await _openRazorpay(
          checkout.publicKeyId.toJS,
          checkout.providerOrderId.toJS,
          checkout.amountMinor.toJS,
          checkout.currency.toJS,
          checkout.name.toJS,
          checkout.description.toJS)
      .toDart)
      .toDart;
  final value = jsonDecode(raw) as Map<String, dynamic>;
  if (value['cancelled'] == true) {
    throw const PurchaseException('Payment cancelled. No coins were added.');
  }
  return RazorpayPaymentResult(
      paymentId: value['razorpay_payment_id'] as String? ?? '',
      orderId: value['razorpay_order_id'] as String? ?? '',
      signature: value['razorpay_signature'] as String? ?? '');
}
