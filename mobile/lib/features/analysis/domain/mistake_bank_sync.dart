import 'dart:async';
import '../../../core/local_game_archive.dart';
import '../../academy/data/academy_api.dart';
import '../../auth/data/auth_session_store.dart';
import '../../tutorial/data/academy_progress_store.dart';
import 'mistake_bank.dart';

// Only transmit board positions after explicit per-academy opt-in.
// Local snapshots survive offline failures and are retried on the next visit.
bool _listening = false;
Timer? _syncDebounce;
void startAcademyMistakeSync() {
  if(_listening)return;
  _listening=true;
  LocalGameArchive.activityRevision.addListener(() {
    _syncDebounce?.cancel();
    _syncDebounce=Timer(const Duration(seconds:2),()=>unawaited(syncAcademyMistakeBank()));
  });
}
Future<bool> _syncQueue = Future.value(false);
Future<bool> syncAcademyMistakeBank() {
  _syncQueue = _syncQueue.then((_) => _syncBank(), onError: (_) => _syncBank());
  return _syncQueue;
}
Future<bool> _syncBank() async {
  final session = await const AuthSessionStore().read();
  if(session == null || session.isGuest || session.isExpired) return false;
  final identity = await const AuthSessionStore().progressIdentity(session);
  if(!await LocalGameArchive.hasActiveIdentity(identity))return false;
  final api = AcademyApi(session.token);
  try {
    final me = await api.request('/me');
    final reviews = await const AcademyProgressStore().readMistakeReviews();
    final bank = MistakeBank.all(LocalGameArchive.games);
    var synced = false;
    for(final org in (me['organizations'] as List).where((o) => o['role']=='STUDENT')) {
      try {
        final activity = await api.request('/${org['id']}/app-activity');
        if(!(activity['sharing'] as List? ?? []).any((s) => s['enabled']==true && s['mistake_bank_enabled']==true)) continue;
        final items = bank.map((item) {
          final review = reviews[item.id];
          return <String,dynamic>{'id':item.id,'fen':item.review.fenBefore,
            'bestMove':item.review.bestMove.toLowerCase(),'playedMove':item.review.playedMove.toLowerCase(),
            'classification':item.review.classification.toLowerCase(),
            'centipawnLoss':item.review.centipawnLoss.clamp(0,100000),
            'attempts':review?.attempts ?? 0,'successes':review?.successes ?? 0,'stage':review?.stage ?? 0,
            'nextReview':(review?.nextReview ?? item.game.playedAt).toUtc().toIso8601String(),
            'updatedAt':(review?.updatedAt ?? item.game.playedAt).toUtc().toIso8601String()};
        }).toList();
        final current = await const AuthSessionStore().read();
        if(current?.token!=session.token || !await LocalGameArchive.hasActiveIdentity(identity))return false;
        await api.request('/${org['id']}/mistake-bank/sync',method:'POST',body:{'items':items});
        synced = true;
      } catch (_) { /* Other academies and offline practice remain available. */ }
    }
    return synced;
  } catch (_) {return false;} finally {api.close();}
}
