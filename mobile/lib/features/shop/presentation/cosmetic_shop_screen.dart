import 'package:flutter/material.dart';
import '../../../core/app_preferences.dart';
import '../../../core/ads/rewarded_coin_service.dart';
import '../data/shop_api.dart';
import '../data/economy_rewards_api.dart';

class CosmeticShopScreen extends StatefulWidget {
  const CosmeticShopScreen({required this.token, super.key});
  final String token;
  @override
  State<CosmeticShopScreen> createState() => _CosmeticShopScreenState();
}

class _CosmeticShopScreenState extends State<CosmeticShopScreen> {
  final ShopApi _api = const ShopApi();
  final EconomyRewardsApi _rewardsApi = const EconomyRewardsApi();
  ShopDto? _shop;
  bool _busy = true;
  String? _error;
  String _category = 'BOARD';
  EconomyRewardStatus? _rewards;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _api.load(widget.token);
      EconomyRewardStatus? rewards;
      try {
        rewards = await _rewardsApi.status(widget.token);
      } catch (_) {
        // Cosmetics remain usable while the optional reward status refreshes.
      }
      if (mounted) {
        setState(() {
          _shop = value;
          _rewards = rewards;
          _busy = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ShopException ? e.message : 'Shop unavailable.';
        });
      }
    }
  }

  Future<void> _act(CosmeticItemDto item) async {
    setState(() => _busy = true);
    try {
      final ShopDto value = item.owned
          ? await _api.equip(widget.token, item.category, item.id)
          : await _api.purchase(widget.token, item.id);
      if (item.category == 'BOARD') {
        await const AppPreferences().writeString('boardTheme', item.name);
      }
      if (item.category == 'PIECES') {
        await const AppPreferences().writeString('pieceStyle', item.name);
      }
      if (mounted) {
        setState(() {
          _shop = value;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                item.owned ? '${item.name} equipped' : '${item.name} unlocked'),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ShopException ? e.message : 'Try again.'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF061524),
        appBar: AppBar(
            backgroundColor: const Color(0xFF071B2D),
            title: const Text('ROYAL COLLECTION'),
            actions: [
              IconButton(
                  onPressed: _load, icon: const Icon(Icons.refresh_rounded))
            ]),
        body: _busy && _shop == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry'))
                  ]))
                : _content());
  }

  Widget _content() {
    final s = _shop!;
    final items = s.items.where((e) => e.category == _category).toList();
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 850;
      return CustomScrollView(slivers: [
        SliverPadding(
            padding:
                EdgeInsets.fromLTRB(wide ? 40 : 16, 20, wide ? 40 : 16, 12),
            sliver: SliverToBoxAdapter(child: _hero(s))),
        SliverToBoxAdapter(child: _tabs()),
        SliverPadding(
            padding:
                EdgeInsets.fromLTRB(wide ? 40 : 16, 16, wide ? 40 : 16, 120),
            sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 3 : (c.maxWidth > 560 ? 2 : 1),
                    mainAxisExtent: 330,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16),
                delegate: SliverChildBuilderDelegate((_, i) => _card(items[i]),
                    childCount: items.length)))
      ]);
    });
  }

  Widget _hero(ShopDto s) => Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              colors: [Color(0xFF123D55), Color(0xFF0B2338)]),
          border: Border.all(color: const Color(0x5060E8D0))),
      child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            const SizedBox(
                width: 430,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAKE THE BOARD YOURS',
                          style: TextStyle(
                              color: Color(0xFFF4C75B),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6)),
                      SizedBox(height: 7),
                      Text('Boards, pieces & checkmate style',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text('Cosmetics only. Your skill decides every game.',
                          style: TextStyle(color: Color(0xFFB7CAD7)))
                    ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _balance(Icons.paid_rounded, '${s.wallet.coins}', 'COINS',
                    const Color(0xFFF4C75B)),
                const SizedBox(width: 10),
                _balance(Icons.diamond_rounded, '${s.wallet.diamonds}',
                    'DIAMONDS', const Color(0xFF5DE9E0))
              ]),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : (_rewards?.dailyAvailable ?? false)
                          ? _claimDaily
                          : null,
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: Text((_rewards?.dailyAvailable ?? false)
                      ? 'CLAIM DAILY • +100 COINS'
                      : 'DAILY REWARD CLAIMED'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB8862F))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: _busy || (_rewards?.rewardedAdsRemaining ?? 3) <= 0
                      ? null
                      : () => _watchAd(s),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(RewardedCoinService.instance.supported
                      ? 'WATCH VIDEO • +150 (${_rewards?.rewardedAdsRemaining ?? 3} LEFT)'
                      : 'FREE COINS • MOBILE APP'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5DE9D3),
                      side: const BorderSide(color: Color(0x805DE9D3))))
            ])
          ]));

  Future<void> _claimDaily() async {
    setState(() => _busy = true);
    try {
      _rewards = await _rewardsApi.claimDaily(widget.token);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Daily reward claimed • +100 play coins')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _watchAd(ShopDto shop) async {
    if (!RewardedCoinService.instance.supported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Rewarded videos are available in the Android and iOS app.')));
      return;
    }
    final bool earned =
        await RewardedCoinService.instance.show(playerId: shop.playerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(earned
            ? 'Video completed. Secure reward verification is processing.'
            : 'Video is still loading. Please try again shortly.')));
    if (earned) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await _load();
    }
  }

  Widget _balance(IconData icon, String value, String label, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
              color: const Color(0xB2081727),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w800))
            ])
          ]));
  Widget _tabs() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(spacing: 10, children: [
        for (final t in ['BOARD', 'PIECES'])
          ChoiceChip(
              label: Text(t == 'BOARD' ? 'BOARDS' : 'PIECE SETS'),
              selected: _category == t,
              onSelected: (_) => setState(() => _category = t),
              selectedColor: const Color(0xFF1E766F),
              labelStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800))
      ]));
  Widget _card(CosmeticItemDto item) {
    final a = _color(item.primaryColor, const Color(0xFFE7D6B0)),
        b = _color(item.secondaryColor, const Color(0xFF6E4128));
    return Container(
        decoration: BoxDecoration(
            color: const Color(0xFF0A2033),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: item.equipped
                    ? const Color(0xFF5DE9D3)
                    : const Color(0xFF244056),
                width: item.equipped ? 2 : 1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 8))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _preview(a, b, item.category))),
          Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(item.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900))),
                      if (item.equipped)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF5DE9D3))
                    ]),
                    const SizedBox(height: 4),
                    Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9FB6C8), fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                            onPressed: _busy || item.equipped
                                ? null
                                : () => _act(item),
                            icon: Icon(item.owned
                                ? Icons.checkroom_rounded
                                : item.priceCurrency == 'DIAMONDS'
                                    ? Icons.diamond_rounded
                                    : Icons.paid_rounded),
                            label: Text(item.equipped
                                ? 'EQUIPPED'
                                : item.owned
                                    ? 'EQUIP'
                                    : item.priceCurrency == 'FREE'
                                        ? 'FREE'
                                        : '${item.priceAmount} ${item.priceCurrency}'),
                            style: FilledButton.styleFrom(
                                backgroundColor:
                                    item.priceCurrency == 'DIAMONDS'
                                        ? const Color(0xFF7355C8)
                                        : const Color(0xFFB8862F),
                                foregroundColor: Colors.white)))
                  ]))
        ]));
  }

  Widget _preview(Color a, Color b, String category) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
          aspectRatio: 1.7,
          child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemCount: 64,
              itemBuilder: (_, i) {
                final dark = ((i ~/ 8) + (i % 8)).isOdd;
                return Container(
                    color: dark ? b : a,
                    alignment: Alignment.center,
                    child: category == 'PIECES' &&
                            <int>{
                              0,
                              1,
                              2,
                              3,
                              4,
                              5,
                              6,
                              7,
                              56,
                              57,
                              58,
                              59,
                              60,
                              61,
                              62,
                              63
                            }.contains(i)
                        ? Text(i < 8 ? '♟' : '♙',
                            style: TextStyle(
                                fontSize: 18,
                                color: i < 8 ? Colors.black : Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 3)
                                ]))
                        : null);
              })));
  Color _color(String? hex, Color fallback) {
    if (hex == null) return fallback;
    return Color(
        int.tryParse(hex.replaceFirst('#', '0xFF')) ?? fallback.toARGB32());
  }
}
