import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../data/purchase_api.dart';
import '../data/premium_subscription_api.dart';
import '../data/razorpay_checkout.dart';

class PurchaseCenterScreen extends StatefulWidget {
  const PurchaseCenterScreen({required this.token, super.key});
  final String token;
  @override
  State<PurchaseCenterScreen> createState() => _PurchaseCenterScreenState();
}

class _PurchaseCenterScreenState extends State<PurchaseCenterScreen> {
  final _api = const PurchaseApi();
  final _premiumApi = const PremiumSubscriptionApi();
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  PurchaseCenterDto? _center;
  PurchaseOrderDto? _pendingOrder;
  PremiumStatusDto? _premium;
  String _selectedPlanId = 'monthly';
  PremiumOfferDto? _selectedOffer;
  bool _couponApplied = false;
  bool _premiumBuying = false;
  bool _loading = true, _buying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _purchaseSub = _iap.purchaseStream.listen(
        _purchaseUpdated,
        onError: (_) =>
            _result('Payment update could not be read.', failed: true),
      );
    }
    _load();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final PurchaseCenterDto center = await _api.center(widget.token);
      if (mounted) {
        setState(() {
          _center = center;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is PurchaseException
              ? e.message
              : 'Purchase service unavailable.';
        });
      }
    }
  }

  Future<void> _startTrial() async {
    if (_premiumBuying) return;
    setState(() => _premiumBuying = true);
    try {
      final value = await _premiumApi.startTrial(widget.token);
      if (mounted) setState(() => _premium = value);
      _result('Your 7-day Premium trial is active.');
    } catch (e) {
      _result(
        e is PremiumSubscriptionException
            ? e.message
            : 'The trial could not be activated.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _premiumBuying = false);
    }
  }

  Future<void> _buyPremium() async {
    if (_premiumBuying ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return;
      _result(
        'Premium checkout is currently available on Android.',
        failed: true,
      );
      return;
    }
    if (_premium?.googlePlayAvailable != true) {
      _result('Google Play Premium checkout is not enabled yet.', failed: true);
      return;
    }
    setState(() => _premiumBuying = true);
    try {
      final response = await _iap.queryProductDetails(const <String>{
        'chessverse_premium',
      });
      final products = response.productDetails
          .whereType<GooglePlayProductDetails>()
          .where((p) {
            final offers = p.productDetails.subscriptionOfferDetails;
            if (offers == null || p.subscriptionIndex == null) return false;
            final offer = offers[p.subscriptionIndex!];
            if (offer.basePlanId != _selectedPlanId) return false;
            if (!_couponApplied || _selectedOffer == null) {
              return offer.offerId == null;
            }
            return offer.offerTags.contains(_selectedOffer!.playOfferTag);
          })
          .toList();
      if (response.error != null || products.isEmpty) {
        throw const PremiumSubscriptionException(
          'This plan or selected offer is not active in Google Play yet.',
        );
      }
      final product = products.first;
      final launched = await _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: product.offerToken,
        ),
      );
      if (!launched) {
        throw const PremiumSubscriptionException(
          'Secure checkout did not open.',
        );
      }
    } catch (e) {
      _result(
        e is PremiumSubscriptionException
            ? e.message
            : 'Premium checkout could not start.',
        failed: true,
      );
      if (mounted) setState(() => _premiumBuying = false);
    }
  }

  String get _provider {
    if (kIsWeb) return 'RAZORPAY';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'APPLE_STOREKIT'
        : 'GOOGLE_PLAY';
  }

  Future<void> _buy(CoinPackDto pack) async {
    if (_buying) return;
    setState(() {
      _buying = true;
      _error = null;
    });
    try {
      if (kIsWeb && !_center!.webCheckoutAvailable) {
        throw const PurchaseException(
          'Razorpay sandbox checkout is not enabled yet. No payment was attempted.',
        );
      }
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          !_center!.googlePlayAvailable) {
        throw const PurchaseException(
          'Google Play checkout is not enabled yet. No payment was attempted.',
        );
      }
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          !_center!.appleStoreKitAvailable) {
        throw const PurchaseException(
          'Apple checkout is not enabled yet. No payment was attempted.',
        );
      }
      final order = await _api.createOrder(widget.token, pack, _provider);
      _pendingOrder = order;
      if (kIsWeb) {
        final checkout = await _api.razorpayCheckout(widget.token, order.id);
        final payment = await openRazorpayCheckout(checkout);
        await _api.verifyRazorpay(widget.token, order.id, payment);
        await _load();
        _result('${order.coins} coins added securely.');
        return;
      }
      final available = await _iap.isAvailable();
      if (!available) {
        throw const PurchaseException('The device store is unavailable.');
      }
      final response = await _iap.queryProductDetails({pack.sku});
      if (response.error != null || response.productDetails.isEmpty) {
        throw const PurchaseException(
          'This coin pack is not active in the store yet.',
        );
      }
      final launched = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
        autoConsume: false,
      );
      if (!launched) {
        throw const PurchaseException('Secure checkout did not open.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buying = false;
          _error = e is PurchaseException
              ? e.message
              : 'Purchase could not start.';
        });
      }
    }
  }

  Future<void> _purchaseUpdated(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (purchase.productID == 'chessverse_premium') {
        await _premiumPurchaseUpdated(purchase);
        continue;
      }
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _buying = true);
        continue;
      }
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _result(
          purchase.status == PurchaseStatus.canceled
              ? 'Purchase cancelled. No coins were added.'
              : 'Payment failed. No coins were added.',
          failed: true,
        );
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final order = _pendingOrder;
          if (order == null) {
            throw const PurchaseException(
              'Purchase order context is missing. Contact support.',
            );
          }
          if (_provider == 'GOOGLE_PLAY') {
            await _api.verifyGooglePlay(
              widget.token,
              order.id,
              purchase.verificationData.serverVerificationData,
            );
            if (defaultTargetPlatform == TargetPlatform.android &&
                purchase is GooglePlayPurchaseDetails) {
              final android = _iap
                  .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              await android.consumePurchase(purchase);
            }
          } else {
            throw const PurchaseException(
              'Apple verification is not enabled yet. The purchase was not credited.',
            );
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          await _load();
          _result('${order.coins} coins added securely.');
        } catch (e) {
          _result(
            e is PurchaseException
                ? e.message
                : 'Verification failed. No coins were added.',
            failed: true,
          );
        }
      }
    }
  }

  Future<void> _premiumPurchaseUpdated(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      if (mounted) setState(() => _premiumBuying = true);
      return;
    }
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      _result(
        purchase.status == PurchaseStatus.canceled
            ? 'Premium purchase cancelled.'
            : 'Premium payment failed.',
        failed: true,
      );
      if (mounted) setState(() => _premiumBuying = false);
      return;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }
    try {
      final value = await _premiumApi.verifyGooglePlay(
        widget.token,
        purchase.verificationData.serverVerificationData,
      );
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      if (mounted) setState(() => _premium = value);
      _result('Premium is active on your account.');
    } catch (e) {
      _result(
        e is PremiumSubscriptionException
            ? e.message
            : 'Premium verification failed.',
        failed: true,
      );
    } finally {
      if (mounted) setState(() => _premiumBuying = false);
    }
  }

  void _result(String message, {bool failed = false}) {
    if (!mounted) return;
    setState(() => _buying = false);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A2033),
        icon: Icon(
          failed ? Icons.cancel_rounded : Icons.verified_rounded,
          color: failed ? const Color(0xFFE36B6B) : const Color(0xFF5DE9D3),
          size: 54,
        ),
        title: Text(failed ? 'Purchase not completed' : 'Payment verified'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF04111E),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071B2D),
      title: const Text('PREMIUM & COINS'),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _center == null
        ? _failure()
        : _body(),
  );

  Widget _failure() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_error!, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry')),
      ],
    ),
  );
  Widget _body() => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 850;
      return ListView(
        padding: EdgeInsets.fromLTRB(wide ? 48 : 16, 20, wide ? 48 : 16, 80),
        children: [
          _hero(),
          const SizedBox(height: 18),
          Text(
            'COIN PACKS',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: _center!.products.map((p) => _pack(p, wide)).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _notice(_error!, const Color(0xFFE2A93B)),
          ],
          const SizedBox(height: 28),
          Text(
            'PURCHASE HISTORY',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _history(),
          const SizedBox(height: 18),
          _notice(_center!.securityNotice, const Color(0xFF5DE9D3)),
        ],
      );
    },
  );

  // Kept dormant for a possible future Academy-linked entitlement migration;
  // the personal ChessVerseAI app currently exposes no Premium subscription.
  // ignore: unused_element
  Widget _premiumCard() {
    final premium = _premium;
    if (premium == null) return const SizedBox.shrink();
    final matchingPlans = premium.plans
        .where((p) => p.basePlanId == _selectedPlanId)
        .toList();
    final plan = matchingPlans.isEmpty ? null : matchingPlans.first;
    final offers = premium.offers
        .where((offer) => offer.basePlanId == _selectedPlanId)
        .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF173E4B), Color(0xFF0A2033)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5DE9D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFF4C75B),
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  premium.premium
                      ? 'CHESSVERSE PREMIUM ACTIVE'
                      : 'CHESSVERSE PREMIUM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'No ads • Unlimited AI game reviews • Premium boards and pieces • Advanced training insights',
            style: TextStyle(color: Color(0xFFB8CFDC), height: 1.45),
          ),
          if (premium.premium) ...<Widget>[
            const SizedBox(height: 14),
            _notice(
              premium.expiresAt == null
                  ? 'Premium access is active.'
                  : 'Premium access is active until ${_date(premium.expiresAt)}.',
              const Color(0xFF5DE9D3),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'monthly', label: Text('Monthly')),
                ButtonSegment<String>(value: 'yearly', label: Text('Yearly')),
              ],
              selected: <String>{_selectedPlanId},
              onSelectionChanged: (values) => setState(() {
                _selectedPlanId = values.first;
                _selectedOffer = null;
                _couponApplied = false;
              }),
            ),
            const SizedBox(height: 14),
            Text(
              plan == null ? 'Plan unavailable' : _premiumPrice(plan),
              style: const TextStyle(
                color: Color(0xFFF4C75B),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<PremiumOfferDto>(
              initialValue:
                  _selectedOffer != null && offers.contains(_selectedOffer)
                  ? _selectedOffer
                  : null,
              decoration: const InputDecoration(
                labelText: 'Available offer',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select an eligible coupon'),
              items: offers
                  .map(
                    (offer) => DropdownMenuItem<PremiumOfferDto>(
                      value: offer,
                      child: Text('${offer.code} — ${offer.label}'),
                    ),
                  )
                  .toList(),
              onChanged: offers.isEmpty
                  ? null
                  : (offer) => setState(() {
                      _selectedOffer = offer;
                      _couponApplied = false;
                    }),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>(_selectedOffer?.code ?? 'no-coupon'),
                    initialValue: _selectedOffer?.code ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Coupon code',
                      hintText: 'Choose from the dropdown',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_couponApplied)
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedOffer = null;
                      _couponApplied = false;
                    }),
                    child: const Text('Remove'),
                  )
                else
                  FilledButton(
                    onPressed: _selectedOffer == null
                        ? null
                        : () => setState(() => _couponApplied = true),
                    child: const Text('Apply'),
                  ),
              ],
            ),
            if (_couponApplied && _selectedOffer != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                '${_selectedOffer!.label}. Discount applies to the first billing only.',
                style: const TextStyle(color: Color(0xFF5DE9D3)),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Google Play shows the final local tax-inclusive price before confirmation. Renewal is at the normal plan price unless you cancel.',
              style: TextStyle(color: Color(0xFF91A8B7), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _premiumBuying ? null : _startTrial,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text('START ${premium.trialDays}-DAY TRIAL'),
                ),
                FilledButton.icon(
                  onPressed: _premiumBuying || plan == null
                      ? null
                      : _buyPremium,
                  icon: const Icon(Icons.lock_rounded),
                  label: Text(
                    _premiumBuying ? 'VERIFYING…' : 'SUBSCRIBE SECURELY',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _premiumPrice(PremiumPlanDto plan) {
    final amount = plan.indiaPriceMinor / 100;
    return plan.currency == 'INR'
        ? '₹${amount.toStringAsFixed(0)} / ${plan.basePlanId == 'yearly' ? 'year' : 'month'}'
        : '${plan.currency} ${amount.toStringAsFixed(2)}';
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF153D54), Color(0xFF091D30)],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0x7063E6D5)),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFB8862F),
          child: Icon(Icons.paid_rounded, color: Color(0xFFFFE394), size: 34),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POWER YOUR CHESS JOURNEY',
                style: TextStyle(
                  color: Color(0xFFF4C75B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Direct coin packs. No money wallet.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Final store price is always shown before you confirm.',
                style: TextStyle(color: Color(0xFFADC2D1)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _pack(CoinPackDto p, bool wide) => SizedBox(
    width: wide ? 300 : double.infinity,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2033),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29475D)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFF4C75B),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(p.description, style: const TextStyle(color: Color(0xFFA8BDCB))),
          const SizedBox(height: 14),
          Text(
            _price(p),
            style: const TextStyle(
              color: Color(0xFFF4C75B),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Final tax-inclusive price is confirmed by the provider',
            style: TextStyle(color: Color(0xFF8298A8), fontSize: 11),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _buying ? null : () => _buy(p),
              icon: const Icon(Icons.lock_rounded),
              label: Text(_buying ? 'VERIFYING…' : 'BUY SECURELY'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8862F),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _history() {
    final orders = _center!.orders;
    if (orders.isEmpty) {
      return _notice(
        'No purchases yet. Your verified purchases will appear here.',
        const Color(0xFF6E8798),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF081B2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF29475D)),
      ),
      child: Column(
        children: [
          for (final o in orders)
            ListTile(
              leading: const Icon(Icons.paid_rounded, color: Color(0xFFF4C75B)),
              title: Text(
                o.productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${o.provider.replaceAll('_', ' ')} • ${_date(o.createdAt)}',
                style: const TextStyle(color: Color(0xFF91A8B7)),
              ),
              trailing: _status(o.status),
            ),
        ],
      ),
    );
  }

  Widget _status(String s) {
    final c = s == 'FULFILLED'
        ? const Color(0xFF5DE9D3)
        : (s == 'FAILED' || s == 'REVOKED'
              ? const Color(0xFFE36B6B)
              : const Color(0xFFF4C75B));
    return Chip(
      label: Text(s),
      backgroundColor: c.withValues(alpha: .12),
      side: BorderSide(color: c),
      labelStyle: TextStyle(
        color: c,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _notice(String text, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        Icon(Icons.security_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    ),
  );
  String _price(CoinPackDto p) => p.currency == 'INR'
      ? '₹${(p.priceMinor / 100).toStringAsFixed(0)}'
      : '${p.currency} ${(p.priceMinor / 100).toStringAsFixed(2)}';
  String _date(DateTime? d) => d == null
      ? '—'
      : '${d.toLocal().day.toString().padLeft(2, '0')}/${d.toLocal().month.toString().padLeft(2, '0')}/${d.toLocal().year}';
}
