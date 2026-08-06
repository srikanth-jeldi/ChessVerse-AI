import 'dart:js_interop';

@JS('chessverseFacebookReady')
external JSPromise<JSAny?> _chessverseFacebookReady();

Future<void> ensureFacebookSdkReady() => _chessverseFacebookReady().toDart;
