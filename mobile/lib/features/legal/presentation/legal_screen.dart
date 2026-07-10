import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';

enum LegalPageType { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.type, super.key});

  final LegalPageType type;

  @override
  Widget build(BuildContext context) {
    final bool privacy = type == LegalPageType.privacy;
    final List<_LegalSection> sections = privacy
        ? const <_LegalSection>[
            _LegalSection(
              'Data we collect',
              'ChessVerse stores account details, guest/local stats, saved games, puzzle progress, device/session metadata, and support information needed to run the service.',
            ),
            _LegalSection(
              'How we use data',
              'We use data to authenticate users, save games, improve AI coaching, protect accounts, prevent abuse, and provide support.',
            ),
            _LegalSection(
              'Third-party services',
              'Production builds may use Google, Apple, Meta/Facebook login, Gmail/SMTP or email delivery, hosting, analytics, and crash reporting services.',
            ),
            _LegalSection(
              'Data deletion',
              'Users can request account and data deletion from the support channel. A public data deletion URL will be connected before store release.',
            ),
          ]
        : const <_LegalSection>[
            _LegalSection(
              'Using ChessVerse',
              'ChessVerse is a chess training and game app. Do not misuse online modes, automate abuse, impersonate players, or attack the service.',
            ),
            _LegalSection(
              'Accounts',
              'You are responsible for your account credentials. Guest mode is local-only and may not sync progress.',
            ),
            _LegalSection(
              'Fair play',
              'Online play should be fair. Engine assistance may be restricted in competitive modes when real-time online matchmaking is enabled.',
            ),
            _LegalSection(
              'Service changes',
              'Features such as online rooms, random matchmaking, cloud saves, and AI analysis may change as the MVP evolves.',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: Text(privacy ? 'Privacy Policy' : 'Terms of Service')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              privacy ? 'ChessVerse Privacy Policy' : 'ChessVerse Terms',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'MVP draft - replace with reviewed legal copy before store release.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            for (final _LegalSection section in sections) ...<Widget>[
              ChessVerseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(section.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(section.body),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ChessVerseCard(
              child: Text(
                privacy
                    ? 'Production URL: ${AppConfig.privacyPolicyUrl}\nData deletion: ${AppConfig.dataDeletionUrl}'
                    : 'Production URL: ${AppConfig.termsUrl}',
                style: const TextStyle(color: Color(0xFFD6A84F)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
