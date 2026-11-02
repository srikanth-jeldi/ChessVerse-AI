import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/social/presentation/tournament_format_cards.dart';

void main() {
  final preview = Platform.environment['CUP_PREVIEW_DIR'];
  setUpAll(() async {
    if (preview == null) return;
    final font = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(
        await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes())));
    await font.load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 840.0]) {
    testWidgets('format cards at width $width', (tester) async {
      tester.view.devicePixelRatio=1;
      tester.view.physicalSize=Size(width,650);
      addTearDown(tester.view.reset);
      final key=GlobalKey();
      var opens=0;
      Widget page(bool previews) => MaterialApp(theme:ThemeData.dark(),home:Scaffold(
        backgroundColor:const Color(0xff050b18),body:SingleChildScrollView(
          child:RepaintBoundary(key:key,child:ColoredBox(color:const Color(0xff050b18),
            child:Padding(padding:const EdgeInsets.all(14),child:TournamentFormatCards(
              previewFormats:previews,onPractice:()=>opens++)))))));
      await tester.pumpWidget(page(false));
      expect(find.text('Weekend Arena'),findsNothing);
      await tester.tap(find.text('Daily Practice Cup'));
      expect(opens,1);
      await tester.pumpWidget(page(true));
      await tester.pumpAndSettle();
      final ko=tester.getRect(find.text('Daily Knockout'));
      final arena=tester.getRect(find.text('Weekend Arena'));
      if(width<680) {
        expect(arena.top,greaterThan(ko.bottom));
      } else {
        expect(arena.top,ko.top);
      }
      expect(tester.takeException(),isNull);
      if (preview != null) {
        final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        late ui.Image snapshot;
        await tester.runAsync(() async {
          snapshot=await boundary.toImage(pixelRatio:1.5);
          final bytes=await snapshot.toByteData(format:ui.ImageByteFormat.png);
          await Directory(preview).create(recursive:true);
          await File('$preview/tournaments-${width.toInt()}.png').writeAsBytes(bytes!.buffer.asUint8List());
          snapshot.dispose();
        });
      }
    });
  }
}
