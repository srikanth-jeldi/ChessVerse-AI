import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';

import '../../../core/club_localizations.dart';
import '../../../core/club_social_localizations.dart';
import '../data/community_api.dart';
import '../data/social_api.dart';

class ClubSocialDialog extends StatefulWidget {
  const ClubSocialDialog({
    super.key,
    required this.api,
    required this.token,
    required this.language,
    this.clubId,
  });
  final CommunityApi api;
  final String token, language;
  final String? clubId;
  @override
  State<ClubSocialDialog> createState() => _ClubSocialDialogState();
}

class _ClubSocialDialogState extends State<ClubSocialDialog> {
  final _identity = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;
  String? _error;
  String s(String key) => clubSocialText(key, widget.language);
  @override
  void dispose() {
    _identity.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _identity.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Object result = true;
      if (widget.clubId == null) {
        result = await widget.api.createClub(
          widget.token,
          _identity.text.trim(),
          _description.text.trim(),
        );
      } else {
        await widget.api.inviteToClub(
          widget.token,
          widget.clubId!,
          _identity.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, result);
    } on SocialException catch (error) {
      if (mounted) setState(() => _error = UiCopy.text(error.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: ['ar', 'fa', 'he', 'ur'].contains(widget.language)
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: AlertDialog(
      scrollable: true,
      title: Text(s(widget.clubId == null ? 'create' : 'invite')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.clubId != null) ...[
            const UiText(
              'Invite anyone by email, even if they do not have ChessVerseAI yet. They sign in with that email and accept in Community > Clubs.',
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _identity,
            enabled: !_busy,
            autocorrect: widget.clubId == null,
            enableSuggestions: widget.clubId == null,
            keyboardType: widget.clubId == null
                ? TextInputType.text
                : TextInputType.emailAddress,
            maxLength: widget.clubId == null ? 80 : 254,
            decoration: InputDecoration(
              label: Text(s(widget.clubId == null ? 'name' : 'identity')),
            ),
          ),
          if (widget.clubId == null)
            TextField(
              controller: _description,
              enabled: !_busy,
              maxLength: 240,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(label: Text(s('description'))),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(clubText('cancel', widget.language)),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  s(widget.clubId == null ? 'create' : 'send'),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    ),
  );
}
