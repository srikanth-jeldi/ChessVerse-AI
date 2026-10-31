import 'package:flutter/foundation.dart';

import 'shop_api.dart';

/// Server loadout, scoped to the authenticated player (never a shared preference).
final equippedBadgeShop = ValueNotifier<ShopDto?>(null);
