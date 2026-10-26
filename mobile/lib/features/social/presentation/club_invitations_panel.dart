import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../data/community_api.dart';
import '../data/social_api.dart';

class ClubInvitationsPanel extends StatefulWidget {
  const ClubInvitationsPanel({
    super.key,
    required this.token,
    required this.api,
    required this.onChanged,
  });
  final String token;
  final CommunityApi api;
  final Future<void> Function() onChanged;
  @override
  State<ClubInvitationsPanel> createState() => _ClubInvitationsPanelState();
}

class _ClubInvitationsPanelState extends State<ClubInvitationsPanel> {
  List<ClubInvitationDto> _invitations = [];
  bool _loading = true;
  bool _responding = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClubInvitationsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _invitations = [];
      _responding = false;
      _load();
    }
  }

  Future<void> _load() async {
    final token = widget.token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invitations = await widget.api.clubInvitations(token);
      if (mounted && token == widget.token) {
        setState(() => _invitations = invitations);
      }
    } on SocialException catch (e) {
      if (mounted && token == widget.token) setState(() => _error = e.message);
    } finally {
      if (mounted && token == widget.token) setState(() => _loading = false);
    }
  }

  Future<void> _respond(ClubInvitationDto invitation, bool accept) async {
    if (_responding) return;
    final token = widget.token;
    setState(() {
      _responding = true;
      _error = null;
    });
    try {
      await widget.api.respondToClubInvitation(
        token,
        invitation.id,
        accept: accept,
      );
      if (!mounted || token != widget.token) return;
      setState(() => _invitations.removeWhere((i) => i.id == invitation.id));
      await widget.onChanged();
    } on SocialException catch (e) {
      if (mounted && token == widget.token) setState(() => _error = e.message);
    } finally {
      if (mounted && token == widget.token) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF102838),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: UiText(
                  'Club invitations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _loading || _responding ? null : _load,
                tooltip: uiText(context, 'Refresh'),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const UiText(
            'Sign in with the email that received the invitation. New players can create a free account first.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator()
          else if (_error == null && _invitations.isEmpty)
            const UiText('No pending club invitations.'),
          if (_error != null)
            UiText(_error!, style: const TextStyle(color: Color(0xFFFFCC80))),
          for (final invitation in _invitations) ...[
            const Divider(height: 24),
            Text(
              invitation.clubName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            UiText('Invited by {0}', values: [invitation.inviterName]),
            if (invitation.expiresAt != null)
              UiText(
                'Expires: {0}',
                values: [
                  MaterialLocalizations.of(context)
                      .formatMediumDate(invitation.expiresAt!),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _responding
                      ? null
                      : () => _respond(invitation, true),
                  icon: const Icon(Icons.check),
                  label: const UiText(
                    'Accept invitation',
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: _responding
                      ? null
                      : () => _respond(invitation, false),
                  child: const UiText('Decline'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
