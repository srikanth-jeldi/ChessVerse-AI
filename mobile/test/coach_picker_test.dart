import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/coach_persona.dart';
import 'package:chessverse_ai/features/coaches/coach_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['COACH_VISUAL_FONTS'] != '1') return;
    for (final entry in {'Roboto':'Nirmala.ttc','ArabicPreview':'segoeui.ttf'}.entries) {
      await (FontLoader(entry.key)..addFont(Future.value(ByteData.sublistView(await File('C:/Windows/Fonts/${entry.value}').readAsBytes())))).load();
    }
  });
  test('coach preference persists without modifying game or coin preferences', () async {
    FlutterSecureStorage.setMockInitialValues({'coins':'123','game':'saved'});
    expect(await CoachPersona.load(),CoachPersona.mira);
    await CoachPersona.vikram.save();
    expect(await CoachPersona.load(),CoachPersona.vikram);
    final all = await const FlutterSecureStorage().readAll();
    expect(all['coins'],'123');expect(all['game'],'saved');
  });
  for (final language in AppLanguageController.supported.where((l)=>l.code!='system')) {
    testWidgets('four coach cards ${language.code} narrow enlarged text', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await tester.runAsync(()=>UiCopy.load(language.code));
      final raw = await tester.runAsync(() => rootBundle.loadString('assets/i18n/ui/${language.code}.json'));
      final catalog=jsonDecode(raw!) as Map;
      for(final c in CoachPersona.values) {
        for(final key in [c.title,c.description,c.preview,c.review('Best','fallback'),c.review('Blunder','fallback'),c.review('Inaccuracy','fallback')]) {
          if(key!='fallback') expect(catalog[key],isNotNull,reason:'${language.code}: $key');
        }
      }
      tester.view.physicalSize=const Size(320,740);
      tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme:ThemeData.dark().copyWith(textTheme:ThemeData.dark().textTheme.apply(fontFamily:'Roboto',fontFamilyFallback:['ArabicPreview'])),locale:Locale(language.code),
        supportedLocales:AppLanguageController.supported.where((l)=>l.code!='system').map((l)=>Locale(l.code)),
        localizationsDelegates:GlobalMaterialLocalizations.delegates,
        builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(1.5)),child:Directionality(textDirection:['ar','fa','he','ur'].contains(language.code)?TextDirection.rtl:TextDirection.ltr,child:child!)),
        home:const RepaintBoundary(key:ValueKey('coach-capture'),child:CoachPickerScreen()),
      ));
      await tester.pumpAndSettle();
      for(final c in CoachPersona.values) {
        await tester.scrollUntilVisible(find.byKey(ValueKey('coach-${c.name}')), 300, maxScrolls: 30);
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        final card=find.byKey(ValueKey('coach-${c.name}'));
        expect(find.descendant(of:card,matching:find.text(c.name)),findsOneWidget);
        for(final element in find.descendant(of:card,matching:find.byType(RichText)).evaluate()) {
          final render=element.renderObject;
          if(render is RenderParagraph) expect(render.didExceedMaxLines,isFalse);
        }
      }
      if(language.code=='en'||language.code=='te'||language.code=='ar') {
        await tester.scrollUntilVisible(find.byKey(const ValueKey('coach-Mira')), -300, maxScrolls: 30);
        await tester.pumpAndSettle();
        final boundary=tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('coach-capture')));
        await tester.runAsync(() async {
          final image=await boundary.toImage(pixelRatio:2);
          final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
          final file=File('../.build-tmp/coach-${language.code}.png');await file.writeAsBytes(bytes!.buffer.asUint8List());image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());await tester.pump();
    });
  }
}
