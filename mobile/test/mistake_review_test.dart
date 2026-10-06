import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_review.dart';
void main(){
 test('due reviews advance through 1 3 7 14 30 days, early replay does not',(){
  var now=DateTime.utc(2026,10,5);var r=MistakeReview(nextReview:now,updatedAt:now);
  for(final days in [1,3,7,14,30]){r=r.record(true,now);expect(r.nextReview,now.add(Duration(days:days)));final early=r.record(true,now);expect(early.stage,r.stage);expect(early.nextReview,r.nextReview);now=r.nextReview;}
  expect(r.stage,5);expect(r.attempts,5);expect(r.successes,5);
 });
 test('wrong retry resets stage and schedules tomorrow, round trip persists',(){
  final now=DateTime.utc(2026,10,5);final r=MistakeReview(nextReview:now,updatedAt:now,stage:4,attempts:5,successes:5).record(false,now);
  expect(r.stage,0);expect(r.nextReview,now.add(const Duration(days:1)));expect(r.successes,5);expect(r.attempts,6);
  final restored=MistakeReview.fromJson(r.toJson());expect(restored.due(now),false);expect(restored.due(r.nextReview),true);
 });
}
