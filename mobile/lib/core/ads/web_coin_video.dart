import 'dart:js_interop';

@JS('showChessVerseCoinVideo')
external JSPromise<JSString> _show(
  JSNumber placement,
  JSString slot,
  JSString player,
);

Future<String> showWebCoinVideo(
  int placement,
  String slot,
  String player,
) async {
  return (await _show(placement.toJS, slot.toJS, player.toJS).toDart).toDart;
}
