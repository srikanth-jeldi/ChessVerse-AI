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
              'ChessVerseAI processes account and profile details, authentication records, games and ratings, puzzle and lesson progress, social activity, chat messages and user-selected attachments, notification tokens, preferences, security signals and diagnostics needed to operate the service.',
            ),
            _LegalSection(
              'How we use data',
              'We use data to authenticate users, save progress, provide AI coaching and online play, connect friends, deliver chat and notifications, prevent cheating and abuse, diagnose failures and provide support. We do not sell personal information.',
            ),
            _LegalSection(
              'Third-party services',
              'Hosting, authentication, email and notification service providers process information only as needed to operate ChessVerseAI. Data is transmitted using HTTPS/TLS.',
            ),
            _LegalSection(
              'Data deletion',
              'Users can request permanent deletion from Settings or the public deletion page. Verified deletion covers the account and associated server data, subject to limited security, legal and backup retention.',
            ),
            _LegalSection(
              'Social and attachment safety',
              'Only share content you have the right to share. Images and files are chosen through the system picker without broad storage access. Abuse, cheating and child-safety concerns can be reported to chessverseai@gmail.com.',
            ),
          ]
        : const <_LegalSection>[
            _LegalSection(
              'Using ChessVerseAI',
              'ChessVerseAI is a chess training and game app. Do not misuse online modes, automate abuse, impersonate players, or attack the service.',
            ),
            _LegalSection(
              'Accounts',
              'Guest mode uses an app-generated installation identifier to sync online progress. Clearing app data or reinstalling may make that guest account unrecoverable unless it is upgraded to a verified account.',
            ),
            _LegalSection(
              'Fair play',
              'Online play should be fair. Engine assistance may be restricted in competitive modes when real-time online matchmaking is enabled.',
            ),
            _LegalSection(
              'Community and chat',
              'Do not harass, threaten, impersonate, spam, exploit others, share illegal or unsafe content, or make repeated unwanted contact. Violations may result in content removal, feature restrictions or account suspension.',
            ),
            _LegalSection(
              'User content',
              'You retain rights in content you lawfully provide and grant EpitomeHub the limited permission needed to host and transmit it through ChessVerseAI. You must have the right to share it.',
            ),
            _LegalSection(
              'Service changes',
              'Features may change or be interrupted. AI coaching can be incomplete or inaccurate and is provided for chess learning and entertainment.',
            ),
          ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar:
          AppBar(title: Text(privacy ? 'Privacy Policy' : 'Terms of Service')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              privacy ? 'ChessVerseAI Privacy Policy' : 'ChessVerseAI Terms',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Effective August 21, 2026',
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
