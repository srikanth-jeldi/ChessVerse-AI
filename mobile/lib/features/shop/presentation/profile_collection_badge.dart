import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/equipped_badge.dart';
import '../data/shop_api.dart';

class ProfileCollectionBadge extends StatefulWidget {
  const ProfileCollectionBadge({super.key});
  @override
  State<ProfileCollectionBadge> createState() => _ProfileCollectionBadgeState();
}

class _ProfileCollectionBadgeState extends State<ProfileCollectionBadge> {
  String? _playerId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await const AuthSessionStore().read();
      if (session == null) return;
      final shop = await const ShopApi().load(session.token);
      if (!mounted) return;
      setState(() => _playerId = shop.playerId);
      equippedBadgeShop.value = shop;
    } on Object {
      // Do not show another account's cached badge after a failed load.
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ShopDto?>(
    valueListenable: equippedBadgeShop,
    builder: (context, shop, _) {
      if (_playerId == null || shop?.playerId != _playerId) {
        return const SizedBox.shrink();
      }
      final badges = shop!.items.where(
        (i) => i.category == 'FRAME' && i.equipped,
      );
      if (badges.isEmpty) return const SizedBox.shrink();
      final badge = badges.first;
      return Card(
        child: ListTile(
          leading: Image.asset(
            'assets/badges/${badge.slug}-v1.webp',
            width: 48,
            height: 48,
            errorBuilder: (_, error, stack) =>
                const Icon(Icons.workspace_premium),
          ),
          title: UiText(badge.name),
          subtitle: UiText(
            badge.achievement?.earned == true
                ? 'Achievement earned'
                : 'Profile badge',
          ),
        ),
      );
    },
  );
}
