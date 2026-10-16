import 'package:flutter/material.dart';

import '../app_language.dart';
import '../monetization_copy.dart';

class LoginBonusMessage extends StatelessWidget {
  const LoginBonusMessage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: AppLanguageController.effectiveLanguageChanges,
    builder: (context, language, _) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        monetizationText(
          'loginBonus',
          AppLanguageController.resolveCode(language ?? 'system'),
        ),
        key: const ValueKey('social-login-bonus'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFFD477),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
