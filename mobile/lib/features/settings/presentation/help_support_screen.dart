import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _working = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('HELP & SUPPORT')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: <Widget>[
            ChessVerseCard(
              child: FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (BuildContext context,
                    AsyncSnapshot<PackageInfo> snapshot) {
                  final PackageInfo? info = snapshot.data;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF123955),
                      child: Icon(Icons.info_outline_rounded,
                          color: AppColors.info),
                    ),
                    title: const Text('ChessVerseAI'),
                    subtitle: Text(info == null
                        ? 'Reading app version…'
                        : 'Version ${info.version} (${info.buildNumber})'),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ChessVerseCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _SupportAction(
                    icon: Icons.copy_all_rounded,
                    title: 'Copy diagnostic information',
                    subtitle:
                        'Copies version, device details and redacted recent events',
                    onTap: _working ? null : _copyDiagnostics,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _SupportAction(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a problem',
                    subtitle:
                        'Opens an email with privacy-safe diagnostics attached',
                    onTap: _working ? null : _reportProblem,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _SupportAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Send feedback',
                    subtitle: 'Tell us what would make ChessVerseAI better',
                    onTap: _working ? null : _sendFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diagnostics never include passwords, authentication tokens, API keys or full email addresses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (_working) ...<Widget>[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      );

  Future<void> _copyDiagnostics() async {
    await _run(() async {
      final String report = await AppDiagnostics.buildReport();
      await Clipboard.setData(ClipboardData(text: report));
      _show('Diagnostic information copied');
    });
  }

  Future<void> _reportProblem() async {
    await _run(() async {
      final String report = await AppDiagnostics.buildReport();
      await _openEmail(
        subject: 'ChessVerseAI problem report',
        body:
            'Please describe what happened:\n\n\n--- SAFE DIAGNOSTICS ---\n$report',
      );
    });
  }

  Future<void> _sendFeedback() async {
    await _run(() => _openEmail(
          subject: 'ChessVerseAI feedback',
          body: 'My feedback:\n\n',
        ));
  }

  Future<void> _openEmail(
      {required String subject, required String body}) async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'chessverseai@gmail.com',
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );
    if (!await launchUrl(email, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: body));
      _show('No email app found. Report copied to clipboard.');
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _working = true);
    try {
      await operation();
    } on Object catch (error, stack) {
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Help and Support action failed',
      );
      _show('That action could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.info),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
