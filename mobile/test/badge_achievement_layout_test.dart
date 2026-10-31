import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/features/shop/data/shop_api.dart';
import 'package:chessverse_ai/features/shop/presentation/badge_achievement_details.dart';

void main() {
  test('legacy catalog remains readable', () {
    final item = CosmeticItemDto.fromJson({'slug':'royal-master','owned':true});
    expect(item.achievement, isNull);
    expect(item.owned, isTrue);
  });
  for (final language in AppLanguageController.supported.where((l)=>l.code!='system')) {
    testWidgets('badge progress ${language.code} narrow with large text', (tester) async {
      await tester.runAsync(()=>UiCopy.load(language.code));
      tester.view.physicalSize=const Size(320,800);
      tester.view.devicePixelRatio=1;
      addTearDown(tester.view.reset);
      for (final state in ['locked','owned','earned']) {
        final item=CosmeticItemDto.fromJson({
          'slug':'puzzle-hunter','owned':state!='locked',
          'achievement':{'current':state=='earned'?25:7,'target':25,'earned':state=='earned'}
        });
        await tester.pumpWidget(MaterialApp(home:Scaffold(body:MediaQuery(
          data:const MediaQueryData(textScaler:TextScaler.linear(2)),
          child:Directionality(textDirection:['ar','he','fa','ur'].contains(language.code)?TextDirection.rtl:TextDirection.ltr,
            child:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(20),child:BadgeAchievementDetails(item:item))))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull,reason:'${language.code}: $state');
        expect(find.byType(LinearProgressIndicator),findsOneWidget);
      }
    });
  }
}
