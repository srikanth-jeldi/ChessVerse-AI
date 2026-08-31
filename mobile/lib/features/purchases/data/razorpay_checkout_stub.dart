import 'purchase_api.dart';

Future<RazorpayPaymentResult> openRazorpayCheckoutImpl(
        RazorpayCheckoutDto checkout) =>
    throw const PurchaseException('Razorpay checkout is available on web only.');
