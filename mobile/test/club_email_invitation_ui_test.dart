import 'dart:async';
import 'dart:convert';

import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/social/data/community_api.dart';
import 'package:chessverse_ai/features/social/data/social_api.dart';
import 'package:chessverse_ai/features/social/presentation/club_invitations_panel.dart';
import 'package:chessverse_ai/features/social/presentation/club_social_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends CommunityApi {
  List<ClubInvitationDto> invitations = [
    ClubInvitationDto(
      id: 'invite',
      clubId: 'club',
      clubName: 'Hyderabad Friends International Chess Club',
      inviterName: 'A friend with a long display name',
      expiresAt: DateTime(2026, 11, 2),
    ),
  ];
  int responses = 0;
  bool? accepted;
  String? sentEmail;
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<List<ClubInvitationDto>> clubInvitations(String token) async {
    if (fail) throw const SocialException('Unable to load invitations.');
    return List.of(invitations);
  }

  @override
  Future<void> respondToClubInvitation(
    String token,
    String id, {
    required bool accept,
  }) async {
    responses++;
    accepted = accept;
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> inviteToClub(
    String token,
    String clubId,
    String identity,
  ) async {
    sentEmail = identity;
  }
}

void main() {
  testWidgets('pending accept cannot update a different signed-in account', (
    tester,
  ) async {
    final api = _Api()..pending = Completer<void>();
    var refreshed = 0;
    Widget shell(String token) => MaterialApp(
      home: Scaffold(
        body: ClubInvitationsPanel(
          token: token,
          api: api,
          onChanged: () async {
            refreshed++;
          },
        ),
      ),
    );
    await tester.pumpWidget(shell('first-account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept invitation'));
    await tester.pump();
    await tester.pumpWidget(shell('second-account'));
    await tester.pumpAndSettle();
    api.pending!.complete();
    await tester.pumpAndSettle();
    expect(refreshed, 0);
    expect(
      find.text('Hyderabad Friends International Chess Club'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
  testWidgets(
    '34-language invitation cards and email keyboard dialog fit small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final manifest = (await tester.runAsync(
        () => AssetManifest.loadFromAssetBundle(rootBundle),
      ))!;
      final paths = manifest.listAssets().where(
        (p) => p.startsWith('assets/i18n/ui/') && p.endsWith('.json'),
      );
      expect(paths.length, 34);
      for (final path in paths) {
        final code = path.split('/').last.split('.').first;
        await tester.runAsync(() => UiCopy.load(code));
        final labels = jsonDecode(
          (await tester.runAsync(() => rootBundle.loadString(path)))!,
        ) as Map;
        expect(labels['Invited by {0}'], contains('{0}'));
        final api = _Api();
        Widget shell(Widget child, {bool keyboard = false}) => MaterialApp(
          home: Directionality(
            textDirection: {'ar', 'he', 'fa', 'ur'}.contains(code)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(
                textScaler: const TextScaler.linear(1.4),
                viewInsets: EdgeInsets.only(bottom: keyboard ? 280 : 0),
              ),
              child: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        );
        await tester.pumpWidget(
          shell(
            ClubInvitationsPanel(
              key: ValueKey(code),
              token: 'token',
              api: api,
              onChanged: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Hyderabad Friends International Chess Club'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$code card');
        await tester.pumpWidget(
          shell(
            ClubSocialDialog(
              key: ValueKey('dialog-$code'),
              api: api,
              token: 'token',
              language: code,
              clubId: 'club',
            ),
            keyboard: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'friend.without.account@example.com',
        );
        expect(tester.takeException(), isNull, reason: '$code keyboard');
      }
      await tester.runAsync(() => UiCopy.load('en'));
    },
  );
  testWidgets(
    'accept is explicit, duplicate taps blocked, and refresh updates membership',
    (tester) async {
      final api = _Api()..pending = Completer<void>();
      var refreshed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClubInvitationsPanel(
              token: 'token',
              api: api,
              onChanged: () async {
                refreshed++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.responses, 0);
      await tester.tap(find.text('Accept invitation'));
      await tester.pump();
      await tester.tap(find.text('Accept invitation'));
      expect(api.responses, 1);
      api.pending!.complete();
      await tester.pumpAndSettle();
      expect(api.accepted, true);
      expect(refreshed, 1);
      expect(
        find.text('Hyderabad Friends International Chess Club'),
        findsNothing,
      );
    },
  );
  testWidgets('decline does not accept and failed loading offers retry', (
    tester,
  ) async {
    final api = _Api()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClubInvitationsPanel(
            token: 'token',
            api: api,
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load invitations.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(api.accepted, false);
  });
}
