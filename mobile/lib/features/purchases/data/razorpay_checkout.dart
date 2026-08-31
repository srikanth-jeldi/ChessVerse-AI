import 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart';

import 'purchase_api.dart';

Future<RazorpayPaymentResult> openRazorpayCheckout(
        RazorpayCheckoutDto checkout) =>
    openRazorpayCheckoutImpl(checkout);
